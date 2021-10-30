defmodule PatternMetonyms.View do
  @moduledoc false

  @doc false
  def inspect_macro(x) do
    _ = IO.puts(Macro.to_string(x))
    x
  end

  @doc false
  def kind(ast, macro_env) do
    import Circe

    case ast do
      ~m/(#{{:fn, _, body}} -> #{pat})/ ->
        #_ = IO.puts("+++ Matched fn -> pat +++")
        var_data = Macro.var(:"$view_data_#{:erlang.unique_integer([:positive])}", __MODULE__)
        {pat, further_act} = kind(pat, macro_env)
        next = [{
          quote do (unquote({:fn, [], body})).(unquote(var_data)) end,
          pat
        }]
        next_act = concat_act({:replace, next}, further_act)

        {var_data, next_act}

      ~m/(#{{_, _, _} = module}.#{function}(#{[spliced: args]}) -> #{pat})/ ->
        #_ = IO.puts("+++ Matched module.function(args) -> pat +++")
        var_data = Macro.var(:"$view_data_#{:erlang.unique_integer([:positive])}", __MODULE__)
        {pat, further_act} = kind(pat, macro_env)
        next = [{
          quote do unquote(module).unquote(function)(unquote_splicing([var_data | args])) end,
          pat
        }]
        next_act = concat_act({:replace, next}, further_act)

        {var_data, next_act}

      ~m/(#{view_fun = ~m/#{function}(#{[spliced: args]})/} -> #{pat})/ ->
        #_ = IO.puts("+++ Matched function(args) -> pat +++")
        _ = case view_fun do
          {_name, meta, context} when is_atom(context) ->
            message =
              """
              Ambiguous function call `#{Macro.to_string(view_fun)}` in raw view in #{macro_env.file}:#{Keyword.get(meta, :line, macro_env.line)}
                Parentheses are required.
              """
            raise(message)

          _ -> :ok
        end

        var_data = Macro.var(:"$view_data_#{:erlang.unique_integer([:positive])}", __MODULE__)
        {pat, further_act} = kind(pat, macro_env)
        next = [{
          quote do unquote(function)(unquote_splicing([var_data | args])) end,
          pat
        }]
        next_act = concat_act({:replace, next}, further_act)

        {var_data, next_act}

      ~m/#{name}(#{[spliced: args]})/ when is_atom(name) and is_list(args) -> # local syn ?
        #_ = IO.puts("+++ Matched function(args) +++")
        augmented_ast = quote do unquote(:"$pattern_metonyms_viewing_#{name}")(unquote_splicing(args)) end
        augmented_ast
        |> Macro.expand(macro_env)
        |> case do
          ^augmented_ast ->
            kind(args, macro_env)
            |> case do
              {args, {:replace, next}} ->
                ast = quote do unquote(name)(unquote_splicing(args)) end

                {ast, {:replace, next}}

              {args, :keep} ->
                ast = quote do unquote(name)(unquote_splicing(args)) end

                {ast, :keep}
            end

          other ->
            kind(other, macro_env)
        end

      ~m/#{{_, _, _} = module}.#{function}(#{[spliced: args]})/ -> # remote syn ?
        #_ = IO.puts("+++ Matched module.function(args) +++")
        augmented_ast = quote do unquote(module).unquote(:"$pattern_metonyms_viewing_#{function}")(unquote_splicing(args)) end
        augmented_ast
        |> Macro.expand(macro_env)
        #|> IO.inspect(label: "macro expansion test remote syn")
        |> case do
          ^augmented_ast ->
            kind(args, macro_env)
            |> case do
              {args, {:replace, next}} ->
                ast = quote do unquote(module).unquote(function)(unquote_splicing(args)) end

                {ast, {:replace, next}}

              {args, :keep} ->
                ast = quote do unquote(module).unquote(function)(unquote_splicing(args)) end

                {ast, :keep}
            end

          other ->
            kind(other, macro_env)
        end

      xs when is_list(xs) ->
        #_ = IO.puts("+++ Matched list +++")
        {ast, acts} =
          Enum.map(xs, fn x -> kind(x, macro_env) end)
          |> Enum.unzip()

        # concat_act is assosiative, but not commutative
        # so folding from the right is fine, but folding from the left will swap the arguments
        act = List.foldr(acts, :keep, &concat_act/2)

        {ast, act}

      {left, right} ->
        #_ = IO.puts("+++ Matched tuple +++")
        {l_ast, l_act} = kind(left, macro_env)
        {r_ast, r_act} = kind(right, macro_env)
        ast = {l_ast, r_ast}
        act = concat_act(l_act, r_act)

        {ast, act}

      other ->
        #_ = IO.puts("+++ Matched something else +++")
        #_ = IO.puts("other = #{inspect(other)}")
        {other, :keep}
    end
  end


  @doc false
  def concat_act({:replace, prev}, {:replace, next}), do: {:replace, prev ++ next}
  def concat_act({:replace, next}, :keep), do: {:replace, next}
  def concat_act(:keep, x), do: x

  @doc false
  def builder(data, clauses, caller) do
    import Circe
    asts =
      clauses
      |> Enum.map(fn
        ~m/(#{pat} when #{guard} -> #{expr})/w ->
          guard_ast = quote do
            try do unquote(guard) catch _, _ -> false end
          end
          {pat, [{guard_ast, true}], expr}
        ~m/(#{pat} -> #{expr})/w -> {pat, [], expr}
      end)
      |> Enum.map(fn {pat, guard, expr} ->
        pat
        |> PatternMetonyms.View.kind(caller)
        |> case do
          {pat, :keep} ->
            {pat, expr, guard}
          {pat, {:replace, next}} ->
            {pat, expr, next ++ guard}
        end
      end)

      var = Macro.unique_var(:"$view_data", __MODULE__)

      start_ast = quote do unquote(var) = unquote(data) end

      fallback_clause = quote generated: true do _ -> :no_match end |> hd()

      end_ast = quote do raise(CaseClauseError, term: unquote(var)) end

      ast = List.foldr(asts, end_ast, fn ast_t, acc ->
        ast = case ast_t do
          {pat, expr, next} ->
            match_ast = quote do {:matched, unquote(expr)} end

            next_expr =
              next
              |> Enum.reverse()
              |> Enum.reduce(match_ast, fn
                {transform_ast, pat}, next ->
                  transform_ast = quote do (try do {:transformed, unquote(transform_ast)} catch _, _ -> :failed end) end
                  quote generated: true do
                    case unquote(transform_ast) do
                      {:transformed, unquote(pat)} -> unquote(next)
                      _ -> :no_match
                    end
                  end
              end)

            hd(quote do unquote(pat) -> unquote(next_expr) end)
        end

        quote generated: true do
          case unquote(var) do
            unquote([ast, fallback_clause])
          end
          |> case do
            {:matched, x} -> x
            :no_match -> unquote(acc)
          end
        end
        #|> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
      end)

    quote do
      unquote(start_ast)
      unquote(ast)
    end
  end
end
