defmodule Fnv.NestedViewTest do
  use ExUnit.Case, async: true

  defmodule DNVT do
    use PatternMetonyms

    pattern two <- 2

    def foo do
      fnv do
        {two(), two()} -> :ok
        {_x, _y} -> :ko
      end
    end

    pattern two_i <- (Function.identity() -> 2)

    def bar do
      fnv do
        {two(), two()} -> :ok
        {_x, _y} -> :ko
      end
    end

    pattern(just(x) <- (Function.identity() -> {:Just, x}))

    def baz do
      fnv do
        {just(two_i())} -> :ok
        _ -> :ko
      end
    end

    pattern(just2(a, b) = {:Just, {a, b}})

    def uncons([]), do: :Nothing
    def uncons([x | xs]), do: {:Just, {x, xs}}

    def safeHead do
      fnv do
        (uncons() -> just2(x, _)) -> {:Just, x}
        _ -> :Nothing
      end
    end

    def safeHead2 do
      fnv do
        (fn x -> uncons(x) end -> just2(x, _)) -> {:Just, x}
        _ -> :Nothing
      end
    end

    def safeHead3 do
      fnv do
        (fn x -> uncons(x) end -> (fn just2(y, _) -> y end -> z)) -> {:Just, z}
        _ -> :Nothing
      end
    end
  end

  test "view two 2 pair" do
    assert DNVT.foo.({2, 2}) == :ok
  end

  test "view two 2 pair (with id)" do
    assert DNVT.bar.({2, 2}) == :ok
  end

  test "view just two (with id)" do
    x = {:Just, 2}

    assert DNVT.baz.({x}) == :ok
  end

  test "view safe head" do
    assert DNVT.safeHead.([]) == :Nothing
    assert DNVT.safeHead.([1]) == {:Just, 1}
  end

  test "view safe head 2" do
    assert DNVT.safeHead2.([]) == :Nothing
    assert DNVT.safeHead2.([1]) == {:Just, 1}
  end

  test "view safe head 3" do
    assert DNVT.safeHead3.([]) == :Nothing
    assert DNVT.safeHead3.([1]) == {:Just, 1}
  end
end
