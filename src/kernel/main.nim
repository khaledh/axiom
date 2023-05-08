import ../boot/uefitypes
import acpi, acpi/madt
import cpu
import idt
import ioapic
import lapic
import sched
import thread
import threaddef
import timer

import devices/bga
import devices/console
import devices/keyboard
import devices/pic

import ../graphics/font
import ../graphics/framebuffer
import ../lib/[libc, malloc]
import ../shell


const BgColor = 0x26486B'u32


proc spinner() {.cdecl.} =
  const spinner = ['-', '\\', '|', '/']
  var index = 0

  while true:
      putCharAt(spinner[index mod len(spinner)], 61, 156)
      inc index
      sleep(50)


proc init*(sysTable: ptr EfiSystemTable) =
  #############################################
  ##  Initialize graphics

  bga.init()

  #############################################
  ##  Initialize framebuffer

  var fb = framebuffer.init(BgaLfbPhysicalAddress, width = 1280, height = 1024)
  fb.clear(BgColor)

  #############################################
  ##  Initialize console

  let font = loadFont()
  console.init(fb, left = 8, top = 16, font = font, maxCols = 158, maxRows = 62, color = BgColor)

  writeln("""    _          _                    ___  ____  """, 0xa0caef)
  writeln("""   / \   __  _(_) ___  _ __ ___    / _ \/ ___| """, 0xa0caef)
  writeln("""  / _ \  \ \/ / |/ _ \| '_ ` _ \  | | | \___ \ """, 0xa0caef)
  writeln(""" / ___ \  >  <| | (_) | | | | | | | |_| |___) |""", 0xa0caef)
  writeln("""/_/   \_\/_/\_\_|\___/|_| |_| |_|  \___/|____/ """, 0xa0caef)
  writeln("")
  writeln("Welcome to AxiomOS")
  writeln("")
  write("] ")

  #############################################
  ##  Initialize ACPI

  acpi.init(sysTable)

  #############################################
  ##  Setup interrupts

  #  Local APICs
  lapic.init()

  # I/O APIC
  ioapic0 = ioapic.init(madt0)
  # set keyboard interrupt: interrupt input 1 => vector 21h
  ioapic0.setRedirEntry(irq = 1, vector = 0x21)

  pic.disable()
  idt.init()

  # setInterruptHandler(0, isr00)
  # asm """
  #   mov rcx, 0
  #   div rcx
  # """

  #############################################
  ##  Setup devices

  keyboard.init(keyHandler)

  #############################################
  ## Setup timer

  proc timerCallback() {.cdecl.} =
    # writeln("timerCallback")
    sched.schedule(tsReady)

  timer.init()
  let timerIndex = timer.registerTimerCallback(timerCallback)
  if timerIndex == -1:
    writeln("Failed to register timer callback")
    quit(1)

  #############################################
  ##  Bring the rest of the kernel up

  sched.init()

  shell.init(sysTable)
  # let t1 = createThread(shell.start)

  #############################################
  ##  Exit UEFI Boot Services

  # let status = sysTable.bootServices.exitBootServices(imageHandle, memoryMapKey)

  #############################################
  ##  Start idle thread

  var idleThread = createThread(idle, ThreadPriority.low, "idle")

  createThread(spinner, name = "spinner").start()

  jumpToThread(idleThread)
