import std/[heapqueue, strformat, strutils]

import threaddef
import timer
import ../kernel/debug


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

proc removeFromQueue(th: Thread, queue: var HeapQueue[SleepingThread]): SleepingThread =
  for i in 0 ..< queue.len:
    let sleeper = queue[i]
    if sleeper.thread.id == th.id:
      queue.del(i)
      return sleeper


####################################################################################################
# Scheduler main routine

proc wakeup*(th: Thread)  # forward declaration

proc schedule*() {.cdecl.} =

  if sleepingQueue.len > 0:
    while sleepingQueue.len > 0 and sleepingQueue[0].sleepUntil > 0 and sleepingQueue[0].sleepUntil <= getTimerTicks():
      var sleeper = sleepingQueue.pop()
      wakeup(sleeper.thread)

  # get highest priority thread
  if readyQueue.len > 0:
    debugln(&"sched.schedule: readyQueue.len={readyQueue.len}")
    var thNext = readyQueue[0]
    debugln(&"sched.schedule: {currentThread.id=}, {currentThread.name=}, {currentThread.priority=}, {currentThread.state=}")
    debugln(&"sched.schedule: {thNext.id=}, {thNext.name=}, {thNext.priority=}, {thNext.state=}")

    if currentThread.state == tsTerminated:
      readyQueue.del(0)
      become(thNext)

    if thNext.priority >= currentThread.priority or currentThread.state notin {tsReady, tsRunning}:
      readyQueue.del(0)
      if currentThread.state == tsRunning:
        currentThread.state = tsReady
        readyQueue.push(currentThread)
      thNext.state = tsRunning
      var thTemp = currentThread
      currentThread = thNext
      debugln(&"sched.schedule: switching from id={thTemp.id}, name={thTemp.name} to id={thNext.id}, name={thNext.name}")
      switchToThread(thTemp, thNext)
    
    currentThread.state = tsRunning


####################################################################################################
# API for managing current thread

proc sleep*(ticks: uint64) =
  currentThread.state = tsSleeping
  var sleeper = SleepingThread(
    thread: currentThread,
    sleepUntil: getTimerTicks() + ticks
  )
  sleepingQueue.push(sleeper)
  debugln(&"sched.sleep: id={sleeper.thread.id}, name={sleeper.thread.name}, until={sleeper.sleepUntil}")
  schedule()

proc wait*() =
  debugln(&"sched.wait: id={currentThread.id}, name={currentThread.name}")
  currentThread.state = tsWaiting
  waitingQueue.push(currentThread)
  schedule()

# proc join*(th: Thread) =
#   while th.state != tsTerminated:
#     th.finished.wait()

proc terminate*() =
  debugln(&"sched.stop: terminating thread id={currentThread.id}, name={currentThread.name}")
  currentThread.state = tsTerminated
  schedule()


####################################################################################################
# API for managing other threads

proc start*(thread: Thread) =
  debugln(&"sched.start: id={thread.id}, name={thread.name}")
  thread.state = tsReady
  readyQueue.push(thread)

proc wakeup*(th: Thread) =
  if th.state == tsSleeping:
    debugln("sched.wakeup: th=", $th.id, ", removing from sleepingQueue")
    discard removeFromQueue(th, sleepingQueue)
    debugln("sched.wakeup: th=", $th.id, ", sleepingQueue.len=", $sleepingQueue.len)
    th.state = tsReady
    debugln("sched.wakeup: th=", $th.id, ", adding to readyQueue")
    readyQueue.push(th)

proc signal*(th: Thread) =
  debugln(&"sched.signal: id={th.id}, name={th.name}")
  removeFromQueue(th, waitingQueue)
  th.state = tsReady
  readyQueue.push(th)

proc stop*(th: Thread) =
  debugln(&"sched.stop: terminating thread id={th.id}, name={th.name}")
  removeFromQueue(th, readyQueue)
  removeFromQueue(th, blockedQueue)
  discard removeFromQueue(th, sleepingQueue)
  th.state = tsTerminated


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
