defmodule Matchv.GuardedViewTest do
  use ExUnit.Case, async: true

  test "guards with pattern" do
    defmodule TestGPL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      pattern(justHead(x) <- (uncons() -> {:Just, {x, _}}))

      def bigHead(xs) do
        matchv?(justHead(x) when x > 1, xs)
      end
    end

    refute TestGPL1.bigHead([])
    refute TestGPL1.bigHead([1])
    assert TestGPL1.bigHead([2])
  end

  test "guards with view" do
    defmodule TestGVL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      def bigHead(xs) do
        matchv?((uncons() -> {:Just, {x, _}}) when x > 1, xs)
      end
    end

    refute TestGVL1.bigHead([])
    refute TestGVL1.bigHead([1])
    assert TestGVL1.bigHead([2])
  end

  test "guards with view pattern" do
    import PatternMetonyms

    refute matchv?((abs() -> x) when x > 3, 2 - :rand.uniform(2))
  end
end
