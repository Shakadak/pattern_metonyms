defmodule PatternMetonyms.Ast do
  @moduledoc false

  import Circe

  defmacrop softmatch(pattern, do: data) do
    quote do
      fn
        unquote(pattern) -> data = (unquote(data)) ; {:match, data}
        _ -> :no_match
      end
    end
  end

  def ordered_metas do
    [
      guarded_remote_view(),
      guarded_stored_fn_view(),
      guarded_raw_fn_view(),
      guarded_local_wa_view(),
      guarded_local_view(),
      guarded_remote_syn(),
      guarded_local_syn(),
      guarded_naked_syn(),
      guarded_clause(),
      remote_view(),
      stored_fn_view(),
      raw_fn_view(),
      local_wa_view(),
      local_view(),
      remote_syn(),
      local_syn(),
      naked_syn(),
      clause(),
    ]
  end

  def guarded_remote_view do
    parse = softmatch ~m/((#{{_, _, _} = module}.#{function}(#{[spliced: args]}) -> #{pat}) when #{guard} -> #{expr})/w do
      %{
        type: :guarded_remote_view,
        guard: guard,
        expr: expr,
        pat: pat,
        module: module,
        function: function,
        args: args,
      }
    end

    to_ast = softmatch %{
      type: :guarded_remote_view,
      guard: guard,
      expr: expr,
      pat: pat,
      module: module,
      function: function,
      args: args,
    } do
      [x] = quote do ((unquote(module).unquote(function)(unquote_splicing(args)) -> unquote(pat)) when unquote(guard) -> unquote(expr)) end
      x
    end

    to_view = softmatch %{
        type: :guarded_remote_view,
        guard: guard,
        expr: expr,
        pat: pat,
        module: module,
        function: function,
        args: args,
      } do
        fn var_data, acc ->
        quote do
          case unquote(module).unquote(function)(unquote(var_data), unquote_splicing(args)) do
            unquote(pat) when unquote(guard) -> unquote(expr)
            _ -> unquote(acc)
          end
        end
        end
      end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def guarded_stored_fn_view do
    parse = softmatch ~m/((#{{name, _, context}}.(#{[spliced: args]}) -> #{pat}) when #{guard} -> #{expr})/w
    when is_atom(name) and is_atom(context) and is_list(args) do
      %{
        type: :guarded_stored_fn_view,
        guard: guard,
        expr: expr,
        pat: pat,
        name: name,
        args: args,
        context: context,
      }
    end

    to_ast = softmatch %{
      type: :guarded_stored_fn_view,
      guard: guard,
      expr: expr,
      pat: pat,
      name: name,
      args: args,
      context: context,
    } do
      [x] = quote do ((unquote({name, [], context}).(unquote_splicing(args)) -> unquote(pat)) when unquote(guard) -> unquote(expr)) end
      x
    end

    to_view = softmatch %{
        type: :guarded_stored_fn_view,
        guard: guard,
        expr: expr,
        pat: pat,
        name: name,
        args: args,
        context: context,
    } do
      fn var_data, acc ->
        quote do
          case unquote({name, [], context}).(unquote(var_data), unquote_splicing(args)) do
            unquote(pat) when unquote(guard) -> unquote(expr)
            _ -> unquote(acc)
          end
        end
      end
    end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def guarded_raw_fn_view do
    parse = softmatch ~m/((#{{:fn, _, body}} -> #{pat}) when #{guard} -> #{expr})/w
      when is_list(body) do
      %{
        type: :guarded_raw_fn_view,
        guard: guard,
        expr: expr,
        pat: pat,
        body: body,
      }
      end

    to_ast = softmatch %{
      type: :guarded_raw_fn_view,
      guard: guard,
      expr: expr,
      pat: pat,
      body: body,
    } do
      [x] = quote do ((unquote({:fn, [], body}) -> unquote(pat)) when unquote(guard) -> unquote(expr)) end
      x
    end

    to_view = softmatch %{
        type: :guarded_raw_fn_view,
        guard: guard,
        expr: expr,
        pat: pat,
        body: body,
    } do
      fn var_data, acc ->
        quote do
          case (unquote({:fn, [], body})).(unquote(var_data)) do
            unquote(pat) when unquote(guard) -> unquote(expr)
            _ -> unquote(acc)
          end
        end
      end
    end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def guarded_local_wa_view do
    parse = softmatch ~m/((#{name}(#{[spliced: args]}) -> #{pat}) when #{guard} -> #{expr})/w
    when is_atom(name) and is_list(args) do
      %{
        type: :guarded_local_view,
        guard: guard,
        expr: expr,
        pat: pat,
        function: name,
        args: args,
      }
    end

    to_ast = softmatch %{
      type: :guarded_local_view,
      guard: guard,
      expr: expr,
      pat: pat,
      function: name,
      args: args,
    } do
      [x] = quote do ((unquote(name)(unquote_splicing(args)) -> unquote(pat)) when unquote(guard) -> unquote(expr)) end
      x
    end

    to_view = softmatch %{
        type: :guarded_local_view,
        guard: guard,
        expr: expr,
        pat: pat,
        function: function,
        args: args,
    } do
      fn var_data, acc ->
      quote do
        case unquote(function)(unquote(var_data), unquote_splicing(args)) do
          unquote(pat) when unquote(guard) -> unquote(expr)
          _ -> unquote(acc)
        end
      end
      end
    end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def guarded_local_view do
    parse = softmatch ~m/((#{{name, meta, context}} -> #{pat}) when #{guard} -> #{expr})/w
    when is_atom(name) and is_list(meta) and is_atom(context) do
      %{
        type: :guarded_local_view,
        guard: guard,
        expr: expr,
        pat: pat,
        function: name,
        args: [],
      }
    end

    to_ast = softmatch %{
      type: :guarded_local_view,
      guard: guard,
      expr: expr,
      pat: pat,
      function: name,
      args: args,
    } do
      [x] = quote do ((unquote(name)(unquote_splicing(args)) -> unquote(pat)) when unquote(guard) -> unquote(expr)) end
      x
    end

    to_view = fn _ -> :no_match end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def guarded_remote_syn do
    parse = softmatch ~m/(#{{_, _, _} = module}.#{function}(#{[spliced: args]}) when #{guard} -> #{expr})/w do
      %{
        type: :guarded_remote_syn,
        guard: guard,
        expr: expr,
        module: module,
        function: function,
        args: args,
      }
    end

    to_ast = softmatch %{
      type: :guarded_remote_syn,
      guard: guard,
      expr: expr,
      module: module,
      function: function,
      args: args,
    } do
      [x] = quote do (unquote(module).unquote(function)(unquote_splicing(args)) when unquote(guard) -> unquote(expr)) end
      x
    end

    to_view = fn _ -> :no_match end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def guarded_local_syn do
    parse = softmatch ~m/(#{name}(#{[spliced: args]}) when #{guard} -> #{expr})/w
    when is_atom(name) and is_list(args) do
      %{
        type: :guarded_local_syn,
        guard: guard,
        expr: expr,
        function: name,
        args: args,
      }
    end

    to_ast = softmatch %{
      type: :guarded_local_syn,
      guard: guard,
      expr: expr,
      function: name,
      args: args,
    } do
      [x] = quote do (unquote(name)(unquote_splicing(args)) when unquote(guard) -> unquote(expr)) end
      x
    end

    to_view = fn _ -> :no_match end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def guarded_naked_syn do
    parse = softmatch ~m/(#{{name, meta, context}} when #{guard} -> #{expr})/w
    when is_atom(name) and is_list(meta) and is_atom(context) do
      %{
        type: :guarded_naked_syn,
        guard: guard,
        expr: expr,
        function: name,
        context: context,
      }
    end

    to_ast = softmatch %{
      type: :guarded_naked_syn,
      guard: guard,
      expr: expr,
      function: name,
      context: context,
    } do
      [x] = quote do (unquote({name, [], context}) when unquote(guard) -> unquote(expr)) end
      x
    end

    to_view = fn _ -> :no_match end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def guarded_clause do
    parse = softmatch ~m/(#{pat} when #{guard} -> #{expr})/w do
      %{
        type: :guarded_clause,
        guard: guard,
        expr: expr,
        pat: pat,
      }
    end

    to_ast = softmatch %{
      type: :guarded_clause,
      guard: guard,
      expr: expr,
      pat: pat,
    } do
      [x] = quote do (unquote(pat) when unquote(guard) -> unquote(expr)) end
      x
    end

    to_view = softmatch %{
        type: :guarded_clause,
        guard: guard,
        expr: expr,
        pat: pat,
    } do
      fn var_data, acc ->
      quote do
        case unquote(var_data) do
          unquote(pat) when unquote(guard) -> unquote(expr)
          _ -> unquote(acc)
        end
      end
      end
    end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def remote_view do
    parse = softmatch ~m/((#{{_, _, _} = module}.#{function}(#{[spliced: args]}) -> #{pat}) -> #{expr})/w do
      %{
        type: :remote_view,
        guard: [],
        expr: expr,
        pat: pat,
        module: module,
        function: function,
        args: args,
      }
    end

    to_ast = softmatch %{
      type: :remote_view,
      guard: [],
      expr: expr,
      pat: pat,
      module: module,
      function: function,
      args: args,
    } do
      [x] = quote do ((unquote(module).unquote(function)(unquote_splicing(args)) -> unquote(pat)) -> unquote(expr)) end
      x
    end

    to_view = softmatch %{
        type: :remote_view,
        guard: [],
        expr: expr,
        pat: pat,
        module: module,
        function: function,
        args: args,
    } do
      fn var_data, acc ->
        quote do
          case unquote(module).unquote(function)(unquote(var_data), unquote_splicing(args)) do
            unquote(pat) -> unquote(expr)
            _ -> unquote(acc)
          end
        end
      end
    end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def stored_fn_view do
    parse = softmatch ~m/((#{{name, _, context}}.(#{[spliced: args]}) -> #{pat}) -> #{expr})/w
    when is_atom(name) and is_atom(context) and is_list(args) do
      %{
        type: :stored_fn_view,
        guard: [],
        expr: expr,
        pat: pat,
        name: name,
        context: context,
        args: args,
      }
    end

    to_ast = softmatch %{
      type: :stored_fn_view,
      guard: [],
      expr: expr,
      pat: pat,
      name: name,
      context: context,
      args: args,
    } do
      [x] = quote do ((unquote({name, [], context}).(unquote_splicing(args)) -> unquote(pat)) -> unquote(expr)) end
      x
    end

    to_view = softmatch %{
        type: :stored_fn_view,
        guard: [],
        expr: expr,
        pat: pat,
        name: name,
        context: context,
        args: args,
    } do
      fn var_data, acc ->
        quote do
        case unquote({name, [], context}).(unquote(var_data), unquote_splicing(args)) do
          unquote(pat) -> unquote(expr)
          _ -> unquote(acc)
        end
      end
      end
    end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def raw_fn_view do
    parse = softmatch ~m/((#{{:fn, _, body}} -> #{pat}) -> #{expr})/w
      when is_list(body) do
      %{
        type: :raw_fn_view,
        guard: [],
        expr: expr,
        pat: pat,
        body: body,
      }
      end

    to_ast = softmatch %{
      type: :raw_fn_view,
      guard: [],
      expr: expr,
      pat: pat,
      body: body,
    } do
      [x] = quote do ((unquote({:fn, [], body}) -> unquote(pat)) -> unquote(expr)) end
      x
    end

    to_view = softmatch %{
        type: :raw_fn_view,
        guard: [],
        expr: expr,
        pat: pat,
        body: body,
    } do
      fn var_data, acc ->
        quote do
          case (unquote({:fn, [], body})).(unquote(var_data)) do
            unquote(pat) -> unquote(expr)
            _ -> unquote(acc)
          end
        end
      end
    end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def local_wa_view do
    parse = softmatch ~m/((#{name}(#{[spliced: args]}) -> #{pat}) -> #{expr})/w
    when is_atom(name) and is_list(args) do
      %{
        type: :local_view,
        guard: [],
        expr: expr,
        pat: pat,
        function: name,
        args: args,
      }
    end

    to_ast = softmatch %{
      type: :local_view,
      guard: [],
      expr: expr,
      pat: pat,
      function: name,
      args: args,
    } do
      [x] = quote do ((unquote(name)(unquote_splicing(args)) -> unquote(pat)) -> unquote(expr)) end
      x
    end

    to_view = fn _ -> :no_match end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def local_view do
    parse = softmatch ~m/((#{{name, meta, context}} -> #{pat}) -> #{expr})/w
    when is_atom(name) and is_list(meta) and is_atom(context) do
      %{
        type: :local_view,
        guard: [],
        expr: expr,
        pat: pat,
        function: name,
        args: [],
      }
    end

    to_ast = softmatch %{
      type: :local_view,
      guard: [],
      expr: expr,
      pat: pat,
      function: name,
      args: args,
    } do
      [x] = quote do ((unquote(name)(unquote_splicing(args)) -> unquote(pat)) -> unquote(expr)) end
      x
    end

    to_view = softmatch %{
        type: :local_view,
        guard: [],
        expr: expr,
        pat: pat,
        function: function,
        args: args,
    } do
      fn var_data, acc ->
        quote do
          case unquote(function)(unquote(var_data), unquote_splicing(args)) do
            unquote(pat) -> unquote(expr)
            _ -> unquote(acc)
          end
        end
      end
    end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def remote_syn do
    parse = softmatch ~m/(#{{_, _, _} = module}.#{function}(#{[spliced: args]}) -> #{expr})/w do
      %{
        type: :remote_syn,
        guard: [],
        expr: expr,
        module: module,
        function: function,
        args: args,
      }
    end

    to_ast = softmatch %{
      type: :remote_syn,
      guard: [],
      expr: expr,
      module: module,
      function: function,
      args: args,
    } do
      [x] = quote do (unquote(module).unquote(function)(unquote_splicing(args)) -> unquote(expr)) end
      x
    end

    to_view = fn _ -> :no_match end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def local_syn do
    parse = softmatch ~m/(#{name}(#{[spliced: args]}) -> #{expr})/w
    when is_atom(name) and is_list(args) do
      %{
        type: :local_syn,
        guard: [],
        expr: expr,
        function: name,
        args: args,
      }
    end

    to_ast = softmatch %{
      type: :local_syn,
      guard: [],
      expr: expr,
      function: name,
      args: args,
    } do
      [x] = quote do (unquote(name)(unquote_splicing(args)) -> unquote(expr)) end
      x
    end

    to_view = fn _ -> :no_match end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def naked_syn do
    parse = softmatch ~m/(#{{name, meta, context}} -> #{expr})/w
    when is_atom(name) and is_list(meta) and is_atom(context) do
      %{
        type: :naked_syn,
        guard: [],
        expr: expr,
        function: name,
        context: context,
      }
    end

    to_ast = softmatch %{
      type: :naked_syn,
      guard: [],
      expr: expr,
      function: name,
      context: context,
    } do
      [x] = quote do (unquote({name, [], context}) -> unquote(expr)) end
      x
    end

    to_view = fn _ -> :no_match end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def clause do
    parse = softmatch ~m/(#{pat} -> #{expr})/w do
      %{
        type: :clause,
        guard: [],
        expr: expr,
        pat: pat,
      }
    end

    to_ast = softmatch %{
      type: :clause,
      guard: [],
      expr: expr,
      pat: pat,
    } do
      [x] = quote do (unquote(pat) -> unquote(expr)) end
      x
    end

    to_view = softmatch %{
        type: :clause,
        guard: [],
        expr: expr,
        pat: pat,
    } do
      fn (var_data, acc) ->
        quote do
          case unquote(var_data) do
            unquote(pat) -> unquote(expr)
            _ -> unquote(acc)
          end
        end
      end
    end

    %{
      parse: parse,
      to_ast: to_ast,
      to_view: to_view,
    }
  end

  def parse_clause(ast) do
    {:match, data} = Enum.reduce_while(ordered_metas(), :no_match, fn meta, acc ->
      case meta.parse.(ast) do
        {:match, _data} = x -> {:halt, x}
        :no_match -> {:cont, acc}
      end
    end)

    data
  end

  def to_ast(data) do
    {:match, ast} = Enum.reduce_while(ordered_metas(), :no_match, fn meta, acc ->
      case meta.to_ast.(data) do
        {:match, _data} = x -> {:halt, x}
        :no_match -> {:cont, acc}
      end
    end)

    ast
  end

  def view_folder(data, acc, var_data) do
    {:match, builder} = Enum.reduce_while(ordered_metas(), :no_match, fn meta, acc ->
      case meta.to_view.(data) do
        {:match, _data} = x -> {:halt, x}
        :no_match -> {:cont, acc}
      end
    end)

    builder.(var_data, acc)
  end
end
