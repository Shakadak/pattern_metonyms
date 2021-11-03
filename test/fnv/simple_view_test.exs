defmodule Fnv.SimpleViewTest do
  use ExUnit.Case, async: true

  defmodule DSVT do
    use PatternMetonyms

    pattern(just2(a, b) = {:Just, {a, b}})

    def f do
      fnv do
        (just2(x, y)) -> x + y
        (:Nothing) -> 0
      end
    end

    def foo, do: f().(just2(3, 2))

    def uncons([]), do: :Nothing
    def uncons([x | xs]), do: {:Just, {x, xs}}

    def safeHead do
      fnv do
        ((uncons() -> {:Just, {x, _}})) -> {:Just, x}
        (_) -> :Nothing
      end
    end

    pattern(justHead(x) <- (uncons() -> {:Just, {x, _}}))

    def safeHead2 do
      fnv do
        (justHead(x)) -> {:Just, x}
        (_) -> :Nothing
      end
    end

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

    pattern (polar(r, a) <- (cartesian_to_polar() -> {r, a}))
      when polar(r, a) = polar_to_cartesian(r, a)

    def bar do
      fnv do (polar(r, a)) -> %{radius: r, theta: a} end
    end

    def string_to_integer(s), do: String.to_integer(s)
    def integer_to_string(i), do: Integer.to_string(i)

    pattern (sti(x) <- (string_to_integer() -> x)) when sti(x) = integer_to_string(x)

    def baz do
      fnv do (sti(i)) -> sti(max(5, i)) end
    end

    pattern (sti_b(x) <- (String.to_integer() -> x)) when sti_b(x) = Integer.to_string(x)

    def qux do
      fnv do (sti_b(i)) -> sti(max(5, i)) end
    end

    def a do
      fnv do
        (xs) when 2 in xs -> :ok
        (_) -> :ko
      end
    end

    def b do
      fnv do
        (1) -> :ko
        (2) -> :ok
      end
    end
  end

  test "view maybe pair" do
    assert DSVT.foo() == 5
  end

  test "view safe head" do
    assert DSVT.safeHead.([]) == :Nothing
    assert DSVT.safeHead.([1]) == {:Just, 1}
  end

  test "pattern safe head" do
    assert DSVT.safeHead2.([]) == :Nothing
    assert DSVT.safeHead2.([1]) == {:Just, 1}
  end

  test "explicit pattern coordinate" do
    # results from : https://keisan.casio.com/exec/system/1223526375
    # angle unit radian, 18digit
    assert DSVT.bar.(DSVT.new_cartesian(3, 3)) == %{
      radius: 4.24264068711928515,
      theta: 0.78539816339744831
    }
  end

  test "explicit pattern string x integer" do
    assert DSVT.baz.("65") == "65"
    assert DSVT.baz.("-45") == "5"
  end

  test "explicit pattern string x integer remotely" do
    assert DSVT.qux.("65") == "65"
    assert DSVT.qux.("-45") == "5"
  end

  test "inverted `in` guard" do
    assert DSVT.a.([1, 2, 3]) == :ok
    assert DSVT.a.([1, 3]) == :ko
  end

  test "last clause match" do
    assert DSVT.b.(2) == :ok
    assert DSVT.b.(1) == :ko
  end
end
