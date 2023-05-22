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
import ../gui/graphics
import ../gui/view
import ../lib/[libc, malloc]
import ../shell

const
  XResolution = 1600
  YResolution = 1200

proc init*(sysTable: ptr EfiSystemTable) =
  #############################################
  ##  Exit UEFI Boot Services

  # let status = sysTable.bootServices.exitBootServices(imageHandle, memoryMapKey)

  debugln("[boot] Axiom OS starting")

  #############################################
  ##  Initialize ACPI

  debugln("[boot] Initializing ACPI")
  acpi.init(sysTable)

  #############################################
  ##  Setup interrupts

  #  Local APICs
  debugln("[boot] Initializing LAPIC")
  lapic.init()

  # I/O APIC
  debugln("[boot] Initializing IOAPIC")
  ioapic0 = ioapic.init(madt0)

  debugln("[boot] Disabling PIC")
  pic.disable()

  debugln("[boot] Initializing IDT")
  idt.init()

  interrupt.init()

  #############################################
  ##  Setup keyboard

  debugln("[boot] Initializing keyboard")
  keyboard.init(console.keyEventHandler)

  #############################################
  ## Setup timer

  debugln("[boot] Initializing timer")
  timer.init()

  #############################################
  ##  Initialize graphics

  bga.init(xres = XResolution, yres = YResolution)

  #############################################
  ##  Initialize framebuffer

  var fb = framebuffer.init(BgaLfbPhysicalAddress, width = XResolution, height = YResolution)
  fb.clear()

  graphics.init(fb)
  view.init()

  #############################################
  ##  Start scheduler

  thread.init(sched.schedule, sched.transitionTo)

  debugln("[boot] Creating idle thread")
  var idleThread = createThread(idle, ThreadPriority.low, "idle")

  debugln("[boot] Creating shell thread")
  shell.init(sysTable)
  createThread(shell.start, name = "shell").start()

  debugln("Creating graphics thread")
  createThread(graphics.start, name = "graphics").start()

  #############################################
  ##  Initialize console

  let font = loadFont()
  console.init(maxCols = 150, maxRows = 60, font = font)

  writeln("""    _          _                    ___  ____  """, 0xa0caef)
  writeln("""   / \   __  _(_) ___  _ __ ___    / _ \/ ___| """, 0xa0caef)
  writeln("""  / _ \  \ \/ / |/ _ \| '_ ` _ \  | | | \___ \ """, 0xa0caef)
  writeln(""" / ___ \  >  <| | (_) | | | | | | | |_| |___) |""", 0xa0caef)
  writeln("""/_/   \_\/_/\_\_|\___/|_| |_| |_|  \___/|____/ """, 0xa0caef)
  writeln("")
  writeln("Welcome to AxiomOS")
  writeln("")


  debugln("[boot] Done; starting idle thread")
  # this should be the last thing we do; this call does not return
  sched.init(idleThread)
