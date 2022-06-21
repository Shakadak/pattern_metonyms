defmodule Matchv.CaseCompatibleTest do
  use ExUnit.Case, async: true

  test "maybe pair" do
    defmodule TestM2 do
      import PatternMetonyms

      pattern(just2(a, b) = {:Just, {a, b}})

      def f(z) do
        matchv?(just2(3, 2), z)
      end
      def foo, do: f(just2(3, 2))
    end

    assert TestM2.foo()
  end

  test "maybe triplet" do
    defmodule TestM3 do
      import PatternMetonyms

      pattern(just3(a, b, c) = {:Just, {a, b, c}})

      def g(z) do
        matchv?(just3(3, 2, _), z)
      end
      def bar, do: g(just3(3, 2, 1))
    end

    assert TestM3.bar()
  end

  test "maybe singleton" do
    defmodule TestM1 do
      import PatternMetonyms

      pattern(just1(a) = {:Just, a})

      def h(z) do
        matchv?(just1(3), z)
      end
      def baz, do: h(just1(3))
    end

    assert TestM1.baz()
  end

  test "list head" do
    defmodule TestL1 do
      import PatternMetonyms

      pattern(head(x) <- [x | _])

      def f(z), do: matchv?(head(1), z)
    end

    assert TestL1.f([1, 2, 3])
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

        matchv?(TestRPL1.head(1), xs)
      end
    end

    assert TestRPL1.Act.foo([1, 2, 3])
  end

  test "case isomorphism" do
    import PatternMetonyms

    xs = [1, 2, 3]

    assert matchv?([1 | _xs], xs)
  end
end
