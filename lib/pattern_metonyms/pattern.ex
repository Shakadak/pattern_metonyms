defmodule PatternMetonyms.Pattern do
  @moduledoc false

  import Circe

  alias PatternMetonyms.Builder

  @doc false
  # implicit bidirectional
  def pattern_builder(~m<#{lhs} = #{pat}>, _caller) do
    {name, meta, args} = Builder.normalize_parens(lhs)

    pattern_block = inject_args(args, pat)

    quote do
      defmacro unquote(lhs) do
        unquote(pattern_block)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end

      @doc false
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        unquote(pattern_block)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("pattern [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  # unidirectional / with view
  def pattern_builder(~m<#{lhs} <- #{view = ~m/(#{fun} -> #{pat})/}>, caller) do
    _ = Builder.check_view_pattern_ambiguity(fun, caller, "unidirectional")

    {name, meta, args} = call = Builder.normalize_parens(lhs)


    import PatternMetonyms.Access
    unused_call = update_in(call, [args(), name()], fn _ -> :_ end)
    incorrect_call_message = "Pattern metonym #{inspect(caller.module)}.#{name}/#{length(args)} can only be used inside `PatternMetonyms.view/2` clauses."

    pattern_block = inject_args(args, pat)

    quote do
      defmacro unquote(unused_call) do
        raise(CompileError, file: __CALLER__.file, line: __CALLER__.line, description: unquote(incorrect_call_message))
      end

      @doc false
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_pat_updated = unquote(pattern_block)
        ast_view = unquote(Macro.escape(view))
        updated_view = put_in(ast_view, [PatternMetonyms.Access.view_pattern()], ast_pat_updated)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [unidirectional]:\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("pattern [unidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  # unidirectional
  def pattern_builder(~m<#{lhs} <- #{pat}>, caller) do
    {name, meta, args} = Builder.normalize_parens(lhs)

    pattern_block = inject_args(args, pat)

    incorrect_call_message = "Pattern metonym #{inspect(caller.module)}.#{name}/#{length(args)} can only be used inside a matching context. (`case/2` or `PatternMetonyms.view/2`)"

    quote do
      defmacro unquote(lhs) do
        if not Macro.Env.in_match?(__CALLER__) do
          raise(CompileError, file: __CALLER__.file, line: __CALLER__.line, description: unquote(incorrect_call_message))
        end
        unquote(pattern_block)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [unidirectional]:\n#{Macro.to_string(x)}") ; x end
      end

      @doc false
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        unquote(pattern_block)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [unidirectional]:\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("pattern [unidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  # explicit bidirectional / with view
  def pattern_builder(~m<(#{lhs} <- #{view = ~m/(#{fun} -> #{pat})/}) when #{lhs2} = #{expr}>, caller) do
    _ = Builder.check_view_pattern_ambiguity(fun, caller, "explicit bidirectional")

    {name, meta, args} = Builder.normalize_parens(lhs)
    {^name, _meta2, args2} = Builder.normalize_parens(lhs2)

    incorrect_call_message = """
    Pattern metonym #{inspect(caller.module)}.#{name}/#{length(args)} cannot be used inside `case/2` clauses.
    Use `PatternMetonyms.view/2` instead."
    """

    construction_pattern_block = inject_args(args2, expr)
    deconstruction_pattern_block = inject_args(args, pat)

    quote do
      defmacro unquote(lhs2) do
        if Macro.Env.in_match?(__CALLER__) do
          raise(CompileError, file: __CALLER__.file, line: __CALLER__.line, description: unquote(incorrect_call_message))
        end
        ast_expr_updated = unquote(construction_pattern_block)
        ast_expr_updated
        #|> case do x -> _ = IO.puts("#{unquote(name)} [explicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end

      @doc false
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_pat_updated = unquote(deconstruction_pattern_block)
        ast_view = unquote(Macro.escape(view))
        updated_view = put_in(ast_view, [PatternMetonyms.Access.view_pattern()], ast_pat_updated)
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

  @doc false
  def inject_args(args, ast) do
    # This is essentially the whole machinery used to inject the AST present at use site
    # into the right hand side of the pattern definition.
    quote do
      ast_args = unquote(Macro.escape(args))
      args = unquote(args)
      args_relations = unquote(__MODULE__).relate_args(ast_args, args)
      ast_pat = unquote(Macro.escape(ast))
      unquote(__MODULE__).substitute_ast(ast_pat, args_relations)
    end
  end

  # Utils

  @doc false
  def ast_var?({name, meta, con}) when is_atom(name) and is_list(meta) and is_atom(con), do: true
  def ast_var?(_), do: false
end
