import std/strformat

import devices/cpu
import sched
import threaddef
import ../kernel/debug

var
  nextAvailableId: uint64 = 0

proc kernelThread(function: ThreadFunc) =
  function()

  disableInterrupts()

  if getCurrentThread().next == getCurrentThread():
    debugln("Halt")
    halt()

  schedule(tsTerminated)

proc createThread*(function: ThreadFunc, priority: ThreadPriority = 0, name: string = ""): Thread =
  let id = nextAvailableId
  inc nextAvailableId

  debugln(&"thread: creating new thread: id={id}, name='{name}', pri={priority}")

  var thNew = new(Thread)
  thNew.id = id
  thNew.name = name
  thNew.state = tsNew
  thNew.priority = priority
  thNew.prev = nil
  thNew.next = nil

  thNew.stack = new(ThreadStack)
  thNew.rsp = cast[uint64](thNew.stack) + sizeof(ThreadStackArray).uint64 - sizeof(SwitchStack).uint64 - 128

  var ss = cast[ptr SwitchStack](thNew.rsp)
  zeroMem(ss, sizeof(SwitchStack))
  ss.rcx = cast[uint64](function)
  ss.rip = cast[uint64](kernelThread)

  result = thNew
