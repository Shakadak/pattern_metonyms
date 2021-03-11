defmodule AnonymousFunctionViewTest do
  use ExUnit.Case

  #test "view with anonymous function" do
  #  import PatternMetonyms

  #  xs = [1, 2, 3]
  #  result = view xs do
  #    (fn [_, x, _] -> x end -> n) -> n
  #  end

  #  assert result == 2
  #end

  #test "view with stored anonymous function" do
  #  import PatternMetonyms

  #  xs = [1, 2, 3]
  #  fun = fn [_, x, _] -> x end
  #  result = view xs do
  #    (fun.() -> n) -> n
  #  end

  #  assert result == 2
  #end
end
