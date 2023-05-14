import std/[heapqueue, strformat, strutils]

import threaddef
import timer
import ../kernel/debug


var
  currentThread*: Thread
  readyQueue*: HeapQueue[Thread]
  blockedQueue*: HeapQueue[Thread]
  sleepingQueue*: HeapQueue[SleepingThread]


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

proc getCurrentThread*(): Thread {.inline.} =
  result = currentThread

proc removeFromQueue(th: Thread, queue: var HeapQueue) =
  let idx = queue.find(th)
  if idx >= 0:
    queue.del(idx)

proc removeFromQueue(th: Thread, queue: var HeapQueue[SleepingThread]): SleepingThread =
  for i in 0 ..< queue.len:
    let sleeper = queue[i]
    if sleeper.thread.id == th.id:
      queue.del(i)
      return sleeper

proc schedule*(newState: ThreadState) {.cdecl.} =
  currentThread.state = newState

  case newState:
  of tsReady:
    readyQueue.push(currentThread)
  of tsBlocked:
    blockedQueue.push(currentThread)
  # of tsSleeping:
  #   sleepingQueue.push(currentThread)
  else: discard

  var toWakeUp: seq[SleepingThread]
  for i in 0 ..< sleepingQueue.len:
    let thSleeping = sleepingQueue[i]
    if thSleeping.sleepUntil > 0 and thSleeping.sleepUntil <= getTimerTicks():
      toWakeUp.add(thSleeping)

  for th in toWakeUp:
    var thread = th.thread
    debugln(&"sched.schedule: th={thread.id}, name={thread.name}, wait expired")
    th.sleepUntil = 0
    thread.state = tsReady
    discard removeFromQueue(thread, sleepingQueue)
    readyQueue.push(thread)

  # get highest priority thread
  if readyQueue.len > 0:
    var thNext = readyQueue.pop()
    thNext.state = tsRunning

    if newState == tsTerminated:
      become(thNext)

    if thNext.id != currentThread.id and (thNext.priority >= currentThread.priority or currentThread.state != tsReady):
      var thTemp = currentThread
      currentThread = thNext
      switchToThread(thTemp, thNext)


proc start*(thread: Thread) =
  debugln(&"sched.start: id={thread.id}, name={thread.name}")
  thread.state = tsReady
  readyQueue.push(thread)


proc wait*() =
  debugln(&"sched.sleep: id={currentThread.id}, name={currentThread.name}")
  schedule(tsSleeping)


proc sleep*(ticks: uint64) =
  var sleeper = SleepingThread()
  sleeper.thread = currentThread
  sleeper.sleepUntil = timerTicks + ticks
  sleepingQueue.push(sleeper)
  debugln(&"sched.sleep: id={sleeper.thread.id}, name={sleeper.thread.name}, until={sleeper.sleepUntil}")
  schedule(tsSleeping)


proc wakeup*(th: Thread) =
  if th.state == tsSleeping:
    debugln("sched.wakeup: th=", $th.id, ", removing from sleepingQueue")
    discard removeFromQueue(th, sleepingQueue)
    debugln("sched.wakeup: th=", $th.id, ", sleepingQueue.len=", $sleepingQueue.len)
    th.state = tsReady
    debugln("sched.wakeup: th=", $th.id, ", adding to readyQueue")
    readyQueue.push(th)

proc stop*(th: Thread) =
  debugln(&"sched.stop: terminating thread id={th.id}, name={th.name}")
  removeFromQueue(th, readyQueue)
  removeFromQueue(th, blockedQueue)
  discard removeFromQueue(th, sleepingQueue)
  th.state = tsTerminated

# proc join*(th: Thread) =
#   while th.state != tsTerminated:
#     th.finished.wait()


proc timerCallback() {.cdecl.} =
  schedule(tsReady)

proc init*(initalThread: Thread) =
  debugln("sched: Registering timer callback")
  let timerIndex = timer.registerTimerCallback(timerCallback)
  if timerIndex == -1:
    debugln("sched: Failed to register timer callback")
    quit(1)

  become(initalThread)
