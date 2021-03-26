defmodule PatternMetonyms.Ast do
  @moduledoc false

  def parse_clause(ast) do
    import Circe

    case ast do
      ~m|((#{{_, _, _} = module}.#{function}(#{[spliced: args]}) -> #{pat}) when #{guard} -> #{expr})|w ->
        %{
          type: :guarded_remote_view,
          guard: guard,
          expr: expr,
          pat: pat,
          module: module,
          function: function,
          args: args,
        }

      ~m|((#{{name, _, context}}.(#{[spliced: args]}) -> #{pat}) when #{guard} -> #{expr})|w
        when is_atom(name) and is_atom(context) and is_list(args) ->
          %{
            type: :guarded_stored_fn_view,
            guard: guard,
            expr: expr,
            pat: pat,
            name: name,
            args: args,
            context: context,
          }

      ~m|((#{{:fn, _, body}} -> #{pat}) when #{guard} -> #{expr})|w
        when is_list(body) ->
          %{
            type: :guarded_raw_fn_view,
            guard: guard,
            expr: expr,
            pat: pat,
            body: body,
          }

      ~m|((#{name}(#{[spliced: args]}) -> #{pat}) when #{guard} -> #{expr})|w
        when is_atom(name)
        and is_list(args) ->
        %{
          type: :guarded_local_view,
          guard: guard,
          expr: expr,
          pat: pat,
          function: name,
          args: args,
        }

      ~m|((#{{name, meta, context}} -> #{pat}) when #{guard} -> #{expr})|w
        when is_atom(name)
        and is_list(meta)
        and is_atom(context) ->
        %{
          type: :guarded_local_view,
          guard: guard,
          expr: expr,
          pat: pat,
          function: name,
          args: [],
        }

      ~m|(#{{_, _, _} = module}.#{function}(#{[spliced: args]}) when #{guard} -> #{expr})|w ->
        %{
          type: :guarded_remote_syn,
          guard: guard,
          expr: expr,
          module: module,
          function: function,
          args: args,
        }

      ~m|(#{name}(#{[spliced: args]}) when #{guard} -> #{expr})|w
        when is_atom(name)
        and is_list(args) ->
        %{
          type: :guarded_local_syn,
          guard: guard,
          expr: expr,
          function: name,
          args: args,
        }

      ~m|(#{{name, meta, context}} when #{guard} -> #{expr})|w
        when is_atom(name)
        and is_list(meta)
        and is_atom(context) ->
        %{
          type: :guarded_naked_syn,
          guard: guard,
          expr: expr,
          function: name,
          context: context,
        }

      ~m|(#{pat} when #{guard} -> #{expr})|w ->
        %{
          type: :guarded_clause,
          guard: guard,
          expr: expr,
          pat: pat,
        }

      ~m|((#{{_, _, _} = module}.#{function}(#{[spliced: args]}) -> #{pat}) -> #{expr})|w ->
        %{
          type: :remote_view,
          guard: [],
          expr: expr,
          pat: pat,
          module: module,
          function: function,
          args: args,
        }

      ~m|((#{{name, _, context}}.(#{[spliced: args]}) -> #{pat}) -> #{expr})|w
        when is_atom(name) and is_atom(context) and is_list(args) ->
          %{
            type: :stored_fn_view,
            guard: [],
            expr: expr,
            pat: pat,
            name: name,
            context: context,
            args: args,
          }

      ~m|((#{{:fn, _, body}} -> #{pat}) -> #{expr})|w
        when is_list(body) ->
            %{
              type: :raw_fn_view,
              guard: [],
              expr: expr,
              pat: pat,
              body: body,
            }

      ~m"((#{name}(#{[spliced: args]}) -> #{pat}) -> #{expr})"w
        when is_atom(name)
        and is_list(args) ->
        %{
          type: :local_view,
          guard: [],
          expr: expr,
          pat: pat,
          function: name,
          args: args,
        }

      ~m"((#{{name, meta, context}} -> #{pat}) -> #{expr})"w
        when is_atom(name)
        and is_list(meta)
        and is_atom(context) ->
        %{
          type: :local_view,
          guard: [],
          expr: expr,
          pat: pat,
          function: name,
          args: [],
        }

      ~m|(#{{_, _, _} = module}.#{function}(#{[spliced: args]}) -> #{expr})|w ->
        %{
          type: :remote_syn,
          guard: [],
          expr: expr,
          module: module,
          function: function,
          args: args,
        }

      ~m|(#{name}(#{[spliced: args]}) -> #{expr})|w
        when is_atom(name)
        and is_list(args) ->
        %{
          type: :local_syn,
          guard: [],
          expr: expr,
          function: name,
          args: args,
        }

      ~m|(#{{name, meta, context}} -> #{expr})|w
        when is_atom(name)
        and is_list(meta)
        and is_atom(context) ->
        %{
          type: :naked_syn,
          guard: [],
          expr: expr,
          function: name,
          context: context,
        }

      ~m/(#{pat} -> #{expr})/w ->
        %{
          type: :clause,
          guard: [],
          expr: expr,
          pat: pat,
        }
    end
  end

  def to_ast(data) do
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
      [x] = quote do ((unquote(module).unquote(function)(unquote_splicing(args)) -> unquote(pat)) when unquote(guard) -> unquote(expr)) end
      x

        %{
          type: :guarded_stored_fn_view,
          guard: guard,
          expr: expr,
          pat: pat,
          name: name,
          args: args,
          context: context,
        } ->
      [x] = quote do ((unquote({name, [], context}).(unquote_splicing(args)) -> unquote(pat)) when unquote(guard) -> unquote(expr)) end
      x

      %{
        type: :guarded_raw_fn_view,
        guard: guard,
        expr: expr,
        pat: pat,
        body: body,
      } ->
          [x] = quote do ((unquote({:fn, [], body}) -> unquote(pat)) when unquote(guard) -> unquote(expr)) end
          x

        %{
          type: :guarded_local_view,
          guard: guard,
          expr: expr,
          pat: pat,
          function: name,
          args: args,
        } ->
        [x] = quote do ((unquote(name)(unquote_splicing(args)) -> unquote(pat)) when unquote(guard) -> unquote(expr)) end
        x

        %{
          type: :guarded_remote_syn,
          guard: guard,
          expr: expr,
          module: module,
          function: function,
          args: args,
        } ->
        [x] = quote do (unquote(module).unquote(function)(unquote_splicing(args)) when unquote(guard) -> unquote(expr)) end
        x

        %{
          type: :guarded_local_syn,
          guard: guard,
          expr: expr,
          function: name,
          args: args,
        } ->
        [x] = quote do (unquote(name)(unquote_splicing(args)) when unquote(guard) -> unquote(expr)) end
        x

        %{
          type: :guarded_naked_syn,
          guard: guard,
          expr: expr,
          function: name,
          context: context,
        } ->
        [x] = quote do (unquote({name, [], context}) when unquote(guard) -> unquote(expr)) end
        x

        %{
          type: :guarded_clause,
          guard: guard,
          expr: expr,
          pat: pat,
        } ->
        [x] = quote do (unquote(pat) when unquote(guard) -> unquote(expr)) end
        x

        %{
          type: :remote_view,
          guard: [],
          expr: expr,
          pat: pat,
          module: module,
          function: function,
          args: args,
        } ->
        [x] = quote do ((unquote(module).unquote(function)(unquote_splicing(args)) -> unquote(pat)) -> unquote(expr)) end
        x

        %{
          type: :stored_fn_view,
          guard: [],
          expr: expr,
          pat: pat,
          name: name,
          context: context,
          args: args,
        } ->
        [x] = quote do ((unquote({name, [], context}).(unquote_splicing(args)) -> unquote(pat)) -> unquote(expr)) end
        x

        %{
          type: :raw_fn_view,
          guard: [],
          expr: expr,
          pat: pat,
          body: body,
        } ->
        [x] = quote do ((unquote({:fn, [], body}) -> unquote(pat)) -> unquote(expr)) end
        x

        %{
          type: :local_view,
          guard: [],
          expr: expr,
          pat: pat,
          function: name,
          args: args,
        } ->
        [x] = quote do ((unquote(name)(unquote_splicing(args)) -> unquote(pat)) -> unquote(expr)) end
        x

        %{
          type: :remote_syn,
          guard: [],
          expr: expr,
          module: module,
          function: function,
          args: args,
        } ->
        [x] = quote do (unquote(module).unquote(function)(unquote_splicing(args)) -> unquote(expr)) end
        x

        %{
          type: :local_syn,
          guard: [],
          expr: expr,
          function: name,
          args: args,
        } ->
        [x] = quote do (unquote(name)(unquote_splicing(args)) -> unquote(expr)) end
        x

        %{
          type: :naked_syn,
          guard: [],
          expr: expr,
          function: name,
          context: context,
        } ->
        [x] = quote do (unquote({name, [], context}) -> unquote(expr)) end
        x

        %{
          type: :clause,
          guard: [],
          expr: expr,
          pat: pat,
        } ->
        [x] = quote do (unquote(pat) -> unquote(expr)) end
        x

    end
  end
end
