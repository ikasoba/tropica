import sugar, macros

{.experimental: "callOperator".}

type AnySignal* = object of RootObj

type Signal*[V] = object of AnySignal
  reciever: (v: V) -> V
  reactListeners: seq[() -> void]
  currentValue: V

proc newSignal*[V](initial: V, onRecieve: (v: V) -> V = proc(v: V): V = v): ref Signal[V] =
  var sig = new Signal[V]
  sig.currentValue = initial
  sig.reciever = onRecieve
  sig.reactListeners = @[]
  return sig

proc set*[V](signal: ref Signal[V], value: V): ref Signal[V] {.discardable.} =
  signal.currentValue = signal.reciever(value)
  for f in signal.reactListeners:
    f()
  return signal

proc `:=`*[V](signal: ref Signal[V], value: V): ref Signal[V] {.discardable.} =
  signal.set(value)

proc `()`*[V](signal: ref Signal[V]): V =
  signal.currentValue

proc react*[V](signal: ref Signal[V], fn: () -> void): ref Signal[V] {.discardable.} =
  signal.reactListeners.add(fn)
  return signal

proc createReactSignal*[V, R](sig: ref Signal[V], fn: () -> R): ref Signal[R] =
  var res = newSignal[R](R.default, proc(v: R): R = v)
  sig.react proc () =
    res.set(fn())
  return res

proc createReactSignal*[R](sigs: openArray[ref AnySignal], fn: () -> R): ref Signal[R] =
  var res = newSignal[R](R.default, proc(v: R): R = v)
  res.set(fn())
  for tmp in sigs:
    var sig = cast[ref Signal[void]](tmp)
    sig.react proc (): void =
      res.set(fn())
  return res

macro `:>`*(left: untyped, right: untyped): untyped =
  if left.kind == nnkBracket:
    var sigs = nnkBracket.newTree()
    for x in left:
      sigs.add(nnkCast.newTree(
        nnkRefTy.newTree(
          ident("AnySignal")
        ),
        x
      ))
    return newCall(
      ident("createReactSignal"),
      sigs,
      nnkLambda.newTree(
        newEmptyNode(),
        newEmptyNode(),
        newEmptyNode(),
        nnkFormalParams.newTree(ident("auto")),
        newEmptyNode(),
        newEmptyNode(),
        nnkStmtList.newTree(right)
      )
    )
  else:
    return newCall(
      ident("createReactSignal"),
      left,
      nnkLambda.newTree(
        newEmptyNode(),
        newEmptyNode(),
        newEmptyNode(),
        nnkFormalParams.newTree(ident("auto")),
        newEmptyNode(),
        newEmptyNode(),
        nnkStmtList.newTree(right)
      )
    )