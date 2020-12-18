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

  import PatternMetonyms.Internals

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

  3) Explicitly bidirectional

  This type of pattern allows the same kind of abstraction as unidirectional one, but also permit defining
  how to construct data from computation (if necessary).
  They take the form:
  ```
  pattern (<name>(<[variables]>) <- (function -> pattern)) when <name>(<[variables]>) = builder
  ```
  where _pattern_ and _builder_ reuse the _variables_.
  `(function -> pattern)` is called a view

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

  Patterns using a view can not be used with `case`.

  Remote calls are not yet supported.

  Unknown yet if anonymous functions can be supported.

  Guards within a pattern definition is considered undefined behavior,
  it may work, but it depends on the context.
  Consider that if the behavior gets a specification, it would be the removal of
  the possibility of using them. Patterns using a view pattern are the recommend
  approach. For example:

  ```
  pattern heart(n) <- (less_than_3 -> {:ok, n})
  ```
  """
  defmacro pattern(ast) do
    PatternMetonyms.Internals.pattern_builder(ast)
  end

  # view

  @doc """
  Macro substitute for `case/2` capable of using pattern metonyms.

  Custom `case` able to use pattern metonyms defined with this module.
  Largely unoptimized, try to avoid side effect in your pattern definitions as using them multiple time
  in `view` will repeat them, but might not later on.

  View pattern (`(function -> pattern)`) may be used raw in here.

  View patterns are simply a pair of a function associated with a pattern
  where the function will be applied to the data passed to `view`
  and the result will be matched with the pattern.

      iex> import PatternMetonyms
      iex> view self() do
      ...>   (is_pid -> true) -> :ok
      ...>   _ -> :ko
      ...> end
      :ok

  Guards can be used outside of the view pattern or the pattern metonym.

      iex> import PatternMetonyms
      iex> view -3 - :rand.uniform(2) do
      ...>   (abs -> x) when x > 3 -> :ok
      ...>   (abs -> x) when x < 3 -> :ko
      ...>   x -> x
      ...> end
      :ok

  Remote calls are not yet supported.

  Anonymous functions are not yet supported.
  """
  defmacro view(data, do: clauses) when is_list(clauses) do
    [last | rev_clauses] = Enum.reverse(clauses)

    var_data = Macro.var(:"$view_data_#{inspect(make_ref())}", __MODULE__)

    rev_tail = case view_folder(last, nil, var_data, __CALLER__) do
      # presumably a catch all pattern
      case_ast = {:case, [], [_, [do: [{:->, _, [[_lhs = {name, meta, con}], _rhs]}, _]]]} when is_atom(name) and is_list(meta) and is_atom(con) ->

        import Access
        case_ast = update_in(case_ast, [elem(2), at(1), at(0), elem(1)], &Enum.take(&1, 1))

        [case_ast]

      _ ->
        fail_ast = quote do
          raise(CaseClauseError, term: unquote(var_data))
        end

        [fail_ast, last]
    end

    view_ast = Enum.reduce(rev_tail ++ rev_clauses, fn x, acc -> view_folder(x, acc, var_data, __CALLER__) end)

    ast = quote do
      unquote(var_data) = unquote(data)
      unquote(view_ast)
    end

    ast
    #|> case do x -> _ = IO.puts("view:\n#{Macro.to_string(x)}") ; x end
  end

  @doc false
  # Bidirectional pattern matching on a clause and giving access to the metadata of the clause.
  pattern clause_ast(meta, lhs, rhs) = {:->, meta, [[lhs], rhs]}

  @doc false
  # Bidirectional pattern matching on guard
  pattern when_ast(meta, lhs, rhs) = {:when, meta, [lhs, rhs]}

  @doc false
  # Unidirictional pattern matching on a view's ast
  pattern view_ast(call, pat) <- [{:->, _, [[call = {_name, _meta, nil}], pat]}]

  @doc false
  # Unidirectional pattern capable of detecting a view clause.
  pattern clause_view(call, pat, rhs) <- clause_ast(_, view_ast(call, pat), rhs)

  @doc false
  # Unidirictional pattern matching on a guarded clause
  pattern guarded_clause(pat, guard, rhs) <- clause_ast(_, when_ast(_, pat, guard), rhs)

  @doc false
  pattern guarded_view(call, pat, guard, rhs) <- guarded_clause(view_ast(call, pat), guard, rhs)

  @doc false
  # Clause using a view with a guard
  def view_folder(guarded_view({name, meta, _}, pat, guard, rhs), acc, data, _caller_env) do
    call = {name, meta, [data]}
    quote do
      case unquote(call) do
        unquote(pat) when unquote(guard) -> unquote(rhs)
        _ -> unquote(acc)
      end
    end
  end

  # Clause using a view
  def view_folder(clause_view({name, meta, _}, pat, rhs), acc, data, _caller_env) do
    call = {name, meta, [data]}
    quote do
      case unquote(call) do
        unquote(pat) -> unquote(rhs)
        _ -> unquote(acc)
      end
    end
  end

  # Clause using a call with a guard, we attempt to expand it using our internal representation
  # if it succeeds, we use the use the result
  # otherwise we simply do as if we know nothing
  def view_folder(clause_ast(meta_clause, when_ast(meta_guard, call, guard), rhs), acc, data, caller_env) when is_call(call) do
    {name, meta, con} = call
    augmented_call = {:"$pattern_metonyms_viewing_#{name}", meta, con}
    case Macro.expand(augmented_call, caller_env) do
      # didn't expand because didn't exist, so we let other macros do their stuff later
      ^augmented_call ->
        quote do
          case unquote(data) do
            unquote(call) when unquote(guard) -> unquote(rhs)
            _ -> unquote(acc)
          end
        end

      # can this recurse indefinitely ?
      new_call ->
        new_clause = clause_ast(meta_clause, when_ast(meta_guard, new_call, guard), rhs)
        view_folder(new_clause, acc, data, caller_env)
    end
  end

  # Clause using a call, we attempt to expand it using our internal representation
  # if it succeeds, we use the use the result
  # otherwise we simply do as if we know nothing
  def view_folder(clause_ast(meta_clause, call, rhs), acc, data, caller_env) when is_call(call) do
    {name, meta, con} = call
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
        new_clause = clause_ast(meta_clause, new_call, rhs)
        view_folder(new_clause, acc, data, caller_env)
    end
  end

  # Clause without anything special
  def view_folder(clause_ast(_, lhs, rhs), acc, data, _caller_env) do
    quote do
      case unquote(data) do
        unquote(lhs) -> unquote(rhs)
        _ -> unquote(acc)
      end
    end
  end
end
