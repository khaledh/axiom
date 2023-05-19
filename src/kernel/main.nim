import ../boot/uefitypes
import acpi, acpi/madt
import idt
import ioapic
import lapic
import sched
import thread
import timer

import devices/bga
import devices/console
import devices/cpu
import devices/keyboard
import devices/pic

import debug
import interrupt
import ../graphics/font
import ../graphics/framebuffer
import ../lib/[libc, malloc]
import ../shell


proc init*(sysTable: ptr EfiSystemTable) =
  #############################################
  ##  Exit UEFI Boot Services

  # let status = sysTable.bootServices.exitBootServices(imageHandle, memoryMapKey)

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

  debugln("boot: Disabling PIC")
  pic.disable()

  debugln("boot: Initializing IDT")
  idt.init()

  interrupt.init()

  #############################################
  ##  Setup keyboard

  debugln("boot: Initializing keyboard")
  keyboard.init(console.keyEventHandler)

  #############################################
  ## Setup timer

  debugln("boot: Initializing timer")
  timer.init()

  #############################################
  ##  Welcome to Axiom

  writeln("""    _          _                    ___  ____  """, 0xa0caef)
  writeln("""   / \   __  _(_) ___  _ __ ___    / _ \/ ___| """, 0xa0caef)
  writeln("""  / _ \  \ \/ / |/ _ \| '_ ` _ \  | | | \___ \ """, 0xa0caef)
  writeln(""" / ___ \  >  <| | (_) | | | | | | | |_| |___) |""", 0xa0caef)
  writeln("""/_/   \_\/_/\_\_|\___/|_| |_| |_|  \___/|____/ """, 0xa0caef)
  writeln("")
  writeln("Welcome to AxiomOS")
  writeln("")

  #############################################
  ##  Start scheduler

  thread.init(sched.schedule, sched.transitionTo)

  debugln("boot: Creating idle thread")
  var idleThread = createThread(idle, ThreadPriority.low, "idle")

  debugln("boot: Creating shell thread")
  shell.init(sysTable)
  createThread(shell.start, name = "shell").start()

  debugln("boot: Done; starting idle thread")
  # this should be the last thing we do; this call does not return
  sched.init(idleThread)
