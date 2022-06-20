defmodule FitDo.RemoteViewPatternTest do
  use ExUnit.Case, async: true

  test "view pattern with remote call, and argument" do
    import PatternMetonyms

    
    fit(do: (Map.new(fn x -> {x, x * 2} end) -> %{3 => x}) = 1..3)
    result = x + 1

    assert result == 7
  end

  test "view pattern with remote call, and argument, and guard" do
    import PatternMetonyms

    
    fit(do: (Map.new(fn x -> {x, x * 2} end) -> %{3 => x}) when x > 5 = 1..3)
    result = x + 1

    assert result == 7
  end

  test "view pattern with remote call, and argument, and raising" do
    import PatternMetonyms

    assert_raise MatchError, fn ->
      data = if 2 - :rand.uniform(2) < 3 do %{banana: :split} end
      fit(do: (Map.fetch!(:peach) -> x) = data)
      _ = x
    end
  end

  test "simple equality pattern" do
    assert_raise MatchError, fn ->
      import PatternMetonyms

      fit(do: {(Function.identity() -> x), (Function.identity -> x)} = {1, 2})
      _ = x
    end
  end

  test "simpler equality pattern" do
    assert_raise MatchError, fn ->
      import PatternMetonyms

      fit(do: {x, (Function.identity() -> x)} = {1, 2})
      _ = x
    end
  end

  test "simpler equality pattern: swapped" do
    assert_raise MatchError, fn ->
      import PatternMetonyms

      fit(do: {(Function.identity() -> x), x} = {1, 2})
      _ = x
    end
  end
end
