import std/[heapqueue, strformat]

import devices/console
import threaddef

proc schedule*(newState: ThreadState) =
  # writeln(&"(s:{thCurr.id})")
  # showThreads()
  # writeln(&"thCurr.id: {thCurr.id:x}h, thCurr @ {cast[uint64](thCurr):x}")

  thCurr.state = newState

  case newState:
  of tsReady: readyQueue.push(thCurr)
  of tsBlocked: blockedQueue.push(thCurr)
  else: discard

  # get highest priority thread
  if readyQueue.len > 0:
    var thNext = readyQueue.pop()
    thNext.state = tsRunning

    # writeln(&"=> thNext.id: {thNext.id}, thNext.state: {thNext.state}")

    # if thCurr.state == tsTerminated:
    #   halt()
    # if thNext == thCurr:
    #   # same thread, no context switch
    #   return

    if newState == tsTerminated:
      jumpToThread(thNext)
    elif thNext.id != thCurr.id and thNext.priority >= thCurr.priority:
      var thTemp = thCurr
      thCurr = thNext
      contextSwitch(thTemp, thNext)


proc start*(thread: Thread) =
  thread.state = tsReady
  readyQueue.push(thread)

  # showThreads()

# proc terminateThread(thread: Thread) =
#   thread.state = tsTerminated

#   if thHead == thread:
#     thHead = thread.next
#   if thTail == thread:
#     thTail = thread.prev

#   thread.prev.next = thread.next
#   thread.next.prev = thread.prev

proc showThread(th: Thread) =
  writeln(&"  id={th.id}, addr={cast[uint64](th):x}h, state={th.state}, priority={th.priority}")

proc showThreads*() =
  writeln("")

  writeln("Running:")
  showThread(thCurr)

  if readyQueue.len > 0:
    writeln("Ready:")
    for i in 0 ..< readyQueue.len:
      showThread(readyQueue[i])

  if blockedQueue.len > 0:
    writeln("Blocked:")
    for i in 0 ..< blockedQueue.len:
      showThread(blockedQueue[i])

proc init*() =
  thCurr = nil
