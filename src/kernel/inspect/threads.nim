import std/strformat
import std/heapqueue

import ../threaddef
import ../devices/console


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
