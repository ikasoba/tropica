import os

switch("path", "$projectDir/../src")
switch("backend", "js")


if not dirExists("./tests/node_modules"):
  echo """

    __/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\__
    > Please run `npm i` at ./tests/ in your shell.  <
    ¯¯\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/¯¯
  """
  quit 1