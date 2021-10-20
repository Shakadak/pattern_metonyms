defmodule PatternMetonyms.View do
  def kind(ast, macro_env) do
    import Circe

    case ast do
      ~m/(#{{:fn, _, body}} -> #{pat})/ ->
        var_data = Macro.var(:"$view_data_#{:erlang.unique_integer([:positive])}", __MODULE__)
        {pat, further_act} = kind(pat, macro_env)
        next = [{
          quote do (unquote({:fn, [], body})).(unquote(var_data)) end,
          pat
        }]
        next_act = concat_act({:replace, next}, further_act)

        {var_data, next_act}

      ~m/(#{{_, _, _} = module}.#{function}(#{[spliced: args]}) -> #{pat})/ ->
        var_data = Macro.var(:"$view_data_#{:erlang.unique_integer([:positive])}", __MODULE__)
        {pat, further_act} = kind(pat, macro_env)
        next = [{
          quote do unquote(module).unquote(function)(unquote_splicing([var_data | args])) end,
          pat
        }]
        next_act = concat_act({:replace, next}, further_act)

        {var_data, next_act}

      ~m/(#{view_fun = ~m/#{function}(#{[spliced: args]})/} -> #{pat})/ ->
        _ = case view_fun do
          {_name, meta, context} when is_atom(context) ->
            message =
              """
              Ambiguous function call `#{Macro.to_string(view_fun)}` in raw view in #{macro_env.file}:#{Keyword.get(meta, :line, macro_env.line)}
                Parentheses are required.
              """
            raise(message)

          _ -> :ok
        end

        var_data = Macro.var(:"$view_data_#{:erlang.unique_integer([:positive])}", __MODULE__)
        {pat, further_act} = kind(pat, macro_env)
        next = [{
          quote do unquote(function)(unquote_splicing([var_data | args])) end,
          pat
        }]
        next_act = concat_act({:replace, next}, further_act)

        {var_data, next_act}

      ~m/#{name}(#{[spliced: args]})/ when is_atom(name) and is_list(args) -> # local syn ?
        augmented_ast = quote do unquote(:"$pattern_metonyms_viewing_#{name}")(unquote_splicing(args)) end
        #_ = IO.puts(Macro.to_string(augmented_ast))
        augmented_ast
        |> Macro.expand(macro_env)
        |> case do
          ^augmented_ast ->
            kind(args, macro_env)
            |> case do
              {args, {:replace, next}} ->
                ast = quote do unquote(name)(unquote_splicing(args)) end

                {ast, {:replace, next}}

              {args, :keep} ->
                ast = quote do unquote(name)(unquote_splicing(args)) end

                {ast, :keep}
            end

          other ->
            kind(other, macro_env)
        end

      ~m/#{{_, _, _} = module}.#{function}(#{[spliced: args]})/ -> # remote syn ?
        augmented_ast = quote do unquote(module).unquote(:"$pattern_metonyms_viewing_#{function}")(unquote_splicing(args)) end
        augmented_ast
        |> Macro.expand(macro_env)
        #|> IO.inspect(label: "macro expansion test remote syn")
        |> case do
          ^augmented_ast ->
            kind(args, macro_env)
            |> case do
              {args, {:replace, next}} ->
                ast = quote do unquote(module).unquote(function)(unquote_splicing(args)) end

                {ast, {:replace, next}}

              {args, :keep} ->
                ast = quote do unquote(module).unquote(function)(unquote_splicing(args)) end

                {ast, :keep}
            end

          other ->
            kind(other, macro_env)
        end

      xs when is_list(xs) ->
        {ast, acts} =
          Enum.map(xs, fn x -> kind(x, macro_env) end)
          |> Enum.unzip()

        # concat_act is assosiative, but not commutative
        # so folding from the right is fine, but folding from the left will swap the arguments
        act = List.foldr(acts, :keep, &concat_act/2)

        {ast, act}

      {left, right} ->
        {l_ast, l_act} = kind(left, macro_env)
        {r_ast, r_act} = kind(right, macro_env)
        ast = {l_ast, r_ast}
        act = concat_act(l_act, r_act)

        {ast, act}

      other ->
        #_ = IO.puts("other = #{inspect(other)}")
        {other, :keep}
    end
  end


  def concat_act({:replace, prev}, {:replace, next}), do: {:replace, prev ++ next}
  def concat_act({:replace, next}, :keep), do: {:replace, next}
  def concat_act(:keep, x), do: x
end
