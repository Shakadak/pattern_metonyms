defmodule Matchv.RemoteViewTest do
  use ExUnit.Case, async: true

  test "view with remote pattern" do
    defmodule TestRPL2 do
      import PatternMetonyms

      pattern(head(x) <- [x | _])
    end

    defmodule TestRPL2.Act do
      def foo(xs) do
        import PatternMetonyms
        require TestRPL2

        matchv?(TestRPL2.head(1), xs)
      end
    end

    assert TestRPL2.Act.foo([1, 2, 3])
  end

  test "view with remote pattern using a view" do
    defmodule TestRVPL1 do
      import PatternMetonyms

      def reverse(xs), do: Enum.reverse(xs)

      pattern(rev_head(x) <- (reverse() -> [x | _]))
    end

    defmodule TestRVPL1.Act do
      def foo(xs) do
        import PatternMetonyms

        # Because the ast we are given doesn't tell us
        # where does `reverse` come from, we are forced to import
        # the module defining `rev_head` to get access to the same `reverse` a it does
        # but if it did import `Enum.reverse/1`, importing `TestRVPL1` wouldn't work.
        # So later on I might add a check on the context to see if the function
        # in the view is present in the imported scope.
        import TestRVPL1

        matchv?(TestRVPL1.rev_head(3), xs)
      end
    end

    assert TestRVPL1.Act.foo([1, 2, 3])
  end

  test "view with remote pattern using a remote call within a view" do
    defmodule TestRVPL3 do
      import PatternMetonyms

      pattern(rev_head(x) <- (Enum.reverse() -> [x | _]))
    end

    defmodule TestRVPL3.Act do
      def foo(xs) do
        import PatternMetonyms

        require TestRVPL3

        matchv?(TestRVPL3.rev_head(3), xs)
      end
    end

    assert TestRVPL3.Act.foo([1, 2, 3])
  end

  test "view with remote call within a view" do
    import PatternMetonyms

    xs = [1, 2, 3]

    
    assert matchv?((Enum.reverse() -> [3 | _]), xs)
  end

  test "view with remote pattern using a remote call within an explicitly bidirectional pattern" do
    defmodule TestRVPL4 do
      import PatternMetonyms

      pattern((tuple2(x, y) <- (Tuple.to_list() -> [x, y | _])) when tuple2(x, y) = {x, y})
    end

    defmodule TestRVPL4.Act do
      def foo(xs) do
        import PatternMetonyms

        require TestRVPL4

        matchv?(TestRVPL4.tuple2(1, 2), xs)
      end
    end

    assert TestRVPL4.Act.foo({1, 2, 3})
  end

  test "view with remote pattern using a remote call within an explicitly bidirectional pattern, eq pattern" do
    defmodule TestRVPL4eq do
      import PatternMetonyms

      pattern((tuple2(x, y) <- (Tuple.to_list() -> [x, y | _])) when tuple2(x, y) = {x, y})
    end

    defmodule TestRVPL4eq.Act do
      def foo(xs) do
        import PatternMetonyms

        require TestRVPL4eq

        matchv?(TestRVPL4eq.tuple2(x, x), xs)
      end
    end

    refute TestRVPL4eq.Act.foo({1, 2, 3})
    assert TestRVPL4eq.Act.foo({2, 2, 3})
  end
end
