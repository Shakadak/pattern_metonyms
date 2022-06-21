defmodule Matchv.NestedViewTest do
  use ExUnit.Case, async: true

  test "view two 2 pair" do
    defmodule TestVT2P1 do
      import PatternMetonyms

      pattern(two <- 2)

      def foo do
        matchv?({two(), two()}, {2, 2})
      end
    end

    assert TestVT2P1.foo()
  end

  test "view two 2 pair (with id)" do
    defmodule TestVT2P2 do
      import PatternMetonyms

      pattern(two <- (Function.identity() -> 2))

      def foo do
        matchv?({two(), two()}, {2, 2})
      end
    end

    assert TestVT2P2.foo()
  end

  test "view just two (with id)" do
    defmodule TestVJT1 do
      import PatternMetonyms

      pattern(two <- (Function.identity() -> 2))

      pattern(just(x) <- (Function.identity() -> {:Just, x}))

      def foo do
        x = {:Just, 2}

        matchv?({just(two())}, {x})
      end
    end

    assert TestVJT1.foo()
  end

  test "view simple equality pattern" do
    defmodule TestSEP1 do
      import PatternMetonyms

      pattern id(x) = x

      def foo do
        data = (fn _ -> {1, 2} end).(2 - :rand.uniform(2))
        matchv?({y, id(y)}, data)
      end
    end

    refute TestSEP1.foo()
  end

  test "left nested matchv? fail at compilation" do
    assert_raise CompileError, fn ->
      defmodule LNFFAC do
        import PatternMetonyms

        matchv?(matchv?(2, 3), 4)
      end
    end
  end
end
