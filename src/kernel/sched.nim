import std/[heapqueue, strformat, strutils]

import threaddef
import timer
import ../kernel/debug


var
  thCurr*: Thread
  readyQueue*: HeapQueue[Thread]
  blockedQueue*: HeapQueue[Thread]
  sleepingQueue*: HeapQueue[Thread]


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
  thCurr = thread
  thCurr.state = tsRunning

  asm """
    mov rsp, %0
    jmp resumeThread
    :
    :"g"(`thread`->rsp)
  """

proc getCurrentThread*(): Thread {.inline.} =
  result = thCurr

proc removeFromQueue(th: Thread, queue: var HeapQueue) =
  let idx = queue.find(th)
  if idx >= 0:
    queue.del(idx)

proc schedule*(newState: ThreadState) {.cdecl.} =
  thCurr.state = newState

  case newState:
  of tsReady:
    readyQueue.push(thCurr)
  of tsBlocked:
    blockedQueue.push(thCurr)
  of tsSleeping:
    sleepingQueue.push(thCurr)
  else: discard

  var toWakeUp: seq[Thread]
  for i in 0 ..< sleepingQueue.len:
    let thSleeping = sleepingQueue[i]
    if thSleeping.sleepUntil > 0 and thSleeping.sleepUntil <= getTimerTicks():
      toWakeUp.add(thSleeping)

  for th in toWakeUp:
    debugln(&"sched.schedule: th={th.id}, name={th.name}, wait expired")
    th.sleepUntil = 0
    th.state = tsReady
    removeFromQueue(th, sleepingQueue)
    readyQueue.push(th)

  # get highest priority thread
  if readyQueue.len > 0:
    var thNext = readyQueue.pop()
    thNext.state = tsRunning

    if newState == tsTerminated:
      become(thNext)

    if thNext.id != thCurr.id and (thNext.priority >= thCurr.priority or thCurr.state != tsReady):
      var thTemp = thCurr
      thCurr = thNext
      switchToThread(thTemp, thNext)


proc start*(thread: Thread) =
  debugln(&"sched.start: id={thread.id}, name={thread.name}")
  thread.state = tsReady
  readyQueue.push(thread)


proc sleep*() =
  debugln(&"sched.sleep: id={thCurr.id}, name={thCurr.name}")
  schedule(tsSleeping)


proc sleep*(ticks: uint64) =
  thCurr.sleepUntil = timerTicks + ticks
  debugln(&"sched.sleep: id={thCurr.id}, name={thCurr.name}, until={thCurr.sleepUntil}")
  schedule(tsSleeping)


proc wakeup*(th: Thread) =
  if th.state == tsSleeping:
    debugln("sched.wakeup: th=", $th.id, ", removing from sleepingQueue")
    removeFromQueue(th, sleepingQueue)
    debugln("sched.wakeup: th=", $th.id, ", sleepingQueue.len=", $sleepingQueue.len)
    th.sleepUntil = 0
    th.state = tsReady
    debugln("sched.wakeup: th=", $th.id, ", adding to readyQueue")
    readyQueue.push(th)

proc stop*(th: Thread) =
  debugln(&"sched.stop: terminating thread id={th.id}, name={th.name}")
  removeFromQueue(th, readyQueue)
  removeFromQueue(th, blockedQueue)
  removeFromQueue(th, sleepingQueue)
  th.state = tsTerminated

# proc join*(th: Thread) =
#   while th.state != tsTerminated:
#     th.finished.wait()


proc init*() =
  thCurr = nil
