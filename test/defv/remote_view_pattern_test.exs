defmodule Defv.RemoteViewPatternTest do
  use ExUnit.Case, async: true

  defmodule DRVT do
    use PatternMetonyms

    defv foo((Map.new(fn x -> {x, x * 2} end) -> %{3 => x})), do: x + 1

    defv bar((Map.new(fn x -> {x, x * 2} end) -> %{3 => x})) when x > 5, do: x + 1

    defv baz((Map.fetch!(:peach) -> x)), do: x
    defv baz(_), do: :ko
  end

  test "view pattern with remote call, and argument" do
    assert DRVT.foo(1..3) == 7
  end

  test "view pattern with remote call, and argument, and guard" do
    assert DRVT.bar(1..3) == 7
  end

  test "view pattern with remote call, and argument, and raising" do
    assert DRVT.baz(%{banana: :split}) == :ko
  end
end
