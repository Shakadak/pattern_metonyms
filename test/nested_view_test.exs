defmodule NestedViewTest do
  use ExUnit.Case

  test "view two 2 pair" do
    defmodule TestVT2P1 do
      import PatternMetonyms

      pattern two <- 2
      pattern two_b <- (Function.identity() -> 2)

      def foo do
        view {2, 2} do
          {two(), two()} -> :ok
          {_x, _y} -> :ko
        end
      end
    end

    assert TestVT2P1.foo() == :ok
  end

  test "view two 2 pair (with id)" do
    defmodule TestVT2P2 do
      import PatternMetonyms

      pattern two <- (Function.identity -> 2)

      def foo do
        view {2, 2} do
          {two(), two()} -> :ok
          {_x, _y} -> :ko
        end
      end
    end

    assert TestVT2P2.foo() == :ok
  end
end
