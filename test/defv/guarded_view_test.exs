defmodule Defv.GuardedViewTest do
  use ExUnit.Case, async: true

  defmodule DGVT do
    use PatternMetonyms

    def uncons([]), do: :Nothing
    def uncons([x | xs]), do: {:Just, {x, xs}}

    pattern(justHead(x) <- (uncons() -> {:Just, {x, _}}))

    defv bigHead(justHead(x)) when x > 1, do: {:Just, x}
    defv bigHead(_), do: :Nothing

    defv bigHead2((uncons() -> {:Just, {x, _}})) when x > 1, do: {:Just, x}
    defv bigHead2(_), do: :Nothing

    defv c((abs() -> x)) when x > 3, do: :ok
    defv c((abs() -> x)) when x < 3, do: :ko
    defv c(x), do: x
  end

  test "guards with pattern" do
    assert DGVT.bigHead([]) == :Nothing
    assert DGVT.bigHead([1]) == :Nothing
    assert DGVT.bigHead([2]) == {:Just, 2}
  end

  test "guards with view" do
    assert DGVT.bigHead2([]) == :Nothing
    assert DGVT.bigHead2([1]) == :Nothing
    assert DGVT.bigHead2([2]) == {:Just, 2}
  end

  test "guards with view pattern" do
    result = DGVT.c(2 - :rand.uniform(2))
    assert result == :ko
  end
end
