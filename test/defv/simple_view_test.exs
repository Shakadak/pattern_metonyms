defmodule Defv.SimpleViewTest do
  use ExUnit.Case, async: true

  defmodule DSVT do
    use PatternMetonyms

    pattern(just2(a, b) = {:Just, {a, b}})

    defv f(just2(x, y)), do: x + y
    defv f(:Nothing), do: 0

    def foo, do: f(just2(3, 2))

    def uncons([]), do: :Nothing
    def uncons([x | xs]), do: {:Just, {x, xs}}

    defv safeHead((uncons() -> {:Just, {x, _}})), do: {:Just, x}
    defv safeHead(_), do: :Nothing

    pattern(justHead(x) <- (uncons() -> {:Just, {x, _}}))

    defv safeHead2(justHead(x)), do: {:Just, x}
    defv safeHead2(_), do: :Nothing

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

    defv bar(polar(r, a)), do: %{radius: r, theta: a}

    def string_to_integer(s), do: String.to_integer(s)
    def integer_to_string(i), do: Integer.to_string(i)

    pattern (sti(x) <- (string_to_integer() -> x)) when sti(x) = integer_to_string(x)

    defv baz(sti(i)), do: sti(max(5, i))

    pattern (sti_b(x) <- (String.to_integer() -> x)) when sti_b(x) = Integer.to_string(x)

    defv qux(sti_b(i)), do: sti(max(5, i))

    defv a(xs) when 2 in xs, do: :ok
    defv a(_), do: :ko

    defv b(1), do: :ko
    defv b(2), do: :ok
  end

  test "view maybe pair" do
    assert DSVT.foo() == 5
  end

  test "view safe head" do
    assert DSVT.safeHead([]) == :Nothing
    assert DSVT.safeHead([1]) == {:Just, 1}
  end

  test "pattern safe head" do
    assert DSVT.safeHead2([]) == :Nothing
    assert DSVT.safeHead2([1]) == {:Just, 1}
  end

  test "explicit pattern coordinate" do
    # results from : https://keisan.casio.com/exec/system/1223526375
    # angle unit radian, 18digit
    assert DSVT.bar(DSVT.new_cartesian(3, 3)) == %{
      radius: 4.24264068711928515,
      theta: 0.78539816339744831
    }
  end

  test "explicit pattern string x integer" do
    assert DSVT.baz("65") == "65"
    assert DSVT.baz("-45") == "5"
  end

  test "explicit pattern string x integer remotely" do
    assert DSVT.qux("65") == "65"
    assert DSVT.qux("-45") == "5"
  end

  test "inverted `in` guard" do
    assert DSVT.a([1, 2, 3]) == :ok
    assert DSVT.a([1, 3]) == :ko
  end

  test "last clause match" do
    assert DSVT.b(2) == :ok
    assert DSVT.b(1) == :ko
  end
end
