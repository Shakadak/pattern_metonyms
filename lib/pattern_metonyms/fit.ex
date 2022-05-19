defmodule PatternMetonyms.Fit do
  @moduledoc false

  @doc false
  def builder(pat, rhs) do
    #_ = IO.inspect(pat)
    vars = identify_vars(pat)
    vars = Enum.to_list(vars)
    var_container = quote do {unquote_splicing(vars)} end
    rhs_var = Macro.unique_var(:"$view_data", __MODULE__)
    quote do
      unquote(rhs_var) = unquote(rhs)
      unquote(var_container) = try do
        view unquote(rhs_var) do
          unquote(pat) -> unquote(var_container)
        end
      catch
        _, _ -> raise(MatchError, term: unquote(rhs_var))
      end
      unquote(rhs_var)
    end
  end

  @doc false
  def identify_vars(ast), do: go_identify_vars(ast, MapSet.new())

  @doc false
  def go_identify_vars(ast, vars) do
    import Circe
    case ast do
      ~m/#{pat} when #{_}/ -> go_identify_vars(pat, vars)
      ~m/(#{_} -> #{pat})/ -> go_identify_vars(pat, vars)
      ~m/#{_function}(#{...args})/ when is_list(args) -> go_identify_vars(args, vars)
      {:_, _, context} when is_atom(context) -> vars
      ast when is_list(ast) -> Enum.reduce(ast, vars, &go_identify_vars/2)
      {_, _} = ast -> go_identify_vars(Tuple.to_list(ast), vars)
      {name, _, context} = ast when is_atom(context) ->
        case Atom.to_string(name) do
          "_" <> _ -> vars
          _ -> MapSet.put(vars, ast)
        end

      _other -> vars
    end
  end
end
