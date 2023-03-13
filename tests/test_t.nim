# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest, dom
import tropica

{.emit: """
  const dom = new (require("jsdom").JSDOM)("<!DOCTPE html>")
  const window = dom.window
  const {document} = window
""".}

test "test t":
  var element =
    t "div" {class = "hoge fuga"}:
      "あああ！！！"
      t "p": "お味噌汁"

  check element.nodeName == "DIV"
  check element.className == "hoge fuga"
  check element[0].textContent == "あああ！！！"
  check element[1].nodeName == "P"
  check element[1].textContent == "お味噌汁"