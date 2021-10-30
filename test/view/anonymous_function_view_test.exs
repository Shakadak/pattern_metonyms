defmodule AnonymousFunctionViewTest do
  use ExUnit.Case, async: true

  test "view with anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]

    result =
      view xs do
        (fn [_, x, _] -> x end -> n) -> n
      end

    assert result == 2
  end

  test "guarded view with anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]

    result =
      view xs do
        (fn [_, x, _] -> x end -> n) when n == 2 -> n
      end

    assert result == 2
  end

  test "view with stored anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]
    fun = fn [_, x, _] -> x end

    result =
      view xs do
        (fun.() -> n) -> n
      end

    assert result == 2
  end

  test "guarded view with stored anonymous function" do
    import PatternMetonyms

    xs = [1, 2, 3]
    fun = fn [_, x, _] -> x end

    result =
      view xs do
        (fun.() -> n) when n == 2 -> n
      end

    assert result == 2
  end

  test "view with stored anonymous function, multi params" do
    import PatternMetonyms

    xs = [1, 2, 3]
    fun = fn [_, x, _], y -> x + y end

    result =
      view xs do
        (fun.(3) -> n) -> n
      end

    assert result == 5
  end

  test "guarded view with stored anonymous function, multi params" do
    import PatternMetonyms

    xs = [1, 2, 3]
    fun = fn [_, x, _], y -> x * y end

    result =
      view xs do
        (fun.(2) -> n) when n != 2 -> n
      end

    assert result == 4
  end

  test "view with anonymous function, wrong arg" do
    import PatternMetonyms

    result =
      view [1, 2, 3] do
        (fn {_, x, _} -> x end -> n) -> n
        _ -> :ko
      end

    assert result == :ko
  end

  test "view with anonymous function in pattern" do
    defmodule VAFP1 do
      import PatternMetonyms

      pattern with_fn(n) <- (fn [_, x, _] -> x end -> n)

      def foo do
        xs = [1, 2, 3]

        view xs do
          with_fn(n) -> n
        end
      end
    end

    assert VAFP1.foo == 2
  end
end
