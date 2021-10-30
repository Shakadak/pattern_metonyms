defmodule Defv.RemoteGuardedViewTest do
  use ExUnit.Case, async: true

  test "guarded view with remote pattern using a view" do
    defmodule DTestRVPL2 do
      import PatternMetonyms

      def reverse(xs), do: Enum.reverse(xs)

      pattern(rev_head(x) <- (reverse() -> [x | _]))
    end

    defmodule DTestRVPL2.Act do
      use PatternMetonyms

      # Because the ast we are given doesn't tell us
      # where does `reverse` come from, we are forced to import
      # the module defining `rev_head` to get access to the same `reverse` a it does
      # but if it did import `Enum.reverse/1`, importing `TestRVPL1` wouldn't work.
      # So later on I might add a check on the context to see if the function
      # in the view is present in the imported scope.
      import DTestRVPL2

      defv foo(DTestRVPL2.rev_head(n)) when n < 2, do: {:ok, n}
      defv foo(_), do: :error
    end

    assert DTestRVPL2.Act.foo([1, 2, 3]) == :error
    assert DTestRVPL2.Act.foo([3, 2, 1]) == {:ok, 1}
  end
end
