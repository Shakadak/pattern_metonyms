defmodule PatternMetonyms.Ast do
  @moduledoc false

  def parse_clause(ast) do
    import Circe

    #_ = IO.inspect(ast, label: "parse_clause(ast)", pretty: false)
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

      ~m|(#{pat} -> #{expr})|w ->
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
      {:->, [], [[{:when, [], [[{:->, [], [[{{:., [], [module, function]}, [], args}], pat]}], guard]}], expr]}

        %{
          type: :guarded_stored_fn_view,
          guard: guard,
          expr: expr,
          pat: pat,
          name: name,
          args: args,
          context: context,
        } ->
      {:->, [], [[{:when, [], [[{:->, [], [[{{:., [], [{name, [], context}]}, [], args}], pat]}], guard]}], expr]}

      %{
        type: :guarded_raw_fn_view,
        guard: guard,
        expr: expr,
        pat: pat,
        body: body,
      } ->
      {:->, [], [[{:when, [], [[{:->, [], [[{:fn, [], body}], pat]}], guard]}], expr]}

        %{
          type: :guarded_local_view,
          guard: guard,
          expr: expr,
          pat: pat,
          function: name,
          args: args,
        } ->
      {:->, [], [[{:when, [], [[{:->, [], [[{name, [], args}], pat]}], guard]}], expr]}

        %{
          type: :guarded_remote_syn,
          guard: guard,
          expr: expr,
          module: module,
          function: function,
          args: args,
        } ->
        {:->, [], [[{:when, [], [{{:., [], [module, function]}, [], args}, guard]}], expr]}

        %{
          type: :guarded_local_syn,
          guard: guard,
          expr: expr,
          function: name,
          args: args,
        } ->
        {:->, [], [[{:when, [], [{name, [], args}, guard]}], expr]}

        %{
          type: :guarded_naked_syn,
          guard: guard,
          expr: expr,
          function: name,
          context: context,
        } ->
        {:->, [], [[{:when, [], [{name, [], context}, guard]}], expr]}

        %{
          type: :guarded_clause,
          guard: guard,
          expr: expr,
          pat: pat,
        } ->
        {:->, [], [[{:when, [], [pat, guard]}], expr]}

        %{
          type: :remote_view,
          guard: [],
          expr: expr,
          pat: pat,
          module: module,
          function: function,
          args: args,
        } ->
        {:->, [], [[[{:->, [], [[{{:., [], [module, function]}, [], args}], pat]}]], expr]}

        %{
          type: :stored_fn_view,
          guard: [],
          expr: expr,
          pat: pat,
          name: name,
          context: context,
          args: args,
        } ->
        {:->, [], [[[{:->, [], [[{{:., [], [{name, [], context}]}, [], args}], pat]}]], expr]}

        %{
          type: :raw_fn_view,
          guard: [],
          expr: expr,
          pat: pat,
          body: body,
        } ->
        {:->, [], [[[{:->, [], [[{:fn, [], body}], pat]}]], expr]}

        %{
          type: :local_view,
          guard: [],
          expr: expr,
          pat: pat,
          function: name,
          args: args,
        } ->
        {:->, [], [[[{:->, [], [[{name, [], args}], pat]}]], expr]}

        %{
          type: :remote_syn,
          guard: [],
          expr: expr,
          module: module,
          function: function,
          args: args,
        } ->
        {:->, [], [[{{:., [], [module, function]}, [], args}], expr]}

        %{
          type: :local_syn,
          guard: [],
          expr: expr,
          function: name,
          args: args,
        } ->
        {:->, [], [[{name, [], args}], expr]}

        %{
          type: :naked_syn,
          guard: [],
          expr: expr,
          function: name,
          context: context,
        } ->
        {:->, [], [[{name, [], context}], expr]}

        %{
          type: :clause,
          guard: [],
          expr: expr,
          pat: pat,
        } ->
        {:->, [], [[pat], expr]}

    end
  end
end
