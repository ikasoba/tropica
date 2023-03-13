# about
tropica is a small frontend framework for nim.
it was written to create a simple web site.

```nim
import tropica

proc main =
  var count = newSignal(0)

  t "div":
    t "p":
      "count: " {count}
    t "button" {
      "on:click": proc() = count := count() + 1
    }:
      "click here!"
```