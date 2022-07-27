defmodule PatternMetonyms.Builder do
  @moduledoc false

  @doc false
  def pop_guard(args) do
    [guard | rxs] = Enum.reverse(args)
    xs = Enum.reverse(rxs)
    {guard, xs}
  end

  @doc false
  def unwrap_clause([clause]), do: clause

  @doc false
  def generate_clause(args, expr) do
    hd(quote do unquote(args) -> unquote(expr) end)
  end

  @doc false
  def generate_clause(args, guard, expr) do
    hd(quote do unquote(args) when unquote(guard) -> unquote(expr) end)
  end

  @doc false
  def count_args(clause) do
    import Circe

    case clause do
      ~m/(#{{:when, _meta, args}} -> #{_a})/w ->
        {_guard, xs} = pop_guard(args)
        Enum.count(xs)

      ~m/(#{...xs} -> #{_a})/w ->
        Enum.count(xs)
    end
  end

  @doc false
  def analyse_args(clauses) do
    result = Enum.reduce(clauses, {}, fn
      x, {} -> {:matching, count_args(x)}
      x, {:matching, n} ->
        n2 = count_args(x)
        case {n, n2} do
          {n, n} -> {:matching, n}
          {n, n2} -> {:different, [n2, n]}
        end
      x, {:different, ns} ->
        n = count_args(x)
        case n in ns do
          true -> {:different, ns}
          false -> {:different, [n | ns]}
        end
    end)
    case result do
      {:matching, n} -> {:ok, n}
      {:different, _ns} -> {:error, "Found variable amount of argument in clauses."}
    end
  end

  @doc false
  def wrap_pattern(clause) do
    import Circe
    case clause do
      ~m/(#{{:when, _meta, args}} -> #{expr})/w ->
        {guard, xs} = pop_guard(args)
        pat = quote(do: {unquote_splicing(xs)})
        unwrap_clause(quote do unquote(pat) when unquote(guard) -> unquote(expr) end)

      ~m/(#{...xs} -> #{expr})/w ->
        pat = quote(do: {unquote_splicing(xs)})
        unwrap_clause(quote do unquote(pat) -> unquote(expr) end)
    end
  end

  @doc false
  # Convert 0-arity without parens into 0-arity with parens to streamline the data.
  def normalize_parens({name, meta, x}) when not is_list(x), do: {name, meta, []}
  def normalize_parens(t), do: t

  @doc false
  def check_view_pattern_ambiguity(fun, env, type) do
    case fun do
      {_name, meta, context} when is_atom(context)  ->
        message =
          """
          Ambiguous function call `#{Macro.to_string(fun)}` in #{type} pattern with view.
            Parentheses are required.
          """
        raise(CompileError, file: env.file, line: Keyword.get(meta, :line, env.line), description: message)

      _ -> :ok
    end
  end
end
