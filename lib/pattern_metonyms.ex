defmodule PatternMetonyms do
  @moduledoc """
  Reusing the description from the paper:

  Pattern synonyms allow to abstract over patterns used in pattern matching,
  notably by allowing to use computation instead of being limited to concrete data.

  Pattern metonyms are an implementations of this, but because of the limitation of the language,
  it can not be considered the same, so metonyms was chosen as a synonym to synonyms.

  Unlike in Haskell, few metonym definitions can be used with `case/2`,
  other forms of patterns can only be used in combination with `view/2`.
  """

  @doc """
  Macro used to define pattern metonyms.

  There are three types of pattern, listed below with examples:

  1) Implicitly Bidirectional
  The simplest type of pattern, because of its symmetry requirement, it can only
  be defined using concrete data (or adapted macro). Therefore no computation is
  allowed, and they are thus compatible with `case` and function heads.
  They take the form:
  ```
  pattern <name>(<[variables]>) = pattern
  ```
  where _pattern_ reuses the _variables_

      ```
      iex> defmodule DoctestTPX do
      ...>   import PatternMetonyms
      ...>
      ...>   pattern ok(x)    = {:ok, x}
      ...>   pattern error(x) = {:error, x}
      ...>
      ...>   pattern cons(x, xs) = [x | xs]
      ...>
      ...>   def foo(x) do
      ...>     view x do
      ...>       ok(a)    -> a
      ...>       error(b) -> b
      ...>     end
      ...>   end
      ...>
      ...>   def bar(x) do
      ...>     case x do
      ...>       ok(a)    -> a
      ...>       error(b) -> b
      ...>     end
      ...>   end
      ...>
      ...>   def baz(ok(a)   ), do: a
      ...>   def baz(error(b)), do: b
      ...>
      ...>   def mk_ok(x), do: ok(x)
      ...>
      ...>   def blorg(xs) do
      ...>     view xs do
      ...>       cons(x, xs) -> cons(x, Enum.map(xs, fn x -> -x end))
      ...>     end
      ...>   end
      ...> end
      iex> DoctestTPX.foo({:ok, :banana})
      :banana
      iex> DoctestTPX.foo({:error, :split})
      :split
      iex> DoctestTPX.bar({:ok, :peach})
      :peach
      iex> DoctestTPX.baz({:error, :melba})
      :melba
      iex> DoctestTPX.mk_ok(:melba)
      {:ok, :melba}
      iex> DoctestTPX.blorg([1, 2, 3])
      [1, -2, -3]
      ```

  2) Unidirectional
  This type of pattern is read only, it may be used as abstraction over pattern matching on concrete data type
  that can not be reused to construct data, or as abstraction over views, as explained in `view/2`.
  They take the form:
  ```
  pattern <name>(<[variables]>) <- pattern
  pattern <name>(<[variables]>) <- (function -> pattern)
  ```
  where _pattern_ reuses the _variables_.
  `(function -> pattern)` is called a view

      ```
      iex> defmodule DoctestTPY do
      ...>   import PatternMetonyms
      ...>
      ...>   pattern head(x) <- [x | _]
      ...>
      ...>   pattern rev_head(x) <- (reverse -> head(x))
      ...>
      ...>   def reverse(xs), do: Enum.reverse(xs)
      ...>
      ...>   def foo(xs) do
      ...>     view xs do
      ...>       head(x) -> x
      ...>       []      -> []
      ...>     end
      ...>   end
      ...>
      ...>   def bar(x) do
      ...>     case x do
      ...>       head(a) -> a
      ...>       []      -> []
      ...>     end
      ...>   end
      ...>
      ...>   def baz(head(a)), do: a
      ...>
      ...>   def blorg(xs) do
      ...>     view xs do
      ...>       rev_head(x) -> x
      ...>     end
      ...>   end
      ...> end
      iex> DoctestTPY.foo([1, 2, 3])
      1
      iex> DoctestTPY.bar([1, 2, 3])
      1
      iex> DoctestTPY.baz([1, 2, 3])
      1
      iex> DoctestTPY.blorg([1, 2, 3])
      3
      ```

  3) Explicitly bidirectional
  This type of pattern allows the same kind of abstraction as unidirectional one, but also permit defining
  how to construct data from computation (if necessary).
  The take the form:
  ```
  pattern (<name>(<[variables]>) <- (function -> pattern)) when <name>(<[variables]>) = builder
  ```
  where _pattern_ and _builder_ reuse the _variables_.
  `(function -> pattern)` is called a view

      ```
      iex> defmodule DoctestTPZ do
      ...>   import PatternMetonyms
      ...>
      ...>   pattern (snoc(x, xs) <- (unsnoc -> {x, xs}))
      ...>     when snoc(x, xs) = Enum.reverse([x | Enum.reverse(xs)])
      ...>
      ...>   defp unsnoc([]), do: :error
      ...>   defp unsnoc(xs) do
      ...>     [x | rev_tail] = Enum.reverse(xs)
      ...>     {x, Enum.reverse(rev_tail)}
      ...>   end
      ...>
      ...>   def foo(xs) do
      ...>     view xs do
      ...>       snoc(x, _) -> x
      ...>       []      -> []
      ...>     end
      ...>   end
      ...>
      ...>   def bar(xs) do
      ...>     view xs do
      ...>       snoc(x, xs) -> snoc(-x, xs)
      ...>       []      -> []
      ...>     end
      ...>   end
      ...> end
      iex> DoctestTPZ.foo([1, 2, 3])
      3
      iex> DoctestTPZ.bar([1, 2, 3])
      [1, 2, -3]
      ```

  Patterns using a view can not be used with `case`.

  Currently does not support remote calls.
  """
  # implicit bidirectional
  defmacro pattern(_syn = {:=, _, [lhs, pat]}) do
    {name, meta, args} = lhs
    quote do
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
        args_relation = Map.new(Enum.zip(ast_args, args), relate)

        ast_pat = unquote(Macro.escape(pat))

        Macro.postwalk(ast_pat, fn x ->
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

        Macro.postwalk(ast_pat, fn x ->
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

        ast_pat_updated = Macro.postwalk(ast_pat, fn x ->
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
  defmacro pattern({:<-, _, [lhs, pat]}) do
    {name, meta, args} = lhs
    quote do
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
        args_relation = Map.new(Enum.zip(ast_args, args), relate)

        ast_pat = unquote(Macro.escape(pat))

        Macro.postwalk(ast_pat, fn x ->
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

        Macro.postwalk(ast_pat, fn x ->
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

        ast_pat_updated = Macro.postwalk(ast_pat, fn x ->
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

        Macro.postwalk(ast_expr, fn x ->
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

  @doc """
  Macro substitute for `case/2` capable of using pattern metonyms

  Custom `case` able to use pattern metonyms defined with this module.
  Largely unoptimized, try to avoid side effect in your pattern definition as using them multiple time
  in `view` will repeat them, but might not later on.

  view pattern (`(function -> pattern)`) may be used raw in here.

      ```
      iex> import PatternMetonyms
      iex> view self() do
      ...>   (is_pid -> true) -> :ok
      ...>   _ -> :ko
      ...> end
      :ok
      ```

  Remote calls are not yet supported.
  Anonymous functions are not yet supported
  Guards are not yet supported.
  """
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

  @doc false
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

  @doc false
  def ast_var?({name, meta, con}) when is_atom(name) and is_list(meta) and is_atom(con), do: true
  def ast_var?(_), do: false
end
