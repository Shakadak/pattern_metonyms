defmodule PatternMetonyms.Access do
  @moduledoc false

  @doc false
  def compose_a(outer, inner) do
    fn op, data, next -> outer.(op, data, fn data -> inner.(op, data, next) end) end
  end

  @doc false
  def compose_as([_ | _] = as) do
    Enum.reduce(Enum.reverse(as), &compose_a/2)
  end

  @doc false
  def args, do: compose_a(Access.elem(2), Access.all())

  @doc false
  def name, do: Access.elem(0)

  @doc false
  # updated_view = [{:->, meta, [[fun], ast_pat_updated]}]
  def view_pattern, do: compose_as([Access.at(0), Access.elem(2), Access.at(1)])
end
