defmodule PatternMetonyms.Internals do
  @moduledoc false

  import Circe

  @doc false
  # implicit bidirectional
  def pattern_builder(~m<#{lhs} = #{pat}>) do
    {name, meta, args} = lhs
    quote do
      defmacro unquote(lhs) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        args_relations = unquote(__MODULE__).relate_args(ast_args, args)
        ast_pat = unquote(Macro.escape(pat))
        unquote(__MODULE__).substitute_ast(ast_pat, args_relations)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end

      @doc false
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        args_relations = unquote(__MODULE__).relate_args(ast_args, args)
        ast_pat = unquote(Macro.escape(pat))
        unquote(__MODULE__).substitute_ast(ast_pat, args_relations)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("pattern [implicit bidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  # unidirectional / with view
  def pattern_builder(~m<#{lhs} <- #{view = ~m/(#{_} -> #{pat})/}>) do
    {name, meta, args} = lhs
    unused_call = {name, meta, Enum.map(args, fn {_, m, c} -> {:_, m, c} end)}
    incorrect_call_message = "Pattern metonym #{Macro.to_string(lhs)} can only be used inside `PatternMetonyms.view/2` clauses."

    quote do
      defmacro unquote(unused_call) do
        raise(unquote(incorrect_call_message))
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
  def pattern_builder(~m<#{lhs} <- #{pat}>) do
    {name, meta, args} = lhs
    quote do
      defmacro unquote(lhs) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        args_relations = unquote(__MODULE__).relate_args(ast_args, args)
        ast_pat = unquote(Macro.escape(pat))
        unquote(__MODULE__).substitute_ast(ast_pat, args_relations)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [unidirectional]:\n#{Macro.to_string(x)}") ; x end
      end

      @doc false
      defmacro unquote({:"$pattern_metonyms_viewing_#{name}", meta, args}) do
        ast_args = unquote(Macro.escape(args))
        args = unquote(args)
        args_relations = unquote(__MODULE__).relate_args(ast_args, args)
        ast_pat = unquote(Macro.escape(pat))
        unquote(__MODULE__).substitute_ast(ast_pat, args_relations)
        #|> case do x -> _ = IO.puts("#{unquote(name)} [unidirectional]:\n#{Macro.to_string(x)}") ; x end
      end
    end
    #|> case do x -> _ = IO.puts("pattern [unidirectional]:\n#{Macro.to_string(x)}") ; x end
  end

  # explicit bidirectional / with view
  def pattern_builder(~m<(#{lhs} <- #{view = ~m/(#{_} -> #{pat})/}) when #{lhs2} = #{expr}>) do
    {name, meta, args} = lhs
    {^name, _meta2, args2} = lhs2

    quote do
      defmacro unquote(lhs2) do
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

  def pattern_builder(ast) do
    raise("pattern not recognized: #{Macro.to_string(ast)}")
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
  def view_folder(data, acc, var_data) do
    #_ = IO.inspect(data, label: "view_folder(data, _, _)")
    case data do
      %{
        type: :guarded_remote_view,
        guard: guard,
        expr: expr,
        pat: pat,
        module: module,
        function: function,
        args: args,
      } ->
        quote do
          case unquote(module).unquote(function)(unquote(var_data), unquote_splicing(args)) do
            unquote(pat) when unquote(guard) -> unquote(expr)
            _ -> unquote(acc)
          end
        end

      %{
        type: :guarded_stored_fn_view,
        guard: guard,
        expr: expr,
        pat: pat,
        name: name,
        args: args,
        context: context,
      } ->
        quote do
          case unquote({name, [], context}).(unquote(var_data), unquote_splicing(args)) do
            unquote(pat) when unquote(guard) -> unquote(expr)
            _ -> unquote(acc)
          end
        end

      %{
        type: :guarded_raw_fn_view,
        guard: guard,
        expr: expr,
        pat: pat,
        body: body,
      } ->
        quote do
          case (unquote({:fn, [], body})).(unquote(var_data)) do
            unquote(pat) when unquote(guard) -> unquote(expr)
            _ -> unquote(acc)
          end
        end

      %{
        type: :guarded_local_view,
        guard: guard,
        expr: expr,
        pat: pat,
        function: function,
        args: args,
      } ->
      quote do
        case unquote(function)(unquote(var_data), unquote_splicing(args)) do
          unquote(pat) when unquote(guard) -> unquote(expr)
          _ -> unquote(acc)
        end
      end

      %{
        type: :guarded_clause,
        guard: guard,
        expr: expr,
        pat: pat,
      } ->
      quote do
        case unquote(var_data) do
          unquote(pat) when unquote(guard) -> unquote(expr)
          _ -> unquote(acc)
        end
      end

      %{
        type: :remote_view,
        guard: [],
        expr: expr,
        pat: pat,
        module: module,
        function: function,
        args: args,
      } ->
        quote do
          case unquote(module).unquote(function)(unquote(var_data), unquote_splicing(args)) do
            unquote(pat) -> unquote(expr)
            _ -> unquote(acc)
          end
        end

      %{
        type: :stored_fn_view,
        guard: [],
        expr: expr,
        pat: pat,
        name: name,
        context: context,
        args: args,
      } ->
      quote do
        case unquote({name, [], context}).(unquote(var_data), unquote_splicing(args)) do
          unquote(pat) -> unquote(expr)
          _ -> unquote(acc)
        end
      end

      %{
        type: :raw_fn_view,
        guard: [],
        expr: expr,
        pat: pat,
        body: body,
      } ->
        quote do
          case (unquote({:fn, [], body})).(unquote(var_data)) do
            unquote(pat) -> unquote(expr)
            _ -> unquote(acc)
          end
        end

      %{
        type: :local_view,
        guard: [],
        expr: expr,
        pat: pat,
        function: function,
        args: args,
      } ->
        quote do
          case unquote(function)(unquote(var_data), unquote_splicing(args)) do
            unquote(pat) -> unquote(expr)
            _ -> unquote(acc)
          end
        end

      %{
        type: :clause,
        guard: [],
        expr: expr,
        pat: pat,
      } ->
        quote do
          case unquote(var_data) do
            unquote(pat) -> unquote(expr)
            _ -> unquote(acc)
          end
        end

    end
  end

  @doc false
  def expand_metonym(%{type: type} = data, env)
  when type in [
    :guarded_remote_syn,
    :guarded_local_syn,
    :guarded_naked_syn,
    :remote_syn,
    :local_syn,
    :naked_syn,
  ]
  do
    transform = fn name -> :"$pattern_metonyms_viewing_#{name}" end
    augmented_data = Map.update!(data, :function, transform)
    augmented_ast = PatternMetonyms.Ast.to_ast(augmented_data)
    case Macro.postwalk(augmented_ast, fn ast -> Macro.expand(ast, env) end) do
      ^augmented_ast ->
        import Circe
        data = case PatternMetonyms.Ast.to_ast(data) do
          ~m/(#{pat} -> #{expr})/w ->
            %{
              type: :clause,
              guard: [],
              expr: expr,
              pat: pat,
            }
        end
        data

      new_ast ->
        new_data = PatternMetonyms.Ast.parse_clause(new_ast)
        expand_metonym(new_data, env)
    end
  end
  def expand_metonym(data, _env), do: data

  # Utils

  @doc false
  def ast_var?({name, meta, con}) when is_atom(name) and is_list(meta) and is_atom(con), do: true
  def ast_var?(_), do: false

  @doc false
  defguard is_var(x) when tuple_size(x) == 3 and is_atom(elem(x, 0)) and is_list(elem(x, 1)) and is_atom(elem(x, 2))

  @doc false
  defguard is_call(x) when tuple_size(x) == 3 and is_atom(elem(x, 0)) and is_list(elem(x, 1)) and is_list(elem(x, 2))
end
