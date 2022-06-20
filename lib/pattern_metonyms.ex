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
  pattern <name>(<[variables]>) = <pattern>
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
  pattern <name>(<[variables]>) <- <pattern>
  pattern <name>(<[variables]>) <- (<function> -> <pattern>)
  ```
  where _pattern_ reuses the _variables_.
  `(function -> pattern)` is called a view

      iex> defmodule DoctestTPY do
      ...>   import PatternMetonyms
      ...>
      ...>   pattern head(x) <- [x | _]
      ...>
      ...>   pattern rev_head(x) <- (reverse() -> head(x))
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
  pattern (<name>(<[variables]>) <- (<function> -> <pattern>)) when <name>(<[variables]>) = <builder>
  ```
  where _pattern_ and _builder_ reuse the _variables_.
  `(function -> pattern)` is called a view

      iex> defmodule DoctestTPZ do
      ...>   import PatternMetonyms
      ...>
      ...>   pattern (snoc(x, xs) <- (unsnoc() -> {x, xs}))
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

  Remote function can be used within a view, but the `__MODULE__` alias won't work
  because the expansion is not done at the usage site. It is not yet determined
  which behavior is desired.

      iex> defmodule DoctestTPA do
      ...>   import PatternMetonyms
      ...>
      ...>   pattern rev_head(x) <- (Enum.reverse -> [x | _])
      ...>
      ...>   def blorg(xs) do
      ...>     view xs do
      ...>       rev_head(x) -> x
      ...>     end
      ...>   end
      ...> end
      iex> DoctestTPA.blorg([1, 2, 3])
      3


  Unknown yet if anonymous functions can be supported.

  Guards within a pattern definition is considered undefined behavior,
  it may work, but it depends on the context.
  Consider that if the behavior gets a specification, it would be the removal of
  the possibility of using them. Patterns using a view pattern are the recommend
  approach. For example:

  ```
  pattern heart(n) <- (less_than_3 -> {:ok, n})
  ```

  Patterns can be documented:
  ```
  @doc \"\"\"
  heart matches when the number is heartfelt <3
  \"\"\"
  pattern heart(n) <- (less_than_3() -> {:ok, n})
  ```
  You can then access the doc as usual: `h heart`, or `h Module.heart`.
  """
  defmacro pattern(ast) do
    PatternMetonyms.Pattern.pattern_builder(ast, __CALLER__)
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
      ...>   (is_pid() -> true) -> :ok
      ...>   _ -> :ko
      ...> end
      :ok

  Guards can be used outside of the view pattern or the pattern metonym.

      iex> import PatternMetonyms
      iex> view -3 - :rand.uniform(2) do
      ...>   (abs() -> x) when x > 3 -> :ok
      ...>   (abs() -> x) when x < 3 -> :ko
      ...>   x -> x
      ...> end
      :ok

  Remote calls can be used directly within a view pattern.

      iex> import PatternMetonyms
      iex> view :banana do
      ...>   (Atom.to_string() -> "ba" <> _) -> :ok
      ...>   _ -> :ko
      ...> end
      :ok

  Anonymous functions can be used within a view pattern.
  They can be either used as stored within a variable:

      iex> import PatternMetonyms
      iex> fun = &inspect(&1, pretty: &2)
      iex> view :banana do
      ...>   (fun.(true) -> str) -> str
      ...> end
      ":banana"

  Or defined directly using `Kernel.SpecialForms.fn/1` only:

      iex> import PatternMetonyms
      iex> view 3 do
      ...>   (fn x -> x + 2 end -> n) -> n + 1
      ...> end
      6
  """
  defmacro view(data, do: clauses) when is_list(clauses) do
    PatternMetonyms.View.builder(data, clauses, __CALLER__)
    #|> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
  end

  @doc """
  View with anonymous functions

  ```elixir
  import PatternMetonyms

  id = fnv do (Function.identity() -> x) -> x end
  ```
  """
  defmacro fnv(do: clauses) when is_list(clauses) do
    PatternMetonyms.Fnv.builder(clauses, __CALLER__)
    #|> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
  end

  @doc false
  defmacro __using__(_opts) do
    quote do
      @before_compile {unquote(__MODULE__), :before_compile_defv}

      import unquote(__MODULE__)
    end
  end

  @doc """
  view with named functions

  ```elixir
  use PatternMetonyms

  defv id((Function.identity() -> x)), do: x
  ```
  """
  defmacro defv(call, [{:do, body} | rest]) do
    call = case call do
      {name, meta, nil} -> {name, meta, []}
      call -> call
    end
    x = PatternMetonyms.Defv.streamline(call, body, rest)
    attribute = :defv_accumulator
    _ = Module.register_attribute(__CALLER__.module, attribute, accumulate: true)
    _ = Module.put_attribute(__CALLER__.module, attribute, x)
  end

  @doc false
  defmacro before_compile_defv(_env) do
    attribute = :defv_accumulator
    defv_accumulator = Module.get_attribute(__CALLER__.module, attribute, [])
    _ = Module.delete_attribute(__CALLER__.module, attribute)

    Enum.reverse(defv_accumulator)
    |> Enum.chunk_by(fn {name, arity, _clause} -> {name, arity} end)
    |> Enum.map(fn xs ->
      {name, _, _} = hd(xs)
      clauses = Enum.map(xs, fn {_, _, clause} -> clause end)
      PatternMetonyms.Defv.builder(name, clauses, __CALLER__)
    end)
    #|> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
  end

  @doc """
  `=/2` equivalent to view, named form.

      iex> import PatternMetonyms
      ...> pat = fn {:Just, x} -> x end
      ...> fit((pat.() -> n), {:Just, 3})
      ...> n + 1
      4

  Underscore prefixed variables are ignored, they are therefore unusable outside
  `fit/2`'s first argument.

  Because of the lack of operator with the same associativity and precedence as `=/2`,
  no operator form of `fit/2` is planned. It would otherwise result in unintuitive behaviors.

  Left nesting of `fit/2` will result in a compilation error.
  """
  defmacro fit(lhs, rhs) do
    PatternMetonyms.Fit.builder(lhs, rhs)
    #|> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
  end

  @doc """
  Replaces _all_ occurences of `=/2` in the do block by `fit/2`

      iex> import PatternMetonyms
      ...> fit do
      ...>   (Kernel.+(1) -> x) = 1
      ...>   (Kernel.-(1) -> y) = 41
      ...> end
      ...> x + y
      42

      iex> import PatternMetonyms
      ...> fit(do: (Kernel.+(1) -> x) = (Kernel.-(1) -> y) = 21)
      ...> x + y
      42
  """
  defmacro fit(do: body) do
    import Circe

    Macro.prewalk(body, fn
      ~m/#{pat} when #{guard} = #{expr}/ -> quote do unquote(__MODULE__).fit(unquote(pat) when unquote(guard), unquote(expr)) end
      ~m/#{pat} = #{expr}/ -> quote do unquote(__MODULE__).fit(unquote(pat), unquote(expr)) end
      other -> other
    end)
    #|> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
  end
end
