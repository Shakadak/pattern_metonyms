defmodule Fnv.RemoteViewPatternTest do
  use ExUnit.Case, async: true

  test "view pattern with remote call, and argument" do
    import PatternMetonyms
    foo = fnv do (Map.new(fn x -> {x, x * 2} end) -> %{3 => x}) -> x + 1 end
    assert foo.(1..3) == 7
  end

  test "view pattern with remote call, and argument, and guard" do
    import PatternMetonyms
    bar = fnv do ((Map.new(fn x -> {x, x * 2} end) -> %{3 => x})) when x > 5 -> x + 1 end
    assert bar.(1..3) == 7
  end

  test "view pattern with remote call, and argument, and raising" do
    import PatternMetonyms
    baz = fnv do
      (Map.fetch!(:peach) -> x) -> x
      _ -> :ko
    end
    assert baz.(%{banana: :split}) == :ko
  end

  test "simple equality pattern" do
    assert_raise CaseClauseError, fn ->
      import PatternMetonyms
      f = fnv do
        {(Function.identity() -> x), (Function.identity -> x)} -> x
      end

      f.({1, 2})
    end
  end

  test "simpler equality pattern" do
    assert_raise CaseClauseError, fn ->
      import PatternMetonyms
      f = fnv do
        {(Function.identity() -> x), x} -> x
      end

      f.({1, 2})
    end
  end

  test "simpler equality pattern: swapped" do
    assert_raise CaseClauseError, fn ->
      import PatternMetonyms
      f = fnv do
        {x, (Function.identity() -> x)} -> x
      end

      f.({1, 2})
    end
  end

  test "3 params basic function" do
    import PatternMetonyms
    f = fnv do
      a, b, c -> a + b + c + 1
    end
    assert f.(1, 2, 3) == 7
  end
end
