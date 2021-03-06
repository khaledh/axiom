import console
import cpu
import sched
import threaddef


var
  nextAvailableId: uint64

proc kernelThread(function: ThreadFunc) =
  # writeln("starting thread")
  function()

  disableInterrupts()

  if thCurr.next == thCurr:
    writeln("Halt")
    halt()

  # let thTemp = thCurr
  # thCurr = thCurr.prev
  # terminateThread(thTemp)
  write("(k)")
  # halt()
  # thCurr.state = tsTerminated
  # writeln(&"thCurr.id: {thCurr.id}, thCurr.state: {thCurr.state}")

  # writeln(&"thread {thCurr.id} terminated")
  schedule(tsTerminated)

proc createThread*(function: ThreadFunc, priority: ThreadPriority = 0): Thread =
  # if nextAvailableId >= len(threads).uint64:
  #   return nil

  var thNew = new(Thread)
  thNew.id = nextAvailableId; inc(nextAvailableId)
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
  # writeln(&"kernelThread @ {cast[uint64](kernelThread):x}")

  result = thNew

proc sleep*() =
  schedule(tsBlocked)

proc initThreads*() =
  nextAvailableId = 0
