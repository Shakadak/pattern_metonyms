defmodule NestedViewTest do
  use ExUnit.Case, async: true

  test "view two 2 pair" do
    defmodule TestVT2P1 do
      import PatternMetonyms

      pattern(two <- 2)

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

      pattern(two <- (Function.identity() -> 2))

      def foo do
        view {2, 2} do
          {two(), two()} -> :ok
          {_x, _y} -> :ko
        end
      end
    end

    assert TestVT2P2.foo() == :ok
  end

  test "view just two (with id)" do
    defmodule TestVJT1 do
      import PatternMetonyms

      pattern(two <- (Function.identity() -> 2))

      pattern(just(x) <- (Function.identity() -> {:Just, x}))

      def foo do
        x = {:Just, 2}

        view {x} do
          {just(two())} -> :ok
          _ -> :ko
        end
      end
    end

    assert TestVJT1.foo() == :ok
  end

  test "view simple equality pattern" do
    defmodule TestSEP1 do
      import PatternMetonyms

      pattern id(x) = x

      def foo do
        data = (fn _ -> {1, 2} end).(2 - :rand.uniform(2))
        view data do
          {y, id(y)} -> y
        end
      end
    end

    assert_raise CaseClauseError, fn ->
      TestSEP1.foo()
    end
  end
end
