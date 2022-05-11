defmodule PatternMetonyms.Fnv do
  @moduledoc false

  alias PatternMetonyms.Builder

  @doc false
  def builder(clauses, caller) do
    case Builder.analyse_args(clauses) do
      {:error, message} -> raise("fnv improperly defined at #{caller.file}:#{caller.line} with reason: #{message}")
      {:ok, n} ->
        args = Macro.generate_unique_arguments(n, __MODULE__)
        clauses = Enum.map(clauses, &Builder.wrap_pattern/1)
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
