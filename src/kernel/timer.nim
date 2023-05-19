import idt, lapic

import debug

type
  TimerCallback* = proc () {.cdecl.}

var
  timerTicks*: uint64 = 0
  timerCallbacks: array[16, TimerCallback]


proc timerInterruptHandler*(intFrame: ptr InterruptFrame)
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


proc registerTimerCallback*(callback: TimerCallback) =
  for i in 0 .. timerCallbacks.high:
    if isNil(timerCallbacks[i]):
      timerCallbacks[i] = callback
      return

  debugln("sched: Failed to register timer callback")
  quit(1)


proc getTimerTicks*(): uint64 =
  result = timerTicks
