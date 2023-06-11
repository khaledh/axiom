import std/strformat
import std/deques
import std/tables

import debug
import devices/cpu
import lock
import timer

{.experimental: "codeReordering".}

const
  StackSize = 4096

type
  ThreadStackArray* = array[StackSize, uint64]
  ThreadStack* = ref ThreadStackArray

  ThreadState* = enum
    tsNew
    tsReady
    tsRunning
    tsSleeping
    tsWaiting
    tsTerminated

  ThreadPriority* = -7..8

  Thread* = ref object
    rsp*: uint64
    id*: uint64
    name*: string
    stack*: ThreadStack
    priority*: ThreadPriority
    state*: ThreadState

  SleepingThread* = ref object
    thread*: Thread
    sleepUntil*: uint64

  WaitingThread* = ref object
    thread*: Thread
    cond*: ConditionVar

  ThreadTransition* = object
    case toState*: ThreadState
    of tsSleeping:
      sleepUntil*: uint64
    of tsWaiting:
      condition*: ConditionVar
    else: discard

  ThreadFunc* = proc () {.cdecl.}

  SwitchStack* {.packed.} = object
    r15*: uint64
    r14*: uint64
    r13*: uint64
    r12*: uint64
    r11*: uint64
    r10*: uint64
    r9*: uint64
    r8*: uint64
    rdi*: uint64
    rsi*: uint64
    rbp*: uint64
    rbx*: uint64
    rdx*: uint64
    rcx*: uint64
    rax*: uint64
    rip*: uint64

# we want heap[0] to contian the thread with highest priority
# so we invert the inequality here
proc `<`*(a, b: Thread): bool = a.priority > b.priority
proc `<`*(a, b: SleepingThread): bool = a.sleepUntil < b.sleepUntil
proc `<`*(a, b: WaitingThread): bool = a.thread.priority > b.thread.priority

proc `$`*(t: Thread): string =
  result = &"Thread({t.id}, '{t.name}', pri={t.priority}, state={t.state})"

var
  nextId: uint64 = 0
  currentThread*: Thread
  schedule: proc () {.cdecl.}
  transitionTo: proc (th: Thread, evt: ThreadTransition): bool {.cdecl.}
  terminateConds*: Table[uint64, ConditionVar]
  terminateLock*: Lock = newSpinLock()

proc getCurrentThread*(): Thread {.inline.} =
  result = currentThread

proc createThread*(threadFunc: ThreadFunc, priority: ThreadPriority = 0, name: string = ""): Thread =

  proc threadWrapper(threadFunc: ThreadFunc) =
    threadFunc()
    disableInterrupts()
    terminate()

  let id = nextId
  inc nextId

  debugln(&"thread: creating new thread: id={id}, name='{name}', pri={priority}")

  var thNew = new(Thread)
  thNew.id = id
  thNew.name = name
  thNew.state = tsNew
  thNew.priority = priority

  thNew.stack = new(ThreadStack)
  thNew.rsp = cast[uint64](thNew.stack) + sizeof(ThreadStackArray).uint64 - sizeof(SwitchStack).uint64 - 128

  var ss = cast[ptr SwitchStack](thNew.rsp)
  zeroMem(ss, sizeof(SwitchStack))
  ss.rcx = cast[uint64](threadFunc)
  ss.rip = cast[uint64](threadWrapper)

  result = thNew

####################################################################################################
# API for managing the current thread

proc sleep*(ticks: uint64) =
  if ticks == 0:
    return
  let sleepUntil = getTimerTicks() + ticks
  if transitionTo(currentThread, ThreadTransition(toState: tsSleeping, sleepUntil: sleepUntil)):
    # debugln(&"thread.sleep: id={currentThread.id}, name={currentThread.name}, until={sleepUntil}")
    schedule()

proc wait*() =
  if transitionTo(currentThread, ThreadTransition(toState: tsWaiting)):
    debugln(&"thread.wait: id={currentThread.id}, name={currentThread.name}")
    schedule()

proc join*(th: Thread) =
  var cond = terminateConds.mgetOrPut(th.id, newConditionVar())
  cond.wait(terminateLock)

proc terminate*() =
  if transitionTo(currentThread, ThreadTransition(toState: tsTerminated)):
    debugln(&"thread.terminate: id={currentThread.id}, name={currentThread.name}")
    schedule()


####################################################################################################
# API for managing other threads

proc start*(th: Thread) =
  if transitionTo(th, ThreadTransition(toState: tsReady)):
    debugln(&"sched.start: {th.id=}, name={th.name=}")

proc wakeup*(th: Thread) =
  if transitionTo(th, ThreadTransition(toState: tsReady)):
    debugln(&"sched.wakeup: {th.id=}, {th.name=}")

proc signal*(th: Thread) =
  if transitionTo(th, ThreadTransition(toState: tsReady)):
    debugln(&"sched.signal: {th.id=}, {th.name=}")

proc stop*(th: Thread) =
  if transitionTo(th, ThreadTransition(toState: tsTerminated)):
    debugln(&"sched.stop: {th.id=}, {th.name=}")


####################################################################################################
# Initialization

proc init*(
  scheduleProc: proc () {.cdecl.},
  transitionProc: proc (th: Thread, evt: ThreadTransition): bool {.cdecl.}
) {.cdecl.} =
  schedule = scheduleProc
  transitionTo = transitionProc


####################################################################################################
# Condition variables

type
  ConditionVar* = ref object of RootObj
    lock: Lock
    waiters: Deque[Thread]

proc newConditionVar*(): ConditionVar =
  result = new(ConditionVar)
  result.lock = newSpinLock()

proc wait*(cv: ConditionVar, l: var Lock) =
  cv.lock.acquire
  cv.waiters.addLast(getCurrentThread())
  cv.lock.release
  l.release
  wait()
  l.acquire

proc signal*(cv: ConditionVar) =
  cv.lock.acquire
  if cv.waiters.len > 0:
    cv.waiters.popFirst.signal
  cv.lock.release

proc broadcast*(cv: ConditionVar) =
  cv.lock.acquire
  while cv.waiters.len > 0:
    cv.waiters.popFirst.signal
  cv.lock.release
