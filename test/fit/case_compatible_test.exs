defmodule Fit.CaseCompatibleTest do
  use ExUnit.Case, async: true

  test "maybe pair" do
    defmodule TestM2 do
      import PatternMetonyms

      pattern(just2(a, b) = {:Just, {a, b}})

      def f(z) do
        fit(just2(x, y), z)
        x + y
      end
      def foo, do: f(just2(3, 2))
    end

    assert TestM2.foo() == 5
  end

  test "maybe triplet" do
    defmodule TestM3 do
      import PatternMetonyms

      pattern(just3(a, b, c) = {:Just, {a, b, c}})

      def g(z) do
        fit(just3(x, y, _), z)
        x + y
      end
      def bar, do: g(just3(3, 2, 1))
    end

    assert TestM3.bar() == 5
  end

  test "maybe singleton" do
    defmodule TestM1 do
      import PatternMetonyms

      pattern(just1(a) = {:Just, a})

      def h(z) do
        fit(just1(x), z)
        -x
      end
      def baz, do: h(just1(3))
    end

    assert TestM1.baz() == -3
  end

  test "list head" do
    defmodule TestL1 do
      import PatternMetonyms

      pattern(head(x) <- [x | _])

      def f(z), do: (fit(head(x), z) ; x)
    end

    assert TestL1.f([1, 2, 3]) == 1
  end

  test "case with remote pattern" do
    defmodule TestRPL1 do
      import PatternMetonyms

      pattern(head(x) <- [x | _])
    end

    defmodule TestRPL1.Act do
      def foo(xs) do
        import PatternMetonyms
        require TestRPL1

        fit(TestRPL1.head(n), xs)
        {:ok, n}
      end
    end

    assert TestRPL1.Act.foo([1, 2, 3]) == {:ok, 1}
  end

  test "case isomorphism" do
    import PatternMetonyms

    xs = [1, 2, 3]

    fit([result | _xs], xs)

    assert result == 1
  end
end
