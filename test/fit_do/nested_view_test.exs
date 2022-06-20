defmodule FitDo.NestedViewTest do
  use ExUnit.Case, async: true

  test "view two 2 pair" do
    defmodule TestVT2P1 do
      import PatternMetonyms

      pattern(two <- 2)

      def foo do
        fit(do: {two(), two()} = {2, 2})
        :ok
      end
    end

    assert TestVT2P1.foo() == :ok
  end

  test "view two 2 pair (with id)" do
    defmodule TestVT2P2 do
      import PatternMetonyms

      pattern(two <- (Function.identity() -> 2))

      def foo do
        fit(do: {two(), two()} = {2, 2})
        :ok
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

        fit(do: {just(two())} = {x})
        :ok
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
        fit(do: {y, id(y)} = data)
        _ = y
      end
    end

    assert_raise MatchError, fn ->
      TestSEP1.foo()
    end
  end

  test "left nested fit fail at compilation" do
    assert_raise CompileError, fn ->
      defmodule LNFFAC do
        import PatternMetonyms

      fit(do: fit(do: 2 = 3) = 4)
      end
    end
  end

  test "left nested = fail at matching" do
    assert_raise MatchError, fn ->
      defmodule LNFFAC do
        import PatternMetonyms

      fit(do: 2 = 3 = 4)
      end
    end
  end
end
