defmodule CaseCompatibleTest do
  use ExUnit.Case

  test "maybe pair" do
    defmodule TestM2 do
      import PatternMetonyms

      pattern just2(a, b) = {:Just, {a, b}}

      def f(just2(x, y)), do: x + y
      def foo, do: f(just2(3, 2))
    end

    assert TestM2.foo == 5
  end

  test "maybe triplet" do
    defmodule TestM3 do
      import PatternMetonyms

      pattern just3(a, b, c) =
        {:Just, {a, b, c}}

      def g(just3(x, y, _)), do: x + y
      def bar, do: g(just3(3, 2, 1))
    end

    assert TestM3.bar == 5
  end

  test "maybe singleton" do
    defmodule TestM1 do
      import PatternMetonyms

      pattern just1(a) = {:Just, a}

      def h(just1(x)), do: -x
      def baz, do: h(just1(3))
    end

    assert TestM1.baz == -3
  end

  test "list head" do
    defmodule TestL1 do
      import PatternMetonyms

      pattern head(x) <- [x | _]

      def f(head(x)), do: x
    end

    assert TestL1.f([1, 2, 3]) == 1
  end

  test "raise list head" do
    assert_raise CompileError, fn ->
      defmodule TestL2 do
        import PatternMetonyms

        pattern head(x) <- [x | _]

        def g, do: head(4)
      end
    end
  end

  test "case with remote pattern" do
    defmodule TestRPL1 do
      import PatternMetonyms

      pattern head(x) <- [x | _]
    end

    defmodule TestRPL1.Act do
      def foo(xs) do
        require TestRPL1
        case xs do
          TestRPL1.head(n) -> {:ok, n}
          _ -> :error
        end
      end
    end

    assert TestRPL1.Act.foo([1, 2, 3]) == {:ok, 1}
  end
end
