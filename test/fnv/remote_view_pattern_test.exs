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
end
