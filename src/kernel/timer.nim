import idt, lapic

type
  TimerCallback* = proc () {.cdecl.}

var
  timerTicks*: uint64 = 0
  timerCallbacks: array[16, TimerCallback]


proc timerInterruptHandler*(intFrame: pointer)
    {.cdecl, codegenDecl: "__attribute__ ((interrupt)) $# $#$#".} =

  inc timerTicks

  lapic.eoi()

  if timerTicks mod 10 == 0:
    for i in 0 .. timerCallbacks.high:
      if not isNil(timerCallbacks[i]):
        timerCallbacks[i]()


proc init*() =
  idt.setInterruptHandler(0x20, timerInterruptHandler)
  lapic.setTimer(0x20)


proc registerTimerCallback*(callback: TimerCallback): int =
  for i in 0 .. timerCallbacks.high:
    if isNil(timerCallbacks[i]):
      timerCallbacks[i] = callback
      return i
  return -1


proc getTimerTicks*(): uint64 =
  result = timerTicks
