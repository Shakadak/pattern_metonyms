defmodule PatternMetonyms.View do
  @moduledoc false

  alias PatternMetonyms.Builder

  @doc false
  def inspect_macro(x) do
    _ = IO.puts(Macro.to_string(x))
    x
  end

  @doc false
  def gen_var, do: Macro.var(:"$view_data_#{:erlang.unique_integer([:positive])}", __MODULE__)

  @doc false
  def new_scope, do: {%{}, 0}

  @doc false
  def insert_var({t, n}, v), do: {Map.put(t, v, n), n}

  @doc false
  def fetch_var({t, _n}, v), do: Map.fetch(t, v)

  @doc false
  def level({_t, n}), do: n

  @doc false
  def increase_level({t, n}), do: {t, n + 1}

  @doc false
  def new_acts, do: []

  @doc false
  def prepend_meta(quoted, k, v) when is_atom(k), do: Macro.update_meta(quoted, fn kvs -> [{k, v} | kvs] end)

  @doc false
  def kind_walker(ast, {prev, existing_vars, macro_env}) do
    import Circe

    #_ = IO.inspect(ast, label: ">>> ast")
    #_ = IO.puts(">>> code: #{Macro.to_string(ast)}")

    case ast do
      ~m/(#{{:fn, _, body}} -> #{pat})/ ->
        #_ = IO.puts("+++ Matched fn -> pat +++")
        var_data = gen_var()

        next_data =
          quote do (unquote({:fn, [], body})).(unquote(var_data)) end
        next_ast =
          pat

        next = [{next_data, next_ast}]

        {var_data, {prev ++ next, existing_vars, macro_env}}

      ~m/(#{{_, _, _} = module}.#{function}(#{...args}) -> #{pat})/ ->
        #_ = IO.puts("+++ Matched module.function(args) -> pat +++")
        var_data = gen_var()

        next_data =
          quote do unquote(module).unquote(function)(unquote_splicing([var_data | args])) end
        next_ast =
          pat

        next = [{next_data, next_ast}]

        {var_data, {prev ++ next, existing_vars, macro_env}}

      ~m/(#{view_fun = ~m/#{function}(#{...args})/} -> #{pat})/ ->
        #_ = IO.puts("+++ Matched function(args) -> pat +++")
        _ = case view_fun do
          {_name, meta, context} when is_atom(context) ->
            message =
              """
              Ambiguous function call `#{Macro.to_string(view_fun)}` in raw view.
                Parentheses are required.
              """
            raise(CompileError, file: macro_env.file, line: Keyword.get(meta, :line, macro_env.line), description: message)

          _ -> :ok
        end

        var_data = gen_var()

        next_data =
          quote do unquote(function)(unquote_splicing([var_data | args])) end
        next_ast =
          pat

        next = [{next_data, next_ast}]

        {var_data, {prev ++ next, existing_vars, macro_env}}

      ~m/#{name}(#{...args})/ when is_atom(name) and is_list(args) -> # local syn ?
        #_ = IO.puts("+++ Matched function(args) +++")
        augmented_ast = quote do unquote(:"$pattern_metonyms_viewing_#{name}")(unquote_splicing(args)) end
        augmented_ast
        |> Macro.expand(macro_env)
        |> case do
          ^augmented_ast ->
            #_ = IO.puts("no change")
            kind_walker(args, {prev, existing_vars, macro_env})
            |> case do
              {args, {next, existing_vars, macro_env}} ->
                ast = quote do unquote(name)(unquote_splicing(args)) end

                {ast, {next, existing_vars, macro_env}}
            end

          other ->
            #_ = IO.puts("change")
            kind_walker(other, {prev, existing_vars, macro_env})
        end

      ~m/#{{_, _, _} = module}.#{function}(#{...args})/ -> # remote syn ?
        #_ = IO.puts("+++ Matched module.function(args) +++")
        augmented_ast = quote do unquote(module).unquote(:"$pattern_metonyms_viewing_#{function}")(unquote_splicing(args)) end
        augmented_ast
        |> Macro.expand(macro_env)
        #|> IO.inspect(label: "macro expansion test remote syn")
        |> case do
          ^augmented_ast ->
            #_ = IO.puts("no change")
            kind_walker(args, {prev, existing_vars, macro_env})
            |> case do
              {args, {next, existing_vars, macro_env}} ->
                ast = quote do unquote(module).unquote(function)(unquote_splicing(args)) end

                {ast, {next, existing_vars, macro_env}}
            end

          other ->
            #_ = IO.puts("change")
            kind_walker(other, {prev, existing_vars, macro_env})
        end

      {_, [{:"$pattern_metonyms_visited", true} | _], _} = ast ->
        {ast, {prev, existing_vars, macro_env}}

      {name, _, context} = ast when is_atom(context) ->
        #_ = IO.puts("+++ Matched var +++")
        current_level = level(existing_vars)
        {ast, existing_vars} = case fetch_var(existing_vars, name) do
          {:ok, ^current_level} ->
            #_ = IO.puts("~~~ SAME LEVEL ~~~")
            {ast, existing_vars}

          {:ok, shallower_level} when shallower_level < current_level ->
            #_ = IO.puts("~~~ PINNING ~~~")
            pin = quote do ^unquote(prepend_meta(ast, :"$pattern_metonyms_visited", true)) end
            {pin, existing_vars}

          :error ->
            #_ = IO.puts("~~~ INSERTING ~~~")
            {ast, insert_var(existing_vars, name)}
        end
        {ast, {prev, existing_vars, macro_env}}

      #xs when is_list(xs) ->
      #  _ = IO.puts("+++ Matched list +++")
      ##  {ast, {acts, existing_vars, macro_env}} =
      ##    Enum.reduce(xs, {[], [], existing_vars}, fn x, {asts, acts, existing_vars} ->
      ##      {ast, further_act, existing_vars} = kind(x, existing_vars, macro_env)
      ##      {asts ++ [ast], acts ++ further_act, existing_vars}
      ##    end)

      #  {xs, {prev, existing_vars, macro_env}}

      #{_left, _right} = ast ->
      #  _ = IO.puts("+++ Matched 2-tuple +++")
      ##  {l_ast, l_act, existing_vars} = kind(left, existing_vars, macro_env)
      ##  {r_ast, r_act, existing_vars} = kind(right, existing_vars, macro_env)
      ##  ast = {l_ast, r_ast}
      ##  act = l_act ++ r_act

      #  {ast, {prev, existing_vars, macro_env}}

      other ->
        #_ = IO.puts("+++ Matched something else +++")
        #_ = IO.puts("other = #{inspect(other)}")
        {other, {prev, existing_vars, macro_env}}
    end
    #|> case do
    #  {ast, {acts, existing_vars, _}} = x ->
    #    #_ = IO.inspect(ast, label: "--- result ast")
    #    _ = IO.puts("<<< result code = #{Macro.to_string(ast)}")
    #    _ = IO.puts("<<< next code = #{Macro.to_string(acts)}")
    #    _ = IO.puts("<<< existing_vars = #{inspect(existing_vars)}")
    #    x
    #end
  end

  @doc false
  def unfold(data, pat, macro_env) do
    init_acc = {[{data, pat}], new_scope(), macro_env}
    {nexts, _acc} = do_unfold(init_acc)
    nexts
  end

  @doc false
  def do_unfold({[], existing_vars, _macro_env}), do: {[], existing_vars}
  def do_unfold({nexts, existing_vars, macro_env}) do
    {nextss, existing_vars} =
      nexts
      |> Enum.map_reduce(existing_vars, fn {data, pat}, existing_vars ->
        {pat, acc} =
          Macro.prewalk(pat, {new_acts(), existing_vars, macro_env}, &kind_walker/2)
        acc = update_in(acc, [Access.elem(1)], &increase_level/1)
        {nexts, acc} = do_unfold(acc)
        x = {data, pat}
        {[x | nexts], acc}
      end)

    {Enum.concat(nextss), existing_vars}
  end

  @doc false
  def builder(data, clauses, caller) do
    import Circe

    var = Macro.unique_var(:"$view_data", __MODULE__)
    start_ast = quote do unquote(var) = unquote(data) end

    asts =
      clauses
      |> Enum.map(fn
        ~m/(#{pat} when #{guard} -> #{expr})/w ->
          guard_ast = quote do
            try do unquote(guard) catch _, _ -> false end
          end
          {pat, expr, [{guard_ast, true}]}

        ~m/(#{pat} -> #{expr})/w ->
          {pat, expr, []}
      end)
      |> Enum.map(fn {pat, expr, guard} ->
        [{_var, pat} | nexts] = unfold(var, pat, caller)
        {pat, expr, nexts ++ guard}
      end)

    fallback_clause = quote generated: true do _ -> :no_match end |> Builder.unwrap_clause()

    end_ast = quote do raise(CaseClauseError, term: unquote(var)) end

    ast = Enum.reduce(Enum.reverse(asts), end_ast, fn {pat, expr, next}, acc ->
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

      ast = Builder.unwrap_clause(quote do unquote(pat) -> unquote(next_expr) end)

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
