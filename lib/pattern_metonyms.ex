defmodule PatternMetonyms do
  @moduledoc """
  Documentation for `PatternMetonyms`.
  """

  @doc """
  implicit bidirectional
  target : pattern just2(a, b) = just({a, b})
  currently work as is for that kind of complexity

  unidirectional
  target : pattern head(x) <- [x | _]
  but doesn't work as is
  "pattern(head(x) <- [x | _])"

  explicit bidirectional
  target : pattern polar(r, a) <- (pointPolar -> {r, a}) when polar(r, a) = polarPoint(r, a)
  but doesn't work as is
  "pattern (polar(r, a) <- (pointPolar -> {r, a})) when polar(r, a) = polarPoint(r, a) "
  """
  # implicit bidirectional
  # lhs = {:just2, [], [{:a, [], Elixir}, {:b, [], Elixir}]}  # just2(a, b)
  # pat = {:just, [], [{{:a, [], Elixir}, {:b, [], Elixir}}]} # just({a, b})
  defmacro pattern(_syn = {:=, _, [lhs, pat]}) do
    {name, meta, args} = lhs
    quote do
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
        args_relation = Map.new(Enum.zip(ast_args, args), relate)

        ast_pat = unquote(Macro.escape(pat))

        Macro.prewalk(ast_pat, fn x ->
          case {ast_var?(x), x} do
            {false, x} -> x
            {true, {name, _, con}} ->
              case Map.fetch(args_relation, {name, con}) do
                :error -> x
                {:ok, substitute} -> substitute
              end
          end
        end)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end

      defmacro unquote(lhs) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
        args_relation = Map.new(Enum.zip(ast_args, args), relate)

        ast_pat = unquote(Macro.escape(pat))

        Macro.prewalk(ast_pat, fn x ->
          case {ast_var?(x), x} do
            {false, x} -> x
            {true, {name, _, con}} ->
              case Map.fetch(args_relation, {name, con}) do
                :error -> x
                {:ok, substitute} -> substitute
              end
          end
        end)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("pattern [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  # unidirectional / with view
  defmacro pattern({:<-, _, [lhs, view = [{:->, _, [[_], pat]}]]}) do
    {name, meta, args} = lhs
    quote do
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
        args_relation = Map.new(Enum.zip(ast_args, args), relate)

        ast_pat = unquote(Macro.escape(pat))

        ast_pat_updated = Macro.prewalk(ast_pat, fn x ->
          case {ast_var?(x), x} do
            {false, x} -> x
            {true, {name, _, con}} ->
              case Map.fetch(args_relation, {name, con}) do
                :error -> x
                {:ok, substitute} -> substitute
              end
          end
        end)

        ast_view = unquote(Macro.escape(view))

        import Access
        updated_view = put_in(ast_view, [at(0), elem(2), at(1)], ast_pat_updated)
        #updated_view = [{:->, meta, [[fun], ast_pat_updated]}]
        #|> case do x -> _ = IO.puts("#{unquote(name)} [unidirectional]:\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("pattern [unidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  # unidirectional
  # lhs = {:head, [], [{:x, [], Elixir}]}                  # head(x)
  # pat = [{:|, [], [{:x, [], Elixir}, {:_, [], Elixir}]}] # [x | _]
  defmacro pattern({:<-, _, [lhs, pat]}) do
    {name, meta, args} = lhs
    quote do
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
        args_relation = Map.new(Enum.zip(ast_args, args), relate)

        ast_pat = unquote(Macro.escape(pat))

        Macro.prewalk(ast_pat, fn x ->
          case {ast_var?(x), x} do
            {false, x} -> x
            {true, {name, _, con}} ->
              case Map.fetch(args_relation, {name, con}) do
                :error -> x
                {:ok, substitute} -> substitute
              end
          end
        end)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end

      defmacro unquote(lhs) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
        args_relation = Map.new(Enum.zip(ast_args, args), relate)

        ast_pat = unquote(Macro.escape(pat))

        Macro.prewalk(ast_pat, fn x ->
          case {ast_var?(x), x} do
            {false, x} -> x
            {true, {name, _, con}} ->
              case Map.fetch(args_relation, {name, con}) do
                :error -> x
                {:ok, substitute} -> substitute
              end
          end
        end)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("pattern [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  # explicit bidirectional / with view
  # lhs = {:polar, [], [{:r, [], Elixir}, {:a, [], Elixir}]}       # polar(r, a)
  # fun = {:pointPolar, [], Elixir}                                # pointPolar
  # pat = {{:r, [], Elixir}, {:a, [], Elixir}}                     # {r, a}
  # lhs2 = {:polar, [], [{:r, [], Elixir}, {:a, [], Elixir}]}      # polar(r, a)
  # expr = {:polarPoint, [], [{:r, [], Elixir}, {:a, [], Elixir}]} # polarPoint(r, a)
  defmacro pattern({:when, _, [{:<-, _, [lhs, view = [{:->, _, [[_], pat]}]]}, {:=, _, [lhs2, expr]}]}) do
    {name, meta, args} = lhs
    {^name, _meta2, args2} = lhs2

    quote do
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
        args_relation = Map.new(Enum.zip(ast_args, args), relate)

        ast_pat = unquote(Macro.escape(pat))

        ast_pat_updated = Macro.prewalk(ast_pat, fn x ->
          case {ast_var?(x), x} do
            {false, x} -> x
            {true, {name, _, con}} ->
              case Map.fetch(args_relation, {name, con}) do
                :error -> x
                {:ok, substitute} -> substitute
              end
          end
        end)

        ast_view = unquote(Macro.escape(view))

        import Access
        updated_view = put_in(ast_view, [at(0), elem(2), at(1)], ast_pat_updated)
        #updated_view = [{:->, meta, [[fun], ast_pat_updated]}]
        #|> case do x -> _ = IO.puts("#{unquote(name)} [expr bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end

      defmacro unquote(lhs2) do
        ast_args = unquote(Macro.escape(args2))
        args = unquote(args2)
        relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
        args_relation = Map.new(Enum.zip(ast_args, args), relate)

        ast_expr = unquote(Macro.escape(expr))

        Macro.prewalk(ast_expr, fn x ->
          case {ast_var?(x), x} do
            {false, x} -> x
            {true, {name, _, con}} ->
              case Map.fetch(args_relation, {name, con}) do
                :error -> x
                {:ok, substitute} -> substitute
              end
          end
        end)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [explicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("pattern [explicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  defmacro pattern(ast) do
    raise("pattern not recognized: #{Macro.to_string(ast)}")
  end

  # view

  defmacro view(data, do: clauses) when is_list(clauses) do
    [last | rev_clauses] = Enum.reverse(clauses)


    rev_tail = case view_folder(last, nil, data, __CALLER__) do
      # presumably a catch all pattern
      case_ast = {:case, [], [_, [do: [{:->, _, [[_lhs = {name, meta, con}], _rhs]}, _]]]} when is_atom(name) and is_list(meta) and is_atom(con) ->

        import Access
        case_ast = update_in(case_ast, [elem(2), at(1), at(0), elem(1)], &Enum.take(&1, 1))

        [case_ast]

      _ ->
        fail_ast = quote do
          raise(CaseClauseError, term: unquote(data))
        end

        [fail_ast, last]
    end

    ast = Enum.reduce(rev_tail ++ rev_clauses, fn x, acc -> view_folder(x, acc, data, __CALLER__) end)

    ast
    #|> case do x -> _ = IO.puts("view:\n#{Macro.to_string(x)}") ; x end
  end

  def view_folder({:->, _, [[[{:->, _, [[{name, meta, nil}], pat]}]], rhs]}, acc, data, _caller_env) do
    call = {name, meta, [data]}
    quote do
      case unquote(call) do
        unquote(pat) -> unquote(rhs)
        _ -> unquote(acc)
      end
    end
  end

  def view_folder({:->, meta_clause, [[{name, meta, con} = call], rhs]}, acc, data, caller_env) when is_atom(name) and is_list(meta) and is_list(con) do
    augmented_call = {:"$pattern_metonyms_viewing_#{name}", meta, con}
    case Macro.expand(augmented_call, caller_env) do
      # didn't expand because didn't exist, so we let other macros do their stuff later
      ^augmented_call ->
        quote do
          case unquote(data) do
            unquote(call) -> unquote(rhs)
            _ -> unquote(acc)
          end
        end

      # can this recurse indefinitely ?
      new_call ->
        new_clause = {:->, meta_clause, [[new_call], rhs]}
        view_folder(new_clause, acc, data, caller_env)
    end
  end

  def view_folder({:->, _, [[lhs = {name, meta, con}], rhs]}, acc, data, _caller_env) when is_atom(name) and is_list(meta) and is_atom(con) do
    quote do
      case unquote(data) do
        unquote(lhs) -> unquote(rhs)
        _ -> unquote(acc)
      end
    end
  end

  def view_folder({:->, _, [[lhs], rhs]}, acc, data, _caller_env) do
    quote do
      case unquote(data) do
        unquote(lhs) -> unquote(rhs)
        _ -> unquote(acc)
      end
    end
  end

  # Utils

  def ast_var?({name, meta, con}) when is_atom(name) and is_list(meta) and is_atom(con), do: true
  def ast_var?(_), do: false
end
