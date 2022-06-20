defmodule FitDo.AnonymousFunctionViewTest do
  use ExUnit.Case, async: true

  test "view with anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]

    fit do (fn [_, x, _] -> x end -> result) = xs end

    assert result == 2
  end

  test "guarded view with anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]

    fit do (fn [_, x, _] -> x end -> n) when n == 2 = xs end

    assert n == 2
  end

  test "view with stored anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]
    fun = fn [_, x, _] -> x end

    fit(do: (fun.() -> result) = xs)

    assert result == 2
  end

  test "guarded view with stored anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]
    fun = fn [_, x, _] -> x end

    fit(do: (fun.() -> n) when n == 2 = xs)

    assert n == 2
  end

  test "view with stored anonymous function, multi params" do
    import PatternMetonyms

    xs = [1, 2, 3]
    fun = fn [_, x, _], y -> x + y end

    fit(do: (fun.(3) -> n) = xs)

    assert n == 5
  end

  test "guarded view with stored anonymous function, multi params" do
    import PatternMetonyms

    xs = [1, 2, 3]
    fun = fn [_, x, _], y -> x * y end

    fit(do: (fun.(2) -> n) when n != 2 = xs)

    assert n == 4
  end

  test "view with anonymous function, wrong arg" do
    assert_raise MatchError, fn ->
      import PatternMetonyms

      xs = if 2 - :rand.uniform(2) < 3 do [1, 2, 3] end
      fit(do: (fn {_, x, _} -> x end -> n) = xs)
      n
    end
  end

  test "view with anonymous function in pattern" do
    defmodule VAFP1 do
      import PatternMetonyms

      pattern with_fn(n) <- (fn [_, x, _] -> x end -> n)

      def foo do
        xs = [1, 2, 3]

        fit do
          with_fn(n) = xs
        end
        n
      end
    end

    assert VAFP1.foo == 2
  end
end
