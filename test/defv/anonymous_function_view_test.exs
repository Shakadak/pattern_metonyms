defmodule Defv.AnonymousFunctionViewTest do
  use ExUnit.Case, async: true

  defmodule DAFVT do
    use PatternMetonyms

    defv a((fn [_, x, _] -> x end -> n)), do: n

    defv b((fn [_, x, _] -> x end -> n)) when n == 2, do: n

    defv c((fn {_, x, _} -> x end -> n)), do: n
    defv c(_), do: :ko

    pattern with_fn(n) <- (fn [_, x, _] -> x end -> n)

    defv d(with_fn(y)), do: y
  end

  test "view with anonymous function" do
    xs = [1, 2, 3]

    assert DAFVT.a(xs) == 2
  end

  test "guarded view with anonymous function" do
    xs = [1, 2, 3]

    assert DAFVT.b(xs) == 2
  end

  test "view with anonymous function, wrong arg" do
    assert DAFVT.c([1, 2, 3]) == :ko
  end

  test "view with anonymous function in pattern" do
    assert DAFVT.d([1, 2, 3]) == 2
  end
end
