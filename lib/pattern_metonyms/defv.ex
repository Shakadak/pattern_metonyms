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
        #     ...
        #     clauseN -> exprN
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

    body = case rest do
      [] -> body
      other ->
        quote do
          try unquote([body | other])
        end
    end

    case call do
      ~m/#{name}(#{...args}) when #{guards}/ ->
        clause = Builder.unwrap_clause(quote do
          unquote_splicing(args) when unquote(guards) -> unquote(body)
        end)
        {name, Enum.count(args), clause}

      ~m/#{name}(#{...args})/ ->
        clause = Builder.unwrap_clause(quote do
          unquote_splicing(args) -> unquote(body)
        end)
        {name, Enum.count(args), clause}
    end
    #|> IO.inspect(label: "streamline result")
    #|> case do {_, _, ast} = x -> _ = IO.puts(Macro.to_string(ast)) ; x end
  end
end
