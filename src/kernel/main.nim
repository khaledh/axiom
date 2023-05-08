import ../boot/uefitypes
import acpi, acpi/madt
import idt
import ioapic
import lapic
import sched
import thread
import threaddef
import timer

import devices/bga
import devices/console
import devices/cpu
import devices/keyboard
import devices/pic

import ../kernel/debug
import ../graphics/font
import ../graphics/framebuffer
import ../lib/[libc, malloc]
import ../shell


proc init*(sysTable: ptr EfiSystemTable) =
  debugln("boot: Axiom OS starting")

  #############################################
  ##  Initialize graphics

  debugln("boot: Initializing graphics")
  bga.init()

  #############################################
  ##  Initialize framebuffer

  debugln("boot: Initializing framebuffer")
  var fb = framebuffer.init(BgaLfbPhysicalAddress, width = 1280, height = 1024)
  fb.clear()

  #############################################
  ##  Initialize console

  debugln("boot: Loading font")
  let font = loadFont()
  console.init(fb, left = 8, top = 16, font = font, maxCols = 158, maxRows = 62)

  writeln("""    _          _                    ___  ____  """, 0xa0caef)
  writeln("""   / \   __  _(_) ___  _ __ ___    / _ \/ ___| """, 0xa0caef)
  writeln("""  / _ \  \ \/ / |/ _ \| '_ ` _ \  | | | \___ \ """, 0xa0caef)
  writeln(""" / ___ \  >  <| | (_) | | | | | | | |_| |___) |""", 0xa0caef)
  writeln("""/_/   \_\/_/\_\_|\___/|_| |_| |_|  \___/|____/ """, 0xa0caef)
  writeln("")
  writeln("Welcome to AxiomOS")
  writeln("")

  #############################################
  ##  Initialize ACPI

  debugln("boot: Initializing ACPI")
  acpi.init(sysTable)

  #############################################
  ##  Setup interrupts

  #  Local APICs
  debugln("boot: Initializing LAPIC")
  lapic.init()

  # I/O APIC
  debugln("boot: Initializing IOAPIC")
  ioapic0 = ioapic.init(madt0)
  # set keyboard interrupt: interrupt input 1 => vector 21h
  ioapic0.setRedirEntry(irq = 1, vector = 0x21)

  debugln("boot: Disabling PIC")
  pic.disable()

  debugln("boot: Initializing IDT")
  idt.init()

  # setInterruptHandler(0, isr00)
  # asm """
  #   mov rcx, 0
  #   div rcx
  # """

  #############################################
  ##  Setup devices

  debugln("boot: Initializing keyboard")
  keyboard.init(console.keyEventHandler)

  #############################################
  ## Setup timer

  proc timerCallback() {.cdecl.} =
    # writeln("timerCallback")
    sched.schedule(tsReady)

  debugln("boot: Initializing timer")
  timer.init()

  debugln("boot: Registering timer callback")
  let timerIndex = timer.registerTimerCallback(timerCallback)
  if timerIndex == -1:
    writeln("Failed to register timer callback")
    quit(1)

  #############################################
  ##  Bring the rest of the kernel up

  debugln("boot: Initializing scheduler")
  sched.init()

  # let t1 = createThread(shell.start)

  #############################################
  ##  Exit UEFI Boot Services

  # let status = sysTable.bootServices.exitBootServices(imageHandle, memoryMapKey)

  #############################################
  ##  Start idle thread

  debugln("boot: Creating idle thread")
  var idleThread = createThread(idle, ThreadPriority.low, "idle")

  debugln("boot: Initializing shell")
  shell.init(sysTable)
  createThread(shell.start, name = "shell").start()

  debugln("boot: Jumping to idle thread")
  jumpToThread(idleThread)
