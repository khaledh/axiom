import std/strformat
import std/heapqueue
import std/tables

import ../sched {.all.}
import ../thread
import ../devices/console


proc showThread(th: Thread) =
  writeln(&"  id={th.id}, addr={cast[uint64](th):x}h, state={th.state:<10}, priority={th.priority:>2}, name={th.name}")


proc showThreads*() =
  writeln("")

  writeln("Current:")
  showThread(getCurrentThread())

  if ready.len > 0:
    writeln("Ready:")
    for i in 0 ..< ready.len:
      showThread(ready[i])

  if waiting.len > 0:
    writeln("Waiting:")
    for waiter in waiting.values:
      showThread(waiter.thread)

  if sleeping.len > 0:
    writeln("Sleeping:")
    for i in 0 ..< sleeping.len:
      showThread(sleeping[i].thread)
      writeln(&"    sleep until: {sleeping[i].sleepUntil}")
