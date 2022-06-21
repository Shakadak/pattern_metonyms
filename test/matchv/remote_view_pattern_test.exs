defmodule Matchv.RemoteViewPatternTest do
  use ExUnit.Case, async: true

  test "view pattern with remote call, and argument" do
    import PatternMetonyms

    assert matchv?((Map.new(fn x -> {x, x * 2} end) -> %{3 => _x}), 1..3)
  end

  test "view pattern with remote call, and argument, and guard" do
    import PatternMetonyms

    
    assert matchv?((Map.new(fn x -> {x, x * 2} end) -> %{3 => x}) when x > 5, 1..3)
  end

  test "view pattern with remote call, and argument, and raising" do
    import PatternMetonyms

    data = if 2 - :rand.uniform(2) < 3 do %{banana: :split} end
    refute matchv?((Map.fetch!(:peach) -> _x), data)
  end

  test "simple equality pattern" do
    import PatternMetonyms

    refute matchv?({(Function.identity() -> x), (Function.identity -> x)}, {1, 2})
  end

  test "simpler equality pattern" do
    import PatternMetonyms

    refute matchv?({x, (Function.identity() -> x)}, {1, 2})
  end

  test "simpler equality pattern: swapped" do
    import PatternMetonyms

    refute matchv?({(Function.identity() -> x), x}, {1, 2})
  end
end
