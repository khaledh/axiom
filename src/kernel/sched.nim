import std/[heapqueue, strformat]

import devices/console
import threaddef
import timer


proc showThread(th: Thread) =
  writeln(&"  id={th.id}, addr={cast[uint64](th):x}h, state={th.state:<10}, priority={th.priority:>2}, name={th.name}")


proc showThreads*() =
  writeln("")

  writeln("Current:")
  showThread(thCurr)

  if readyQueue.len > 0:
    writeln("Ready:")
    for i in 0 ..< readyQueue.len:
      showThread(readyQueue[i])

  if blockedQueue.len > 0:
    writeln("Blocked:")
    for i in 0 ..< blockedQueue.len:
      showThread(blockedQueue[i])

  if sleepingQueue.len > 0:
    writeln("Sleeping:")
    for i in 0 ..< sleepingQueue.len:
      showThread(sleepingQueue[i])
      writeln(&"    sleep until: {sleepingQueue[i].sleepUntil}")


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
