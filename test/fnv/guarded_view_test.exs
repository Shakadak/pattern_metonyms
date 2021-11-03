defmodule Fnv.GuardedViewTest do
  use ExUnit.Case, async: true

  defmodule DGVT do
    import PatternMetonyms

    def uncons([]), do: :Nothing
    def uncons([x | xs]), do: {:Just, {x, xs}}

    pattern(justHead(x) <- (uncons() -> {:Just, {x, _}}))

    def bigHead do
      fnv do
        (justHead(x)) when x > 1 -> {:Just, x}
        (_) -> :Nothing
      end
    end

    def bigHead2 do
      fnv do
        (uncons() -> {:Just, {x, _}}) when x > 1 -> {:Just, x}
        _ -> :Nothing
      end
    end

    def c do
      fnv do
        (abs() -> x) when x > 3 -> :ok
        (abs() -> x) when x < 3 -> :ko
        x -> x
      end
    end
  end

  test "guards with pattern" do
    assert DGVT.bigHead.([]) == :Nothing
    assert DGVT.bigHead.([1]) == :Nothing
    assert DGVT.bigHead.([2]) == {:Just, 2}
  end

  test "guards with view" do
    assert DGVT.bigHead2.([]) == :Nothing
    assert DGVT.bigHead2.([1]) == :Nothing
    assert DGVT.bigHead2.([2]) == {:Just, 2}
  end

  test "guards with view pattern" do
    result = DGVT.c.(2 - :rand.uniform(2))
    assert result == :ko
  end
end
