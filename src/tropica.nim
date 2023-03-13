import jsffi, dom, sugar, strutils, macros, sequtils
import signal

export signal

type TropicaElmChildKind* = enum
  CSTRING,
  NODE,
  SIGNAL_STRING,
  SIGNAL_INT,
  SIGNAL_FLOAT

type TropicaElmChild* = ref object
  case kind: TropicaElmChildKind
  of CSTRING:
    cstr: cstring
  of NODE:
    node: Node
  of SIGNAL_STRING:
    signal_string: ref Signal[string]
  of SIGNAL_FLOAT:
    signal_float: ref Signal[float]
  of SIGNAL_INT:
    signal_int: ref Signal[int]

type TropicaAttrValueKind* = enum
  LISTENER,
  STRING,
  JS_OBJECT

type TropicaAttrItem* = ref object
  case kind: TropicaAttrValueKind
  of LISTENER:
    listener: proc(e: Event)
  of STRING:
    str: string
  of JS_OBJECT:
    obj: JsObject
  key: string

type Attrs* = seq[TropicaAttrItem]

proc newTropicaAttrItem*(key: string, value: proc(e: Event)): TropicaAttrItem =
  return TropicaAttrItem(kind: TropicaAttrValueKind.LISTENER, key: key, listener: value)

proc newTropicaAttrItem*(key: string, value: proc()): TropicaAttrItem =
  return TropicaAttrItem(kind: TropicaAttrValueKind.LISTENER, key: key, listener: proc(e: Event) = value())

proc newTropicaAttrItem*(key: string, value: string): TropicaAttrItem =
  return TropicaAttrItem(kind: TropicaAttrValueKind.STRING, key: key, str: value)

proc newTropicaAttrItem*(key: string, value: JsObject): TropicaAttrItem =
    return TropicaAttrItem(kind: TropicaAttrValueKind.JS_OBJECT, key: key, obj: value)

proc newTropicaElmChild*(value: string): TropicaElmChild =
  TropicaElmChild(
    kind: CSTRING,
    cstr: cstring(value)
  )

proc newTropicaElmChild*(value: cstring): TropicaElmChild =
  TropicaElmChild(
    kind: CSTRING,
    cstr: value
  )

proc newTropicaElmChild*(value: int): TropicaElmChild =
  TropicaElmChild(
    kind: CSTRING,
    cstr: cstring($value)
  )

proc newTropicaElmChild*(value: float): TropicaElmChild =
  TropicaElmChild(
    kind: CSTRING,
    cstr: cstring($value)
  )

proc newTropicaElmChild*(value: Node): TropicaElmChild =
  TropicaElmChild(
    kind: NODE,
    node: value
  )

method newTropicaElmChild*[T](value: T): TropicaElmChild =
    return TropicaElmChild(
      kind: SIGNAL_STRING,
      signal_string: $value
    )

proc newTropicaElmChild*(value: ref Signal[string]): TropicaElmChild =
  TropicaElmChild(
    kind: SIGNAL_STRING,
    signal_string: value
  )

proc newTropicaElmChild*(value: ref Signal[int]): TropicaElmChild =
  TropicaElmChild(
    kind: SIGNAL_INT,
    signal_int: value
  )

proc newTropicaElmChild*(value: ref Signal[float]): TropicaElmChild =
  TropicaElmChild(
    kind: SIGNAL_FLOAT,
    signal_float: value
  )

type TropicaChildren* = openArray[TropicaElmChild]

