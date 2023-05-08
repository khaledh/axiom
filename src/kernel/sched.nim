import std/[heapqueue, strformat]

import devices/console
import threaddef
import timer


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

  for i in 0 ..< sleepingQueue.len:
    var thSleeping = sleepingQueue[i]
    if thSleeping.sleepUntil <= getTimerTicks():
      discard sleepingQueue.pop()
      thSleeping.sleepUntil = 0
      thSleeping.state = tsReady
      readyQueue.push(thSleeping)

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
  thread.state = tsReady
  readyQueue.push(thread)


proc sleep*(ticks: uint64) =
  thCurr.sleepUntil = timerTicks + ticks
  schedule(tsSleeping)


proc init*() =
  thCurr = nil
