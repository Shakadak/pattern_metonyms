defmodule PatternMetonyms.Defv do
  @moduledoc false

  @doc false
  def count_args(clause) do
    import Circe

    case clause do
      ~m/(#{{:when, _meta, args}} -> #{_a})/w ->
        [_guard | xs] = Enum.reverse(args)
        Enum.count(xs)

      ~m/(#{[spliced: xs]} -> #{_a})/w -> Enum.count(xs)
    end
  end

  @doc false
  def analyse_args(clauses) do
    Enum.reduce(clauses, {}, fn
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
    |> case do
      {:matching, n} -> {:ok, n}
      {:different, _ns} -> {:error, "Found variable amount of argument in clauses."}
    end
  end

  @doc false
  def builder(name, clauses, caller) do
    case analyse_args(clauses) do
      {:error, message} -> raise("defv improperly defined at #{caller.file}:#{caller.line} with reason: #{message}")
      {:ok, n} ->
        args = Macro.generate_unique_arguments(n, __MODULE__)
        import Circe
        clauses = Enum.map(clauses, fn
          ~m/(#{{:when, _meta, args}} -> #{expr})/w ->
            [guard | rxs] = Enum.reverse(args)
            xs = Enum.reverse(rxs)
            quote do {unquote_splicing(xs)} when unquote(guard) -> unquote(expr) end

          ~m/(#{[spliced: xs]} -> #{expr})/w -> quote do {unquote_splicing(xs)} -> unquote(expr) end
        end)
        |> Enum.map(&hd/1)
        #|> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end

        quote do
          def unquote(name)(unquote_splicing(args)) do
            PatternMetonyms.view {unquote_splicing(args)} do
              unquote(clauses)
            end
          end
        end
        #|> IO.inspect(label: "builder result")
        #|> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end

    end
  end

  def streamline(call, body, rest) do
    import Circe

    #_ = IO.inspect(call, label: "streamline call")
    #    |> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end

    body = case rest do
      [] -> body
      other ->
        quote do
          try unquote([body | other])
        end
    end

    case call do
      ~m/#{name}(#{[spliced: args]}) when #{guards}/ ->
        clause = hd(quote do unquote_splicing(args) when unquote(guards) -> unquote(body) end)
        {name, Enum.count(args), clause}
      ~m/#{name}(#{[spliced: args]})/ ->
        clause = hd(quote do unquote_splicing(args) -> unquote(body) end)
        {name, Enum.count(args), clause}
    end
    #|> IO.inspect(label: "streamline result")
    #|> case do {_, _, ast} = x -> _ = IO.puts(Macro.to_string(ast)) ; x end
  end
end
