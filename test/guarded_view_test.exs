defmodule GuardedViewTest do
  use ExUnit.Case

  test "guards with pattern" do
    defmodule TestGPL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      pattern(justHead(x) <- (uncons() -> {:Just, {x, _}}))

      def bigHead(xs) do
        view xs do
          justHead(x) when x > 1 -> {:Just, x}
          _ -> :Nothing
        end
      end
    end

    assert TestGPL1.bigHead([]) == :Nothing
    assert TestGPL1.bigHead([1]) == :Nothing
    assert TestGPL1.bigHead([2]) == {:Just, 2}
  end

  test "guards with view" do
    defmodule TestGVL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      def bigHead(xs) do
        view xs do
          (uncons() -> {:Just, {x, _}}) when x > 1 -> {:Just, x}
          _ -> :Nothing
        end
      end
    end

    assert TestGVL1.bigHead([]) == :Nothing
    assert TestGVL1.bigHead([1]) == :Nothing
    assert TestGVL1.bigHead([2]) == {:Just, 2}
  end

  test "guards with view pattern" do
    import PatternMetonyms

    result =
      view 2 - :rand.uniform(2) do
        (abs() -> x) when x > 3 -> :ok
        (abs() -> x) when x < 3 -> :ko
        x -> x
      end

    assert result == :ko
  end
end
