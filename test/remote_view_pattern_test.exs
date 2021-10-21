defmodule RemoteViewPatternTest do
  use ExUnit.Case

  test "view pattern with remote call, and argument" do
    import PatternMetonyms

    result =
      view 1..3 do
        (Map.new(fn x -> {x, x * 2} end) -> %{3 => x}) -> x + 1
      end

    assert result == 7
  end

  test "view pattern with remote call, and argument, and guard" do
    import PatternMetonyms

    result =
      view 1..3 do
        (Map.new(fn x -> {x, x * 2} end) -> %{3 => x}) when x > 5 -> x + 1
      end

    assert result == 7
  end

  test "view pattern with remote call, and argument, and raising" do
    import PatternMetonyms

    result =
      view %{banana: :split} do
        (Map.fetch!(:peach) -> x) -> x
        _ -> :ko
      end

    assert result == :ko
  end
end
