defmodule Fit.SimpleViewTest do
  use ExUnit.Case, async: true

  test "view maybe pair" do
    defmodule TestVM2 do
      import PatternMetonyms

      pattern(just2(a, b) = {:Just, {a, b}})

      def f(x) do
        fit(just2(x, y), x)
        x + y
      end

      def foo, do: f(just2(3, 2))
    end

    assert TestVM2.foo() == 5
  end

  test "view safe head" do
    defmodule TestVL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      def safeHead(xs) do
        fit((uncons() -> {:Just, {x, _}}), xs)
        {:Just, x}
      end
    end

    # "safe"
    assert_raise MatchError, fn -> TestVL1.safeHead([]) end
    assert TestVL1.safeHead([1]) == {:Just, 1}
  end

  test "pattern safe head" do
    defmodule TestPL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      pattern(justHead(x) <- (uncons() -> {:Just, {x, _}}))

      def safeHead(xs) do
        fit(justHead(x), xs)
        {:Just, x}
      end
    end

    # "safeHead"
    assert_raise MatchError, fn -> TestPL1.safeHead([]) end
    assert TestPL1.safeHead([1]) == {:Just, 1}
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
        fit(polar(r, a), point)
        %{radius: r, theta: a}
      end
    end

    # results from : https://keisan.casio.com/exec/system/1223526375
    # angle unit radian, 18digit
    assert TestEPC1.foo(TestEPC1.new_cartesian(3, 3)) == %{
             radius: 4.24264068711928515,
             theta: 0.78539816339744831
           }
  end

  test "explicit pattern string x integer" do
    defmodule TestEPSI1 do
      import PatternMetonyms

      def string_to_integer(s), do: String.to_integer(s)
      def integer_to_string(i), do: Integer.to_string(i)

      pattern((sti(x) <- (string_to_integer() -> x)) when sti(x) = integer_to_string(x))

      def foo(s) do
        fit(sti(i), s)
        sti(max(5, i))
      end
    end

    assert TestEPSI1.foo("65") == "65"
    assert TestEPSI1.foo("-45") == "5"
  end

  test "explicit pattern string x integer remotely" do
    defmodule TestEPSI2 do
      import PatternMetonyms

      def string_to_integer(s), do: String.to_integer(s)
      def integer_to_string(i), do: Integer.to_string(i)

      pattern((sti(x) <- (String.to_integer() -> x)) when sti(x) = Integer.to_string(x))

      def foo(s) do
        fit(sti(i), s)
        sti(max(5, i))
      end
    end

    assert TestEPSI2.foo("65") == "65"
    assert TestEPSI2.foo("-45") == "5"
  end

  test "inverted `in` guard" do
    import PatternMetonyms

    fit(xs when 2 in xs, [1, 2, 3])
    _ = xs
    result = :ok

    assert result == :ok
  end
end
