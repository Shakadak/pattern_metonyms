defmodule Defv.RemoteViewPatternTest do
  use ExUnit.Case, async: true

  defmodule DRVT do
    use PatternMetonyms

    defv foo((Map.new(fn x -> {x, x * 2} end) -> %{3 => x})), do: x + 1

    defv bar((Map.new(fn x -> {x, x * 2} end) -> %{3 => x})) when x > 5, do: x + 1

    defv baz((Map.fetch!(:peach) -> x)), do: x
    defv baz(_), do: :ko

    defv plain3(a, b, c), do: a + b + c + 1

    defv eq1((Function.identity() -> x), (Function.identity() -> x)), do: x
    defv eq2((Function.identity() -> x), x), do: x
    defv eq3(x, (Function.identity() -> x)), do: x
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

  test "simple equality pattern" do
    assert_raise CaseClauseError, fn ->
      DRVT.eq1(1, 2)
    end
  end

  test "simpler equality pattern" do
    assert_raise CaseClauseError, fn ->
      DRVT.eq2(1, 2)
    end
  end

  test "simpler equality pattern: swapped" do
    assert_raise CaseClauseError, fn ->
      DRVT.eq3(1, 2)
    end
  end

  test "3 params basic function" do
    assert DRVT.plain3(1, 2, 3) == 7
  end
end
