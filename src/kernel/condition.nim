import std/deques

import lock
import sched
import threaddef

type
  ConditionVar* = ref object of RootObj
    lock: Lock
    waiters: Deque[Thread]

proc newConditionVar*(): ConditionVar =
  result = new(ConditionVar)
  result.lock = newSpinLock()

proc wait*(cv: ConditionVar) =
  cv.lock.acquire
  cv.waiters.addLast(getCurrentThread())
  cv.lock.release
  wait()

proc signal*(cv: ConditionVar) =
  cv.lock.acquire
  if cv.waiters.len > 0:
    let th = cv.waiters.popFirst
    signal(th)
  cv.lock.release

proc broadcast*(cv: ConditionVar) =
  cv.lock.acquire
  while cv.waiters.len > 0:
    signal(cv.waiters.popFirst)
  cv.lock.release
