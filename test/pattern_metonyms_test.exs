defmodule PatternMetonymsTest do
  use ExUnit.Case
  doctest PatternMetonyms

  test "maybe pair" do
    defmodule TestM2 do
      import PatternMetonyms

      pattern just2(a, b) = {:Just, {a, b}}

      def f(just2(x, y)), do: x + y
      def foo, do: f(just2(3, 2))
    end

    assert TestM2.foo == 5
  end

  test "maybe triplet" do
    defmodule TestM3 do
      import PatternMetonyms

      pattern just3(a, b, c) =
        {:Just, {a, b, c}}

      def g(just3(x, y, _)), do: x + y
      def bar, do: g(just3(3, 2, 1))
    end

    assert TestM3.bar == 5
  end

  test "maybe singleton" do
    defmodule TestM1 do
      import PatternMetonyms

      pattern just1(a) = {:Just, a}

      def h(just1(x)), do: -x
      def baz, do: h(just1(3))
    end

    assert TestM1.baz == -3
  end

  test "list head" do
    defmodule TestL1 do
      import PatternMetonyms

      pattern head(x) <- [x | _]

      def f(head(x)), do: x
    end

    assert TestL1.f([1, 2, 3]) == 1
  end

  test "raise list head" do
    assert_raise CompileError, fn ->
      defmodule TestL2 do
        import PatternMetonyms

        pattern head(x) <- [x | _]

        def g, do: head(4)
      end
    end
  end

  test "view maybe pair" do
    defmodule TestVM2 do
      import PatternMetonyms

      pattern just2(a, b) = {:Just, {a, b}}

      def f(x) do
        view x do
          just2(x, y) -> x + y
          :Nothing -> 0
        end
      end

      def foo, do: f(just2(3, 2))
    end

    assert TestVM2.foo == 5
  end

  test "view safe head" do
    defmodule TestVL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      def safeHead(xs) do
        view xs do
          (uncons -> {:Just, {x, _}}) -> {:Just, x}
          _ -> :Nothing
        end
      end
    end

    assert TestVL1.safeHead([]) == :Nothing
    assert TestVL1.safeHead([1]) == {:Just, 1}
  end

  test "pattern safe head" do
    defmodule TestPL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      pattern justHead(x) <- (uncons -> {:Just, {x, _}})

      def safeHead(xs) do
        view xs do
          justHead(x) -> {:Just, x}
          _ -> :Nothing
        end
      end
    end

    assert TestPL1.safeHead([]) == :Nothing
    assert TestPL1.safeHead([1]) == {:Just, 1}
  end

  test "explicit pattern coordinate" do
    defmodule TestEPC1 do
      import PatternMetonyms

      def new_cartesian(x, y), do: %{x: x, y: y}

      def new_polar(r, t), do: {r, t}

      def polar_to_cartesian({r, t}) do
        x = r * :math.cos(t)
        y = r * :math.sin(t)
        new_cartesian(x, y)
      end

      def cartesian_to_polar(%{x: x, y: y}) do
        r = :math.sqrt(x * x + y * y)
        t = :math.atan(y / x)
        new_polar(r, t)
      end

      pattern (polar(r, a) <- (cartesian_to_polar -> {r, a}))
        when polar(r, a) = polar_to_cartesian(r, a)

      def foo(point) do
        view point do
          polar(r, a) -> %{radius: r, theta: a}
        end
      end
    end

    # results from : https://keisan.casio.com/exec/system/1223526375
    # angle unit radian, 18digit
    assert TestEPC1.foo(TestEPC1.new_cartesian(3, 3)) == %{radius: 4.24264068711928515, theta: 0.78539816339744831}
  end

  test "explicit pattern string x integer" do
    defmodule TestEPSI1 do
      import PatternMetonyms

      def string_to_integer(s), do: String.to_integer(s)
      def integer_to_string(i), do: Integer.to_string(i)

      pattern (sti(x) <- (string_to_integer -> x)) when sti(x) = integer_to_string(x)

      def foo(s) do
        view s do
          sti(i) -> sti(max(5, i))
        end
      end
    end

    assert TestEPSI1.foo("65") == "65"
    assert TestEPSI1.foo("-45") == "5"
  end

  test "guards with pattern" do
    defmodule TestGPL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      pattern justHead(x) <- (uncons -> {:Just, {x, _}})

      def bigHead(xs) do
        view xs do
          justHead(x) when x > 1 -> {:Just, x}
          _ -> :Nothing
        end
      end
    end

    assert TestGPL1.bigHead([]) == :Nothing
    assert TestGPL1.bigHead([1]) == :Nothing
    assert TestGPL1.bigHead([2]) == {:Just, 2}
  end

  test "guards with view" do
    defmodule TestGVL1 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      def bigHead(xs) do
        view xs do
          (uncons -> {:Just, {x, _}}) when x > 1 -> {:Just, x}
          _ -> :Nothing
        end
      end
    end

    assert TestGVL1.bigHead([]) == :Nothing
    assert TestGVL1.bigHead([1]) == :Nothing
    assert TestGVL1.bigHead([2]) == {:Just, 2}
  end

  test "guards within view (might disappear)" do
    defmodule TestGVL2 do
      import PatternMetonyms

      def uncons([]), do: :Nothing
      def uncons([x | xs]), do: {:Just, {x, xs}}

      def bigHead(xs) do
        view xs do
          (uncons -> {:Just, {x, _}} when x > 1) -> {:Just, x}
          _ -> :Nothing
        end
      end
    end

    assert TestGVL2.bigHead([]) == :Nothing
    assert TestGVL2.bigHead([1]) == :Nothing
    assert TestGVL2.bigHead([2]) == {:Just, 2}
  end

  test "guards with view pattern" do
    import PatternMetonyms
    result = view 2 - :rand.uniform(2) do
      (abs -> x) when x > 3 -> :ok
      (abs -> x) when x < 3 -> :ko
      x -> x
    end
    assert result == :ko
  end

  test "case with remote pattern" do
    defmodule TestRPL1 do
      import PatternMetonyms

      pattern head(x) <- [x | _]
    end

    defmodule TestRPL1.Act do
      def foo(xs) do
        require TestRPL1
        case xs do
          TestRPL1.head(n) -> {:ok, n}
          _ -> :error
        end
      end
    end

    assert TestRPL1.Act.foo([1, 2, 3]) == {:ok, 1}
  end

  test "view with remote pattern" do
    defmodule TestRPL2 do
      import PatternMetonyms

      pattern head(x) <- [x | _]
    end

    defmodule TestRPL2.Act do
      def foo(xs) do
        import PatternMetonyms
        require TestRPL2

        view xs do
          TestRPL2.head(n) -> {:ok, n}
          _ -> :error
        end
      end
    end

    assert TestRPL2.Act.foo([1, 2, 3]) == {:ok, 1}
  end

  test "view with remote pattern using a view" do
    defmodule TestRVPL1 do
      import PatternMetonyms

      def reverse(xs), do: Enum.reverse(xs)

      pattern rev_head(x) <- (reverse -> [x | _])
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

        view xs do
          TestRVPL1.rev_head(n) -> {:ok, n}
          _ -> :error
        end
      end
    end

    assert TestRVPL1.Act.foo([1, 2, 3]) == {:ok, 3}
  end

  test "guarded view with remote pattern using a view" do
    defmodule TestRVPL2 do
      import PatternMetonyms

      def reverse(xs), do: Enum.reverse(xs)

      pattern rev_head(x) <- (reverse -> [x | _])
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

  test "view with remote pattern using a remote call within a view" do
    defmodule TestRVPL3 do
      import PatternMetonyms

      pattern rev_head(x) <- (Enum.reverse -> [x | _])
    end

    defmodule TestRVPL3.Act do
      def foo(xs) do
        import PatternMetonyms

        require TestRVPL3

        view xs do
          TestRVPL3.rev_head(n) -> {:ok, n}
          _ -> :error
        end
      end
    end

    assert TestRVPL3.Act.foo([1, 2, 3]) == {:ok, 3}
  end

  test "view with remote call within a view" do
    import PatternMetonyms

    xs = [1, 2, 3]
    result = view xs do
      (Enum.reverse -> [n | _]) -> {:ok, n}
      _ -> :error
    end

    assert result == {:ok, 3}
  end

  test "case isomorphism" do
    import PatternMetonyms

    xs = [1, 2, 3]
    result = view xs do
      [x | _xs] -> x
      [] -> 0
    end

    assert result == 1
  end

  test "view with remote pattern using a remote call within an explicitly bidirectional pattern" do
    defmodule TestRVPL4 do
      import PatternMetonyms

      pattern (tuple2(x, y) <- (Tuple.to_list -> [x, y | _])) when tuple2(x, y) = {x, y}
    end

    defmodule TestRVPL4.Act do
      def foo(xs) do
        import PatternMetonyms

        require TestRVPL4

        view xs do
          TestRVPL4.tuple2(x, y) -> TestRVPL4.tuple2(y, x)
          _ -> :error
        end
      end
    end

    assert TestRVPL4.Act.foo({1, 2, 3}) == {2, 1}
  end
end
