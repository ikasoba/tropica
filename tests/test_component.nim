import unittest, dom
import tropica

{.emit: """
  const dom = new (require("jsdom").JSDOM)("<!DOCTPE html>")
  const window = dom.window
  const {document} = window
""".}

test "test component":
  proc Counter(start: int = 0): Element =
    var count = newSignal(start)

    return
      t "button" {
        "on:click" = proc()= count := count() + 1
      }:
        "count: " {count}

  var counter1 = t Counter
  var counter2 = t Counter {start = 1}

  check counter1.textContent == "count: 0"
  counter1.click()
  check counter1[1].textContent == "1"

  check counter2.textContent == "count: 1"
  counter2.click()
  check counter2[1].textContent == "2"