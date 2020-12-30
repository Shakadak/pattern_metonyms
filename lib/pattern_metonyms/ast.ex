defmodule PatternMetonyms.Ast do
  @moduledoc false

  def parse_clause(ast) do
    case ast do
      {:->, _, [[{:when, _, [[{:->, _, [[{{:., _, [module = {_, _, _}, function]}, _, args}], pat]}], guard]}], expr]} ->
        %{
          type: :guarded_remote_view,
          guard: guard,
          expr: expr,
          pat: pat,
          module: module,
          function: function,
          args: args,
        }

      {:->, _, [[{:when, _, [[{:->, _, [[{name, meta, args}], pat]}], guard]}], expr]}
        when is_atom(name)
        and is_list(meta)
      and is_list(args) ->
        %{
          type: :guarded_local_view,
          guard: guard,
          expr: expr,
          pat: pat,
          function: name,
          args: args,
        }

      {:->, _, [[{:when, _, [[{:->, _, [[{name, meta, context}], pat]}], guard]}], expr]}
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

        {:->, _, [[{:when, _, [{{:., _, [module = {_, _, _}, function]}, _, args}, guard]}], expr]} ->
        %{
          type: :guarded_remote_syn,
          guard: guard,
          expr: expr,
          module: module,
          function: function,
          args: args,
        }

        {:->, _, [[{:when, _, [{name, meta, args}, guard]}], expr]}
        when is_atom(name)
        and is_list(meta)
        and is_list(args) ->
        %{
          type: :guarded_local_syn,
          guard: guard,
          expr: expr,
          function: name,
          args: args,
        }

        {:->, _, [[{:when, _, [{name, meta, context}, guard]}], expr]}
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

        {:->, _, [[{:when, _, [pat, guard]}], expr]} ->
        %{
          type: :guarded_clause,
          guard: guard,
          expr: expr,
          pat: pat,
        }

        {:->, _, [[[{:->, _, [[{{:., _, [module = {_, _, _}, function]}, _, args}], pat]}]], expr]} ->
        %{
          type: :remote_view,
          guard: [],
          expr: expr,
          pat: pat,
          module: module,
          function: function,
          args: args,
        }

        {:->, _, [[[{:->, _, [[{name, meta, args}], pat]}]], expr]}
        when is_atom(name)
        and is_list(meta)
        and is_list(args) ->
        %{
          type: :local_view,
          guard: [],
          expr: expr,
          pat: pat,
          function: name,
          args: args,
        }

        {:->, _, [[[{:->, _, [[{name, meta, context}], pat]}]], expr]}
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

        {:->, _, [[{{:., _, [module = {_, _, _}, function]}, _, args}], expr]} ->
        %{
          type: :remote_syn,
          guard: [],
          expr: expr,
          module: module,
          function: function,
          args: args,
        }

        {:->, _, [[{name, meta, args}], expr]}
        when is_atom(name)
        and is_list(meta)
        and is_list(args) ->
        %{
          type: :local_syn,
          guard: [],
          expr: expr,
          function: name,
          args: args,
        }

        {:->, _, [[{name, meta, context}], expr]}
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

        {:->, _, [[pat], expr]} ->
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
