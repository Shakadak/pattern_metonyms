defmodule PatternMetonyms.Fnv do
  @moduledoc false

  @doc false
  def count_args(clause) do
    import Circe

    case clause do
      ~m/(#{xs} when #{_y} -> #{_z})/w -> Enum.count(xs)
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
  def builder(clauses, caller) do
    case analyse_args(clauses) do
      {:error, message} -> raise("fnv improperly defined at #{caller.file}:#{caller.line} with reason: #{message}")
      {:ok, n} ->
        args = Macro.generate_unique_arguments(n, __MODULE__)
        import Circe
        clauses = Enum.map(clauses, fn
          ~m/(#{xs} when #{guard} -> #{expr})/ -> quote do {unquote_splicing(xs)} when unquote(guard) -> unquote(expr) end
          ~m/(#{[spliced: xs]} -> #{expr})/w -> quote do {unquote_splicing(xs)} -> unquote(expr) end
        end)
        |> Enum.map(&hd/1)
        #|> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end

        quote do
          fn unquote_splicing(args) ->
            PatternMetonyms.view {unquote_splicing(args)} do
              unquote(clauses)
            end
          end
        end
        #|> IO.inspect(label: "builder result")
        #|> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end
          
    end
  end
end
