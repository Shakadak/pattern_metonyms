defmodule PatternMetonyms.View do
  def kind(ast, macro_env) do
    kind_go(ast, macro_env)
  end

  #def kind_go(ast, queue, macro_env) do
  #  import Circe
  #  case ast do
  #    xs when is_list(xs) ->
  #      Enum.reduce(xs, queue, fn x, q -> kind_go(x, q, macro_env) end)

  #    ~m/(#{_fun} -> #{_pat})/w ->
  #      :queue.in(:view, queue)


  #    ~m/#{name}(#{[spliced: args]})/ when is_atom(name) and is_list(args) -> # local syn ?
  #      augmented_ast = quote do unquote(:"$pattern_metonyms_viewing_#{name}")(unquote_splicing(args)) end
  #      _ = IO.puts(Macro.to_string(augmented_ast))
  #      augmented_ast
  #      |> Macro.expand(macro_env)
  #      |> IO.inspect(label: "macro expansion test local syn ?")
  #      |> case do
  #        ^augmented_ast ->
  #          q = :queue.in(:normal, queue)
  #          kind_go(args, q, macro_env)
  #        _other -> :queue.in(:syn_2?, queue)
  #      end

  #    ~m/#{{name, meta, context}}/ when is_atom(name) and is_list(meta) and is_atom(context) -> # naked syn ?
  #      augmented_ast = quote do unquote({:"$pattern_metonyms_viewing_#{name}", meta, context}) end
  #      _ = IO.puts(Macro.to_string(augmented_ast))
  #      augmented_ast
  #      |> Macro.expand(macro_env)
  #      |> IO.inspect(label: "macro expansion test naked syn ?")
  #      |> case do
  #        ^augmented_ast -> :queue.in(:normal, queue)
  #        _other -> :queue.in(:syn_3?, queue)
  #      end

  #    other -> :queue.in({:literal, other}, queue)
  #  end
  #end

  def kind_go(ast, macro_env) do
    import Circe
    case ast do
      ~m/(#{{_, _, _} = module}.#{function}(#{[spliced: args]}) -> #{pat})/ ->
        var_data = Macro.var(:"$view_data_#{:erlang.unique_integer([:positive])}", __MODULE__)
        next = fn ast -> quote do
          case unquote(module).unquote(function)(unquote_splicing([var_data | args])) do
            unquote(pat) -> unquote(ast)
            _ -> :no_match
          end
        end end

        {var_data, {:replace, next}}

      ~m/#{name}(#{[spliced: args]})/ when is_atom(name) and is_list(args) -> # local syn ?
        augmented_ast = quote do unquote(:"$pattern_metonyms_viewing_#{name}")(unquote_splicing(args)) end
        #_ = IO.puts(Macro.to_string(augmented_ast))
        augmented_ast
        |> Macro.expand(macro_env)
        |> case do
          ^augmented_ast ->
            kind_go(args, macro_env)
            |> case do
              {args, {:replace, next}} ->
                ast = quote do unquote(name)(unquote_splicing(args)) end

                {ast, {:replace, next}}

              {args, :keep} ->
                ast = quote do unquote(name)(unquote_splicing(args)) end

                {ast, :keep}
            end

          other ->
            kind_go(other, macro_env)
        end

      ~m/#{{_, _, _} = module}.#{function}(#{[spliced: args]})/ -> # remote syn ?
        augmented_ast = quote do unquote(module).unquote(:"$pattern_metonyms_viewing_#{function}")(unquote_splicing(args)) end
        augmented_ast
        |> Macro.expand(macro_env)
        |> IO.inspect(label: "macro expansion test remote syn")
        |> case do
          ^augmented_ast ->
            kind_go(args, macro_env)
            |> case do
              {args, {:replace, next}} ->
                ast = quote do unquote(module).unquote(function)(unquote_splicing(args)) end

                {ast, {:replace, next}}

              {args, :keep} ->
                ast = quote do unquote(module).unquote(function)(unquote_splicing(args)) end

                {ast, :keep}
            end

          other ->
            kind_go(other, macro_env)
        end

      xs when is_list(xs) ->
        {ast, acts} =
          Enum.map(xs, fn x -> kind_go(x, macro_env) end)
          |> Enum.unzip()

        # concat_act is assosiative, but not commutative
        # so folding from the right is fine, but folding from the left will swap the arguments
        act = List.foldr(acts, :keep, &concat_act/2)

        {ast, act}

      {left, right} ->
        {l_ast, l_act} = kind_go(left, macro_env)
        {r_ast, r_act} = kind_go(right, macro_env)
        ast = {l_ast, r_ast}
        act = concat_act(l_act, r_act)

        {ast, act}

      other -> _ = IO.puts("other = #{inspect(other)}") ; {other, :keep}
    end
  end

  
  def concat_act({:replace, prev}, {:replace, next}), do: {:replace, fn ast -> prev.(next.(ast)) end}
  def concat_act({:replace, next}, :keep), do: {:replace, next}
  def concat_act(:keep, x), do: x

  defmacro view(data, do: ast) do
    import Circe
    {asts, mode} = Enum.map_reduce(ast, :case, fn ~m/(#{pat} -> #{expr})/w, mode ->
      pat
      |> kind(__CALLER__)
      |> case do
        {ast, :keep} ->
          {{ast, expr}, mode}
        {ast, {:replace, next}} ->
          {{ast, expr, next}, :view}
      end
    end)


    _ = IO.inspect(mode, label: "mode")
    _ =
      Macro.to_string(ast)
      |> IO.puts()

    case mode do
      :case ->
        ast = Enum.map(asts, fn {pat, expr} -> hd(quote do unquote(pat) -> unquote(expr) end) end)
        quote do
          case unquote(data) do
            unquote(ast)
          end
        end

      :view ->
        var = Macro.unique_var(:banana, __MODULE__)
        start_ast = quote do unquote(var) = unquote(data) end
        fallback_clause = quote do _ -> :no_match end |> hd()
        end_ast = quote do raise(CaseClauseError, term: unquote(var)) end
        ast = List.foldr(asts, end_ast, fn ast_t, acc ->
          ast = case ast_t do
            {pat, expr} ->
              hd(quote do unquote(pat) -> {:matched, unquote(expr)} end)

            {pat, expr, next} ->
              next_expr = next.(quote do {:matched, unquote(expr)} end)
              hd(quote do unquote(pat) -> unquote(next_expr) end)
          end

          quote do
            case unquote(var) do
              unquote([ast, fallback_clause])
            end
            |> case do
              {:matched, x} -> x
              :no_match -> unquote(acc)
            end
          end
          |> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
        end)

        quote do
          unquote(start_ast)
          unquote(ast)
        end
    end
    |> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
  end
end
