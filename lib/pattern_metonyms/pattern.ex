defmodule PatternMetonyms.Pattern do
  @moduledoc false

  import Circe

  @doc false
  # implicit bidirectional
  def pattern_builder(~m<#{lhs} = #{pat}>, _caller) do
    # Convert 0-arity without parens into 0-arity with parens to streamline the data.
    {name, meta, args} = case lhs do
      {name, meta, x} when not is_list(x) -> {name, meta, []}
      t -> t
    end

    pattern_block = quote do
      ast_args = unquote(Macro.escape(args))
      args = unquote(args)
      args_relations = unquote(__MODULE__).relate_args(ast_args, args)
      ast_pat = unquote(Macro.escape(pat))
      unquote(__MODULE__).substitute_ast(ast_pat, args_relations)
      #|> case do x -> _ = IO.puts("#{unquote(name)} [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
    end

    quote do
      defmacro unquote(lhs) do
        unquote(pattern_block)
      end

      @doc false
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        unquote(pattern_block)
      end
    end
    #|> case do x -> _ = IO.puts("pattern [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  # unidirectional / with view
  def pattern_builder(~m<#{lhs} <- #{view = ~m/(#{fun} -> #{pat})/}>, caller) do
    case fun do
      {_name, _meta, context} when is_atom(context)  ->
        message =
          """
          Ambiguous function call `#{Macro.to_string(fun)}` in unidirectional pattern with view.
            Parentheses are required.
          """
        raise(CompileError, file: caller.file, line: caller.line, description: message)

      _ -> :ok
    end

    # Convert 0-arity without parens into 0-arity with parens to streamline the data.
    {name, meta, args} = case lhs do
      {name, meta, x} when not is_list(x) -> {name, meta, []}
      t -> t
    end
    unused_call = {name, meta, Enum.map(args, fn {_, m, c} -> {:_, m, c} end)}
    incorrect_call_message = "Pattern metonym #{inspect(caller.module)}.#{name}/#{length(args)} can only be used inside `PatternMetonyms.view/2` clauses."

    quote do
      defmacro unquote(unused_call) do
        raise(CompileError, file: __CALLER__.file, line: __CALLER__.line, description: unquote(incorrect_call_message))
      end

      @doc false
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        args_relations = unquote(__MODULE__).relate_args(ast_args, args)
        ast_pat = unquote(Macro.escape(pat))
        ast_pat_updated = unquote(__MODULE__).substitute_ast(ast_pat, args_relations)
        ast_view = unquote(Macro.escape(view))

        import Access
        updated_view = put_in(ast_view, [at(0), elem(2), at(1)], ast_pat_updated)
        #updated_view = [{:->, meta, [[fun], ast_pat_updated]}]
        #|> case do x -> _ = IO.puts("#{unquote(name)} [unidirectional]:\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("pattern [unidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  # unidirectional
  def pattern_builder(~m<#{lhs} <- #{pat}>, caller) do
    # Convert 0-arity without parens into 0-arity with parens to streamline the data.
    {name, meta, args} = case lhs do
      {name, meta, x} when not is_list(x) -> {name, meta, []}
      t -> t
    end

    pattern_block = quote do
      ast_args = unquote(Macro.escape(args))
      args = unquote(args)
      args_relations = unquote(__MODULE__).relate_args(ast_args, args)
      ast_pat = unquote(Macro.escape(pat))
      unquote(__MODULE__).substitute_ast(ast_pat, args_relations)
      #|> case do x -> _ = IO.puts("#{unquote(name)} [unidirectional]:\n#{Macro.to_string(x)}") ; x end
    end

    incorrect_call_message = "Pattern metonym #{inspect(caller.module)}.#{name}/#{length(args)} can only be used inside a matching context. (`case/2` or `PatternMetonyms.view/2`)"

    quote do
      defmacro unquote(lhs) do
        if not Macro.Env.in_match?(__CALLER__) do
          raise(CompileError, file: __CALLER__.file, line: __CALLER__.line, description: unquote(incorrect_call_message))
        end
        unquote(pattern_block)
      end

      @doc false
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        unquote(pattern_block)
      end
    end
    #|> case do x -> _ = IO.puts("pattern [unidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  # explicit bidirectional / with view
  def pattern_builder(~m<(#{lhs} <- #{view = ~m/(#{fun} -> #{pat})/}) when #{lhs2} = #{expr}>, caller) do
    case fun do
      {_name, _meta, context} when is_atom(context)  ->
        message =
          """
          Ambiguous function call `#{Macro.to_string(fun)}` in explicit bidirectional pattern with view.
            Parentheses are required.
          """
        raise(CompileError, file: caller.file, line: caller.line, description: message)

      _ -> :ok
    end

    # Convert 0-arity without parens into 0-arity with parens to streamline the data.
    {name, meta, args} = case lhs do
      {name, meta, x} when not is_list(x) -> {name, meta, []}
      t -> t
    end
    {^name, _meta2, args2} = case lhs2 do
      {name, meta, x} when not is_list(x) -> {name, meta, []}
      t -> t
    end

    incorrect_call_message = """
    Pattern metonym #{inspect(caller.module)}.#{name}/#{length(args)} cannot be used inside `case/2` clauses.
    Use `PatternMetonyms.view/2` instead."
    """

    quote do
      defmacro unquote(lhs2) do
        if Macro.Env.in_match?(__CALLER__) do
          raise(CompileError, file: __CALLER__.file, line: __CALLER__.line, description: unquote(incorrect_call_message))
        end
        ast_args = unquote(Macro.escape(args2))
        args = unquote(args2)
        args_relations = unquote(__MODULE__).relate_args(ast_args, args)
        ast_expr = unquote(Macro.escape(expr))
        ast_expr_updated = unquote(__MODULE__).substitute_ast(ast_expr, args_relations)
        ast_expr_updated
        #|> case do x -> _ = IO.puts("#{unquote(name)} [explicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end

      @doc false
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        args_relations = unquote(__MODULE__).relate_args(ast_args, args)
        ast_pat = unquote(Macro.escape(pat))
        ast_pat_updated = unquote(__MODULE__).substitute_ast(ast_pat, args_relations)
        ast_view = unquote(Macro.escape(view))

        import Access
        updated_view = put_in(ast_view, [at(0), elem(2), at(1)], ast_pat_updated)
        #updated_view = [{:->, meta, [[fun], ast_pat_updated]}]
        #|> case do x -> _ = IO.puts("#{unquote(name)} [explicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("pattern [explicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  def pattern_builder(ast, caller) do
    raise(CompileError, file: caller.file, line: caller.line, description: "Pattern not recognized: #{Macro.to_string(ast)}")
  end

  @doc false
  def relate_args(ast_args, args) do
    relate = fn {{name, _, con}, substitute} -> {{name, con}, substitute} end
    args_relations = Map.new(Enum.zip(ast_args, args), relate)
    args_relations
  end

  @doc false
  def substitute_ast(ast_pat, args_relations) do
    Macro.postwalk(ast_pat, fn x ->
      case {unquote(__MODULE__).ast_var?(x), x} do
        {false, x} -> x
        {true, {name, _, con}} ->
          case Map.fetch(args_relations, {name, con}) do
            :error -> x
            {:ok, substitute} -> substitute
          end
      end
    end)
  end

  # Utils

  @doc false
  def ast_var?({name, meta, con}) when is_atom(name) and is_list(meta) and is_atom(con), do: true
  def ast_var?(_), do: false

  @doc false
  defguard is_var(x) when tuple_size(x) == 3 and is_atom(elem(x, 0)) and is_list(elem(x, 1)) and is_atom(elem(x, 2))

  @doc false
  defguard is_call(x) when tuple_size(x) == 3 and is_atom(elem(x, 0)) and is_list(elem(x, 1)) and is_list(elem(x, 2))
end
