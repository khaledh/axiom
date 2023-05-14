import std/[heapqueue, strformat, strutils]
import fusion/matching
{.experimental: "caseStmtMacros".}

import debug
import threaddef
import timer


var
  currentThread*: Thread
  readyQueue*: HeapQueue[Thread]
  blockedQueue*: HeapQueue[Thread]
  sleepingQueue*: HeapQueue[SleepingThread]
  waitingQueue*: HeapQueue[Thread]


####################################################################################################
# Low level thread switching in assembly

proc switchToThread(oldThread, newThread: Thread) {.asmNoStackFrame.} =
  asm """
    push    rax
    push    rcx
    push    rdx
    push    rbx
    push    rbp
    push    rsi
    push    rdi
    push    r8
    push    r9
    push    r10
    push    r11
    push    r12
    push    r13
    push    r14
    push    r15

    # switch stacks
    mov     [rcx], rsp
    mov     rsp, [rdx]

    jmp resumeThread
  """

proc resumeThread() {.asmNoStackFrame, exportc.} =
  asm """
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    pop     rdi
    pop     rsi
    pop     rbp
    pop     rbx
    pop     rdx
    pop     rcx
    pop     rax

    sti
    ret
  """

proc become*(thread: Thread) {.cdecl.} =
  currentThread = thread
  currentThread.state = tsRunning

  asm """
    mov rsp, %0
    jmp resumeThread
    :
    :"g"(`thread`->rsp)
  """


####################################################################################################
# Helper functions

proc getCurrentThread*(): Thread {.inline.} =
  result = currentThread

proc removeFromQueue(th: Thread, queue: var HeapQueue) =
  let idx = queue.find(th)
  if idx >= 0:
    queue.del(idx)

proc removeFromQueue(th: Thread, queue: var HeapQueue[SleepingThread]) =
  for i in 0 ..< queue.len:
    let sleeper = queue[i]
    if sleeper.thread.id == th.id:
      queue.del(i)
      return

####################################################################################################
# Thread state machine transitions

type
  TransitionEvent = object
    case toState: ThreadState
    of tsSleeping:
      sleepUntil: uint64
    else: discard

proc transitionTo*(th: Thread, event: TransitionEvent): bool =
  if th.state == event.toState:
    return false

  case (th.state, event.toState):
  of (tsNew, tsReady):
    readyQueue.push(th)

  of (tsRunning, tsReady):
    readyQueue.push(th)

  of (tsBlocked, tsReady):
    removeFromQueue(th, blockedQueue)
    readyQueue.push(th)

  of (tsSleeping, tsReady):
    removeFromQueue(th, sleepingQueue)
    readyQueue.push(th)

  of (tsWaiting, tsReady):
    removeFromQueue(th, waitingQueue)
    readyQueue.push(th)

  of (tsReady, tsRunning):
    removeFromQueue(th, readyQueue)
    currentThread = th

  of (tsRunning, tsBlocked):
    blockedQueue.push(th)

  of (tsRunning, tsSleeping):
    let sleeper = SleepingThread(thread: th, sleepUntil: event.sleepUntil)
    sleepingQueue.push(sleeper)

  of (tsRunning, tsWaiting):
    waitingQueue.push(th)

  of (_, tsTerminated):
    case th.state:
    of tsReady: removeFromQueue(th, readyQueue)
    of tsBlocked: removeFromQueue(th, blockedQueue)
    of tsSleeping: removeFromQueue(th, sleepingQueue)
    of tsWaiting: removeFromQueue(th, waitingQueue)
    else: discard

  else:
    debugln(&"threaddef.transitionTo: invalid transition from {th.state} to {event.toState}")
    return false

  th.state = event.toState
  return true


####################################################################################################
# Main scheduler routine

proc wakeup*(th: Thread)  # forward declaration

proc schedule*() {.cdecl.} =
  # wake up sleeping threads that have their sleep time elapsed
  if sleepingQueue.len > 0:
    # the queue is ordered by sleepUntil, so we can stop at the first thread that is not due yet
    while sleepingQueue.len > 0 and sleepingQueue[0].sleepUntil <= getTimerTicks():
      var sleeper = sleepingQueue.pop()
      wakeup(sleeper.thread)

  # get highest priority thread
  if readyQueue.len > 0:
    var thNext = readyQueue.pop()

    if currentThread.state == tsTerminated:
      become(thNext)

    if thNext.priority >= currentThread.priority or currentThread.state notin {tsReady, tsRunning}:
      # switch to new thread
      if currentThread.state == tsRunning:
        discard transitionTo(currentThread, TransitionEvent(toState: tsReady))
      thNext.state = tsRunning
      var thTemp = currentThread
      currentThread = thNext
      debugln(&"sched.schedule: switching from id={thTemp.id}, name={thTemp.name} to id={thNext.id}, name={thNext.name}")
      switchToThread(thTemp, thNext)
    else:
      # no switch, put thread back into ready queue
      readyQueue.push(thNext)


####################################################################################################
# API for managing current thread

proc sleep*(ticks: uint64) =
  if ticks == 0:
    return
  let sleepUntil = getTimerTicks() + ticks
  if transitionTo(currentThread, TransitionEvent(toState: tsSleeping, sleepUntil: sleepUntil)):
    debugln(&"sched.sleep: id={currentThread.id}, name={currentThread.name}, until={sleepUntil}")
    schedule()

proc wait*() =
  if transitionTo(currentThread, TransitionEvent(toState: tsWaiting)):
    debugln(&"sched.wait: id={currentThread.id}, name={currentThread.name}")
    schedule()

# proc join*(th: Thread) =
#   while th.state != tsTerminated:
#     th.finished.wait()

proc terminate*() =
  if transitionTo(currentThread, TransitionEvent(toState: tsTerminated)):
    debugln(&"sched.terminate: id={currentThread.id}, name={currentThread.name}")
    schedule()


####################################################################################################
# API for managing other threads

proc start*(th: Thread) =
  if transitionTo(th, TransitionEvent(toState: tsReady)):
    debugln(&"sched.start: {th.id=}, name={th.name=}")

proc wakeup*(th: Thread) =
  if transitionTo(th, TransitionEvent(toState: tsReady)):
    debugln(&"sched.wakeup: {th.id=}, {th.name=}")

proc signal*(th: Thread) =
  if transitionTo(th, TransitionEvent(toState: tsReady)):
    debugln(&"sched.signal: {th.id=}, {th.name=}")

proc stop*(th: Thread) =
  if transitionTo(th, TransitionEvent(toState: tsTerminated)):
    debugln(&"sched.stop: {th.id=}, {th.name=}")


####################################################################################################
# Initialization

proc timerCallback() {.cdecl.} =
  schedule()

proc init*(initalThread: Thread) =
  debugln("sched: Registering timer callback")
  let timerIndex = timer.registerTimerCallback(timerCallback)
  if timerIndex == -1:
    debugln("sched: Failed to register timer callback")
    quit(1)

  become(initalThread)
