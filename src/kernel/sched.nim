import std/[heapqueue, sequtils, strformat, strutils]

import devices/cpu
import threaddef
import timer
import ../kernel/debug


proc removeFromQueue(th: Thread, queue: var HeapQueue) =
  let idx = queue.find(th)
  # debugln(&"sched.removeFromQueue: id={th.id}, idx={idx}")
  if idx >= 0:
    # debugln(&"sched.removeFromQueue: queue=[{$queue}] (before)")
    queue.del(idx)
    # debugln(&"sched.removeFromQueue: queue=[{$queue}] (after)")


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
      jumpToThread(thNext)

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


proc init*() =
  thCurr = nil
