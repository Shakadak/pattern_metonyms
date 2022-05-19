defmodule Fit.GuardedViewTest do
  use ExUnit.Case, async: true

  test "guards with pattern" do
    defmodule TestGPL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      pattern(justHead(x) <- (uncons() -> {:Just, {x, _}}))

      def bigHead(xs) do
        fit(justHead(x) when x > 1, xs)
        {:Just, x}
      end
    end

    assert_raise MatchError, fn -> TestGPL1.bigHead([]) end
    assert_raise MatchError, fn -> TestGPL1.bigHead([1]) end
    assert TestGPL1.bigHead([2]) == {:Just, 2}
  end

  test "guards with view" do
    defmodule TestGVL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      def bigHead(xs) do
        fit((uncons() -> {:Just, {x, _}}) when x > 1, xs)
        {:Just, x}
      end
    end

    assert_raise MatchError, fn -> TestGVL1.bigHead([]) end
    assert_raise MatchError, fn -> TestGVL1.bigHead([1]) end
    assert TestGVL1.bigHead([2]) == {:Just, 2}
  end

  test "guards with view pattern" do
    import PatternMetonyms

    assert_raise MatchError, fn ->
      fit((abs() -> x) when x > 3, 2 - :rand.uniform(2))
      _ = x
    end
  end
end
