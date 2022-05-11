defmodule PatternMetonyms.Defv do
  @moduledoc false

  alias PatternMetonyms.Builder

  @doc false
  def builder(name, clauses, caller) do
    case Builder.analyse_args(clauses) do
      {:error, message} -> raise("defv improperly defined at #{caller.file}:#{caller.line} with reason: #{message}")
      {:ok, n} ->
        args = Macro.generate_unique_arguments(n, __MODULE__)
        clauses = Enum.map(clauses, &Builder.wrap_pattern/1)
        #|> case do x -> _ = IO.puts(Macro.to_string(x)) ; x end

        # def name(arg1, argN) do
        #   PatternMetonyms.view {arg1, argN} do
        #     clause1 -> expr1
        #     clause 2 -> expr2
        #   end
        # end
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
        pat = quote do unquote_splicing(args) end
        clause = Builder.generate_clause(pat, guards, body)
        {name, Enum.count(args), clause}
      ~m/#{name}(#{[spliced: args]})/ ->
        pat = quote do unquote_splicing(args) end
        clause = Builder.generate_clause(pat, body)
        {name, Enum.count(args), clause}
    end
    #|> IO.inspect(label: "streamline result")
    #|> case do {_, _, ast} = x -> _ = IO.puts(Macro.to_string(ast)) ; x end
  end
end
