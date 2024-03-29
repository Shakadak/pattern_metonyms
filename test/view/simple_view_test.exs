defmodule SimpleViewTest do
  use ExUnit.Case, async: true

  test "view maybe pair" do
    defmodule TestVM2 do
      import PatternMetonyms

      pattern(just2(a, b) = {:Just, {a, b}})

      def f(x) do
        view x do
          just2(x, y) -> x + y
          :Nothing -> 0
        end
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
        view xs do
          (uncons() -> {:Just, {x, _}}) -> {:Just, x}
          _ -> :Nothing
        end
      end
    end

    assert TestVL1.safeHead([]) == :Nothing
    assert TestVL1.safeHead([1]) == {:Just, 1}
  end

  test "pattern safe head" do
    defmodule TestPL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      pattern(justHead(x) <- (uncons() -> {:Just, {x, _}}))

      def safeHead(xs) do
        view xs do
          justHead(x) -> {:Just, x}
          _ -> :Nothing
        end
      end
    end

    assert TestPL1.safeHead([]) == :Nothing
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
        view point do
          polar(r, a) -> %{radius: r, theta: a}
        end
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
        view s do
          sti(i) -> sti(max(5, i))
        end
      end
    end

    assert TestEPSI1.foo("65") == "65"
    assert TestEPSI1.foo("-45") == "5"
  end

  test "explicit pattern string x integer remotely" do
    defmodule TestEPSI2 do
      import PatternMetonyms

      pattern((sti(x) <- (String.to_integer() -> x)) when sti(x) = Integer.to_string(x))

      def foo(s) do
        view s do
          sti(i) -> sti(max(5, i))
        end
      end
    end

    assert TestEPSI2.foo("65") == "65"
    assert TestEPSI2.foo("-45") == "5"
  end

  test "inverted `in` guard" do
    import PatternMetonyms

    result =
      view [1, 2, 3] do
        xs when 2 in xs -> :ok
        _ -> :ko
      end

    assert result == :ok
  end

  test "last clause match" do
    import PatternMetonyms

    result =
      view 2 do
        1 -> :ko
        2 -> :ok
      end

    assert result == :ok
  end
end
