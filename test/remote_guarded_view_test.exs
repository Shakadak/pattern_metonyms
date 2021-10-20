defmodule RemoteGuardedViewTest do
  use ExUnit.Case

  test "guarded view with remote pattern using a view" do
    defmodule TestRVPL2 do
      import PatternMetonyms

      def reverse(xs), do: Enum.reverse(xs)

      pattern rev_head(x) <- (reverse() -> [x | _])
    end

    defmodule TestRVPL2.Act do
      def foo(xs) do
        import PatternMetonyms

        # Because the ast we are given doesn't tell us
        # where does `reverse` come from, we are forced to import
        # the module defining `rev_head` to get access to the same `reverse` a it does
        # but if it did import `Enum.reverse/1`, importing `TestRVPL1` wouldn't work.
        # So later on I might add a check on the context to see if the function
        # in the view is present in the imported scope.
        import TestRVPL2

        view xs do
          TestRVPL2.rev_head(n) when n < 2 -> {:ok, n}
          _ -> :error
        end
      end
    end

    assert TestRVPL2.Act.foo([1, 2, 3]) == :error
  end
end
