import atomic

type
  Lock* = ref object of RootObj
    locked*: bool = false
  SpinLock* = ref object of Lock


method acquire*(l: Lock) {.base.} =
  raise newException(CatchableError, "Method without implementation override")

method release*(l: Lock) {.base.} =
  raise newException(CatchableError, "Method without implementation override")


### SpinLock

proc newSpinLock*(): SpinLock =
  result = SpinLock(locked: false)

method acquire*(l: SpinLock) =
  while true:
    if cmpxchg(l.locked, oldValue = false, newValue = true):
      break
    asm "pause"

method release*(l: SpinLock) =
  l.locked = false
