defmodule Matchv.AnonymousFunctionViewTest do
  use ExUnit.Case, async: true

  test "view with anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]

    assert matchv?((fn [_, x, _] -> x end -> 2), xs)
  end

  test "guarded view with anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]

    assert matchv?((fn [_, x, _] -> x end -> n) when n == 2, xs)
  end

  test "view with stored anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]
    fun = fn [_, x, _] -> x end

    assert matchv?((fun.() -> 2), xs)
  end

  test "guarded view with stored anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]
    fun = fn [_, x, _] -> x end

    matchv?((fun.() -> n) when n == 2, xs)
  end

  test "view with stored anonymous function, multi params" do
    import PatternMetonyms

    xs = [1, 2, 3]
    fun = fn [_, x, _], y -> x + y end

    matchv?((fun.(3) -> 5), xs)
  end

  test "guarded view with stored anonymous function, multi params" do
    import PatternMetonyms

    xs = [1, 2, 3]
    fun = fn [_, x, _], y -> x * y end

    matchv?((fun.(2) -> n) when n != 2, xs)
  end

  test "view with anonymous function, wrong arg" do
    import PatternMetonyms

    xs = if 2 - :rand.uniform(2) < 3 do [1, 2, 3] end
    refute matchv?((fn {_, x, _} -> x end -> 2), xs)
  end

  test "view with anonymous function in pattern" do
    defmodule VAFP1 do
      import PatternMetonyms

      pattern with_fn(n) <- (fn [_, x, _] -> x end -> n)

      def foo do
        xs = [1, 2, 3]

        matchv?(with_fn(2), xs)
      end
    end

    assert VAFP1.foo
  end
end
