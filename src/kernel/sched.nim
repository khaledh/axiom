import std/heapqueue
import std/strformat
import std/tables
import fusion/matching
{.experimental: "caseStmtMacros".}

import debug
import thread
import timer

{.experimental: "codeReordering".}

var
  ready*: HeapQueue[Thread]
  sleeping*: HeapQueue[SleepingThread]
  waiting*: Table[uint64, WaitingThread]


####################################################################################################
# Helper functions

proc removeFromQueue(th: Thread, queue: var HeapQueue) =
  let idx = queue.find(th)
  if idx >= 0:
    queue.del(idx)

type SpecialThread = SleepingThread | WaitingThread

proc removeFromQueue(th: Thread, queue: var HeapQueue[SpecialThread]) =
  for i in 0 ..< queue.len:
    let sleeper = queue[i]
    if sleeper.thread.id == th.id:
      queue.del(i)
      return


####################################################################################################
# Thread state machine transitions

proc transitionTo*(th: Thread, event: ThreadTransition): bool {.cdecl.} =
  if th.state == event.toState:
    return false

  case (th.state, event.toState):
  of (tsNew, tsReady):
    ready.push(th)

  of (tsRunning, tsReady):
    ready.push(th)

  of (tsSleeping, tsReady):
    removeFromQueue(th, sleeping)
    ready.push(th)

  of (tsWaiting, tsReady):
    waiting.del(th.id)
    ready.push(th)

  of (tsReady, tsRunning):
    removeFromQueue(th, ready)
    currentThread = th

  of (tsRunning, tsSleeping):
    let sleeper = SleepingThread(thread: th, sleepUntil: event.sleepUntil)
    sleeping.push(sleeper)

  of (tsRunning, tsWaiting):
    let waiter = WaitingThread(thread: th, cond: event.condition)
    waiting[th.id] = waiter

  of (_, tsTerminated):
    case th.state:
    of tsReady: removeFromQueue(th, ready)
    of tsSleeping: removeFromQueue(th, sleeping)
    of tsWaiting: waiting.del(th.id)
    else: discard

    if terminateConds.hasKey(th.id):
      let cond = terminateConds[th.id]
      cond.broadcast()
      terminateConds.del(th.id)

  else:
    debugln(&"sched.transitionTo: thread id={th.id} invalid transition from {th.state} to {event.toState}")
    return false

  th.state = event.toState
  return true


####################################################################################################
# Main scheduler routine

proc schedule*() {.cdecl.} =
  # the queue is ordered by sleepUntil, so we can stop at the first thread that is not due yet
  while sleeping.len > 0 and sleeping[0].sleepUntil <= getTimerTicks():
    discard transitionTo(sleeping[0].thread, ThreadTransition(toState: tsReady))

  # get highest priority thread
  if ready.len > 0:
    var thNext = ready.pop()

    if currentThread.state == tsTerminated:
      become(thNext)

    if thNext.priority >= currentThread.priority or currentThread.state notin {tsReady, tsRunning}:
      # switch to new thread
      if currentThread.state == tsRunning:
        discard transitionTo(getCurrentThread(), ThreadTransition(toState: tsReady))
      thNext.state = tsRunning
      var thTemp = currentThread
      currentThread = thNext
      # debugln(&"sched.schedule: switching from id={thTemp.id}, name={thTemp.name} to id={thNext.id}, name={thNext.name}")
      switchToThread(thTemp, thNext)
    else:
      # no switch, put thread back into ready queue
      ready.push(thNext)


####################################################################################################
# Initialization

proc timerCallback() {.cdecl.} =
  schedule()

proc init*(initalThread: Thread) =
  debugln("sched: Registering timer callback")
  timer.registerTimerCallback(timerCallback)

  debugln("sched: Jumping to inital thread")
  become(initalThread)


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
