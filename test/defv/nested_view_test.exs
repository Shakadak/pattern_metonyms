defmodule Defv.NestedViewTest do
  use ExUnit.Case, async: true

  defmodule DNVT do
    use PatternMetonyms

    pattern two <- 2

    defv foo({two(), two()}), do: :ok
    defv foo({_x, _y}), do: :ko

    pattern two_i <- (Function.identity() -> 2)

    defv bar({two(), two()}), do: :ok
    defv bar({_x, _y}), do: :ko

    pattern(just(x) <- (Function.identity() -> {:Just, x}))

    defv baz({just(two_i())}), do: :ok
    defv baz(_), do: :ko
  end

  test "view two 2 pair" do
    assert DNVT.foo({2, 2}) == :ok
  end

  test "view two 2 pair (with id)" do
    assert DNVT.bar({2, 2}) == :ok
  end

  test "view just two (with id)" do
    x = {:Just, 2}

    assert DNVT.baz({x}) == :ok
  end
end
