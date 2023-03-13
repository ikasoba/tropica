import tables

type VEvent = object of RootObj


type VEventTarget = object of RootObj
  listeners: Table[string, proc(e: VEvent)]

type VNode = object of RootObj
  nodeName: string