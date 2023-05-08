import std/deques
import std/strformat

import debug
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
  debugln("condvar.wait: acquiring lock")
  cv.lock.acquire
  debugln("condvar.wait: acquired lock, adding current thread to waiters")
  cv.waiters.addLast(thCurr)
  debugln("condvar.wait: releasing lock")
  cv.lock.release
  debugln("condvar.wait: putting current thread to sleep")
  sleep()

proc signal*(cv: ConditionVar) =
  debugln("condvar.signal: acquiring lock")
  cv.lock.acquire
  debugln("condvar.signal: acquired lock")
  if cv.waiters.len > 0:
    debugln(&"condvar.signal: waking up next waiter of {cv.waiters.len}")
    let t = cv.waiters.popFirst
    wakeup(t)
  debugln("condvar.signal: releasing lock")
  cv.lock.release

proc broadcast*(cv: ConditionVar) =
  debugln("condvar.broadcast: acquiring lock")
  cv.lock.acquire
  debugln("condvar.broadcast: acquired lock")
  debugln(&"condvar.broadcast: waking up {cv.waiters.len} waiters")
  while cv.waiters.len > 0:
    wakeup(cv.waiters.popFirst)
  debugln("condvar.broadcast: releasing lock")
  cv.lock.release
