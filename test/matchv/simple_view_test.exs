defmodule Matchv.SimpleViewTest do
  use ExUnit.Case, async: true

  test "view maybe pair" do
    defmodule TestVM2 do
      import PatternMetonyms

      pattern(just2(a, b) = {:Just, {a, b}})

      def f(x) do
        matchv?(just2(3, 2), x)
      end

      def foo, do: f(just2(3, 2))
    end

    assert TestVM2.foo()
  end

  test "view safe head" do
    defmodule TestVL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      def safeHead(xs) do
        matchv?((uncons() -> {:Just, {1, _}}), xs)
      end
    end

    # "safe"
    refute TestVL1.safeHead([])
    assert TestVL1.safeHead([1])
  end

  test "pattern safe head" do
    defmodule TestPL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      pattern(justHead(x) <- (uncons() -> {:Just, {x, _}}))

      def safeHead(xs) do
        matchv?(justHead(1), xs)
      end
    end

    # "safeHead"
    refute TestPL1.safeHead([])
    assert TestPL1.safeHead([1])
  end

  test "explicit pattern coordinate" do
    defmodule TestEPC1 do
      import PatternMetonyms

      def new_cartesian(x, y), do: %{x: x, y: y}

      def new_polar(r, t), do: {r, t}

      def polar_to_cartesian({r, t}) do
        x = r * :math.cos(t)
        y = r * :math.sin(t)
        new_cartesian(x, y)
      end

      def cartesian_to_polar(%{x: x, y: y}) do
        r = :math.sqrt(x * x + y * y)
        t = :math.atan(y / x)
        new_polar(r, t)
      end

      pattern(
        (polar(r, a) <- (cartesian_to_polar() -> {r, a}))
        when polar(r, a) = polar_to_cartesian(r, a)
      )

      def foo(point) do
        matchv?(polar(4.24264068711928515, 0.78539816339744831), point)
      end
    end

    # results from : https://keisan.casio.com/exec/system/1223526375
    # angle unit radian, 18digit
    assert TestEPC1.foo(TestEPC1.new_cartesian(3, 3))
  end

  test "explicit pattern string x integer" do
    defmodule TestEPSI1 do
      import PatternMetonyms

      def string_to_integer(s), do: String.to_integer(s)
      def integer_to_string(i), do: Integer.to_string(i)

      pattern((sti(x) <- (string_to_integer() -> x)) when sti(x) = integer_to_string(x))

      def foo(s) do
        matchv?(sti(65), s)
      end
    end

    assert TestEPSI1.foo("65")
  end

  test "explicit pattern string x integer remotely" do
    defmodule TestEPSI2 do
      import PatternMetonyms

      def string_to_integer(s), do: String.to_integer(s)
      def integer_to_string(i), do: Integer.to_string(i)

      pattern((sti(x) <- (String.to_integer() -> x)) when sti(x) = Integer.to_string(x))

      def foo(s) do
        matchv?(sti(-45), s)
      end
    end

    assert TestEPSI2.foo("-45")
  end

  test "inverted `in` guard" do
    import PatternMetonyms

    assert matchv?(xs when 2 in xs, [1, 2, 3])
  end
end