proc createElement*(name: string, attrs: Attrs, children: TropicaChildren): Element =
  var elm = document.createElement(name)
  for item in attrs:
    if item.key.startsWith("on:"):
      var length = len(item.key)
      var value =
        if item.kind == LISTENER:
          item.listener
        else: continue
      elm.addEventListener(item.key[3..(length - 1)].cstring, value)
    else:
      var value: string =
        if item.kind == STRING:
          item.str
        else:
          continue
      elm.setAttribute(item.key.cstring, value.cstring)
  for child in children:
    if child.kind == CSTRING:
      elm.appendChild(document.createTextNode(child.cstr))
    elif child.kind == NODE:
      elm.appendChild(child.node)
    elif child.kind == SIGNAL_STRING or child.kind == SIGNAL_INT or child.kind == SIGNAL_FLOAT:
      var text: Node
      if child.kind == SIGNAL_STRING:
        var value = child.signal_string
        text = document.createTextNode(cstring(value()))
        capture text, value:
          discard value.react proc(): void =
            text.textContent = cstring(value())
      elif child.kind == SIGNAL_INT:
        var value = child.signal_int
        text = document.createTextNode(cstring($value()))
        capture text, value:
          discard value.react proc(): void =
            text.textContent = cstring($value())
      elif child.kind == SIGNAL_FLOAT:
        var value = child.signal_float
        text = document.createTextNode(cstring($value()))
        capture text, value:
          discard value.react proc(): void =
            text.textContent = cstring($value())
      elm.appendChild(text)
  return elm

proc nodeToTropicaChildren*(arr: var NimNode, node: NimNode): bool =
  for x in node:
    if x.kind == nnkDiscardStmt: continue
    elif x.kind == nnkCommand:
      if x[0].kind != nnkIdent:
        if not nodeToTropicaChildren(arr, x):
          return false
        continue
      else:
        arr.add(ident("newTropicaElmChild").newCall(
          x,
        ))
        continue
    elif x.kind == nnkCurly and x.len <= 1:
      arr.add(ident("newTropicaElmChild").newCall(
        x[0],
      ))
      continue
    elif x.kind == nnkStrLit or x.kind == nnkIntLit:
      arr.add(ident("newTropicaElmChild").newCall(
        x,
      ))
      continue
    return false
  return true

macro t*(tmp: untyped, tmpChildren: untyped): untyped =
  var isComponent: bool = false
  var name: string
  var attrs: NimNode = nnkBracket.newTree()
  if tmp.kind == nnkCommand:
    if tmp[0].kind == nnkStrLit:
      name = tmp[0].strVal
    elif tmp[0].kind == nnkIdent:
      name = tmp[0].strVal
      isComponent = true
    if tmp.len > 1:
      if (tmp[1].kind == nnkTableConstr or tmp[1].kind == nnkCurly):
        for item in tmp[1]:
          if item.kind != nnkExprEqExpr and item.kind != nnkExprColonExpr:
            error("invalid expression")
          if isComponent:
            attrs.add nnkExprEqExpr.newTree(
              ident(item[0].strVal),
              item[1]
            )
          else:
            for item in tmp[1]:
              attrs.add ident("newTropicaAttrItem").newCall(
                (
                  if item[0].kind == nnkStrLit:
                    item[0]
                  elif item[0].kind == nnkIdent:
                    item[0].toStrLit
                  elif item[0].kind == nnkAccQuoted:
                    item[0][0].toStrLit
                  else:
                    item[0].toStrLit
                ),
                item[1]
              )
      elif tmp[1].kind != nnkNilLit:
        error("attribute is only tableConstr or nilLit")
  elif tmp.kind == nnkStrLit:
    name = tmp.strVal
  elif tmp.kind == nnkIdent:
    name = tmp.strVal
    isComponent = true
  else:
    error("first argument type is string")
  var children = nnkBracket.newTree()
  if not nodeToTropicaChildren(children, tmpChildren):
    error("When specifying an expression to children, enclose it in wave brackets.")
  if not isComponent:
    return ident("createElement").newCall(
      newLit(name),
      nnkPrefix.newTree(
        ident("@"),
        attrs
      ),
      nnkPrefix.newTree(
        ident("@"),
        children
      )
    )
  else:
    var invokeComponent = ident(name).newCall()
    for item in attrs:
      invokeComponent.add item
    if children.len > 0:
      invokeComponent.add nnkExprEqExpr.newTree(
        ident("children"),
        children
      )
    return invokeComponent

template t*(tmp: untyped): untyped =
  t tmp: discard
