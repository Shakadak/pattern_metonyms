defmodule Fnv.AnonymousFunctionViewTest do
  use ExUnit.Case, async: true

  defmodule FAFVT do
    import PatternMetonyms

    pattern with_fn(n) <- (fn [_, x, _] -> x end -> n)

    def d do
      fnv do with_fn(y) -> y end
    end
  end

  test "view with anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]

    f = fnv do (fn [_, x, _] -> x end -> n) -> n end

    assert f.(xs) == 2
  end

  test "guarded view with anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]

    f = fnv do (fn [_, x, _] -> x end -> n) when n == 2 -> n end

    assert f.(xs) == 2
  end

  test "view with anonymous function, wrong arg" do
    import PatternMetonyms
    f = fnv do
      (fn {_, x, _} -> x end -> n) -> n
      _ -> :ko
    end
    assert f.([1, 2, 3]) == :ko
  end

  test "view with anonymous function in pattern" do
    assert FAFVT.d().([1, 2, 3]) == 2
  end
end
