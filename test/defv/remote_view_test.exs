defmodule Defv.RemoteViewTest do
  use ExUnit.Case, async: true

  defmodule DRVT.Remote do
    import PatternMetonyms

    pattern(head(x) <- [x | _])

    def reverse(xs), do: Enum.reverse(xs)

    pattern(rev_head(x) <- (reverse() -> [x | _]))

    pattern(rev_head2(x) <- (Enum.reverse() -> [x | _]))

    pattern((tuple2(x, y) <- (Tuple.to_list() -> [x, y | _])) when tuple2(x, y) = {x, y})
  end

  defmodule DRVT do
    use PatternMetonyms

    require DRVT.Remote

    defv foo(DRVT.Remote.head(n)), do: {:ok, n}
    defv foo(_), do: :error

    defv baz(DRVT.Remote.rev_head2(n)), do: {:ok, n}
    defv baz(_), do: :error

    defv qux((Enum.reverse() -> [n | _])), do: {:ok, n}
    defv qux(_), do: :error

    defv bin(DRVT.Remote.tuple2(x, y)), do: DRVT.Remote.tuple2(y, x)
    defv bin(_), do: :error

    # Because the ast we are given doesn't tell us
    # where does `reverse` come from, we are forced to import
    # the module defining `rev_head` to get access to the same `reverse` as it does
    # but if it did import `Enum.reverse/1`, importing `DRVT.Remote` wouldn't work.
    # So later on I might add a check on the context to see if the function
    # in the view is present in the imported scope.

    import DRVT.Remote
    defv bar(DRVT.Remote.rev_head(n)), do: {:ok, n}
    defv bar(_), do: :error
  end

  test "view with remote pattern" do
    assert DRVT.foo([1, 2, 3]) == {:ok, 1}
  end

  test "view with remote pattern using a view" do
    assert DRVT.bar([1, 2, 3]) == {:ok, 3}
  end

  test "view with remote pattern using a remote call within a view" do
    assert DRVT.baz([1, 2, 3]) == {:ok, 3}
  end

  test "view with remote call within a view" do
    xs = [1, 2, 3]

    assert DRVT.qux(xs) == {:ok, 3}
  end

  test "view with remote pattern using a remote call within an explicitly bidirectional pattern" do
    assert DRVT.bin({1, 2, 3}) == {2, 1}
  end
end
