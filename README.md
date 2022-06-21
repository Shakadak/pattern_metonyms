# PatternMetonyms

Attempt at implementing Pattern Synonyms from [https://www.microsoft.com/en-us/research/wp-content/uploads/2016/08/pattern-synonyms-Haskell16.pdf](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/08/pattern-synonyms-Haskell16.pdf) but obviously missing a ton of check, most notably from the type checker.

Consider this as a personal project project until 1.0.0, you may open issues, but pull requests will be closed without consideration.

## Warning

This library hides a lot of code, please keep yourself aware that by using it, you are trading a lot of runtime efficiency for a lot of (unmeasured) expressivness power.

## Installation

The package can be installed by adding `pattern_metonyms` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pattern_metonyms, "~> 0.8.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/pattern_metonyms](https://hexdocs.pm/pattern_metonyms).

## Examples

It can be hard to see at first glance why this would be interesting, so I'm going to try to fill example usages over time.

### Stacks

Stacks are easy to implement, and easy to manipulate: just use a list !
You can use it raw:
- when you want to push something, just cons an element: `new_stack = [x | stack]`
- when you want to pop something, just unconse an element: `[x | new_stack] = stack`

We can improve the code by using functions, in order to give names to the operations.
This is useful because it gives us a vocabulary, thus when we encounter the code,
we don't have to refer to the context, or hold it in our head in order to follow the code:
- when you want to push something, just call the appropriate function: `new_stack = Stack.push(stack, x)`
- when you want to pop something, call the appropriate function and match on the result: `{x, new_stack} = Stack.pop(stack)`
This also has the advantage of functions being first class values, you can pass them around.

But has seen, we have to match while knowing what the result of the function will look like.
This is fine but it still presents some overhead, both in the execution compared to the raw version, and in the expressivity because of the necessity to match on the tuple.

This slight expressivity impediment become more apparent when we want to use pattern matching to control the flow of execution (unless you define more functions to expand the vocabulary of what's possible).
Suppose you want to evaluate different expressions depending on if the stack is empty or not:
- when raw:
  ```elixir
  {x, new_stack} = case stack do
    [] -> {default_value, stack}
    [x | new_stack] -> {x, new_stack}
  end
  ```
- with functions:
  ```elixir
  {x, new_stack} = case Stack.pop(stack) do
    :empty -> {default_value, stack}
    t -> t
  end
  ```

This is one possibility, but what if `Stack.pop/1` was defined more straightforwardly ? You would have to check whether the stack is empty before using it:
```elixir
{x, new_stack} = if Stack.empty?(stack) do {default_value, stack} else Stack.pop(stack) end
```
Or you could have another version that directly handle the default value, with the potential of introducing some ambiguity if it was defined with a default argument itself.

So yes, this is a toy example, so it is absolutly possible to easily define a nice API with functions,
but it is possible with macros to define some vocabulary that can mix well with the pattern matching constructs.

We this library, you can define a vocabulary, that behaves as the raw code:
```elixir
defmodule Stack do
  import PatternMetonyms

  pattern empty = []
  pattern push(stack, x) = [x | stack]
  pattern pop(x, stack) = [x | stack]
end
```
Assuming the module `Stack` was require'd:
- when you want to push something: `new_stack = Stack.push(stack, x)`
- when you want to pop something: `Stack.pop(x, new_stack) = stack`
- when you want to do some control flow:
  ```elixir
  {x, new_stack} = case stack do
    Stack.empty() -> {default_value, stack}
    Stack.pop(x, stack) -> {x, stack}
  end
  ```

That's all fine and dandy, but you don't need to use this library to define these kinds of macro. (Though it isn't as nice looking. :P)
So, on to the next part !

### Queues

Queues aren't as simple as stacks, we don't have a ready made data structure for them we can pattern match on.
But we have the erlang module `:queue` that allows us to construct and manipulate erlang primitives in order to have something that acts like a queue.
Like the function section of the stacks, we have a vocabulary available to us to ease the understanding of the code.
In the same way, we can't directly use it with pattern matching. But it's not possible to define macros that mix well with the pattern matching construct.
Using this library, you can use new control flow constructs, the more interesting one being `view/2`. The others building on top of it.

Note:
  Unfortunatly it's currently too hard for me to define an equivalent to the match operator named `=/2`. (Mainly because I haven't made the effort.)
  Because of that, it's difficult to do something as nice as raw code for non conditional execution.

Using view patterns, you can directly pattern match with the functions of the module `:queue`:
- for control flow:
  ```elixir
  {x, new_queue} = view queue do
    (:queue.is_empty() -> true) -> {default_value, queue}
    (:queue.out() -> {{:value, x}, queue}) -> {x, queue}
  end
  ```
Note that `:queue.out/1` returns `{:empty, queue}` in case the queue is empty, allowing to directly pattern match on `:queue.out/1`'s result:
  ```elixir
  {x, new_queue} = case :queue.out(queue) do
    {:empty, queue} -> {default_value, queue}
    {{:value, x}, queue} -> {x, queue}
  end
  ```

Using patterns definition with view:
```elixir
defmodule Queue do
  import PatternMetonyms

  pattern empty <- (:queue.is_empty() -> true)
  pattern pop(x, queue) <- (:queue.out() -> {{:value, x}, queue})
end
```
- for control flow, assuming `Queue` was require'd:
  ```elixir
  {x, new_queue} = view queue do
    Queue.empty() -> {default_value, queue}
    Queue.pop(x, queue) -> {x, queue}
  end
  ```

This become even more interesting with recursion (though this is still a toy example).
Say `:queue.to_list/1` doesn't exist, neither `:queue.fold/3`, how would you go about defining it ?
- raw:
  ```elixir
  defmodule Queue do
    # [...]

    def to_list(queue) do
      case :queue.out(queue) do
        {:empty, _} -> []
        {{:value, x}, queue} -> [x | to_list(queue)
      end
    end
  end
  ```
- with patterns and `defv/1`:
  ```elixir
  defmodule Queue do
    # [...]

    defv to_list(empty()), do: []
    defv to_list(pop(x, queue)), do: [x | to_list(queue)]
  end
  ```

I hope you are now starting to get an idea about how to play with this lib.

More to come when the inspiration does.
