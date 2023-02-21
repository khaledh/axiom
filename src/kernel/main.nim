import std/strformat

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

import devices/bxvbe
import devices/console
import devices/keyboard
import devices/pic

import ../debug
import ../font
import ../framebuffer
import ../lib/[libc, malloc]
import ../shell


proc init*(sysTable: ptr EfiSystemTable) =
  # BGA (Bochs Graphics Adapter)
  let bgaId = bgaReadRegister(BxvbePortIndexId)
  println(&"BGA ID = {bgaId:0>4x}")

  bgaSetVideoMode(1280, 1024, 32)

  let virtWidth = bgaReadRegister(BxvbePortIndexVirtWidth)
  let virtHeight = bgaReadRegister(BxvbePortIndexVirtHeight)
  println(&"BGA VirtualRes = {virtWidth}x{virtHeight}")

  var fb = framebuffer.init(BxvbeLfbPhysicalAddress, width = 1280, height = 1024)

  var fnt = loadFont16()

  # let consoleBkColor = 0x2d363d'u32
  # let consoleBkColor = 0x1d262d'u32
  # let consoleBkColor = 0x0d161d'u32
  let consoleBkColor = 0x26486B'u32

  # clear background
  fb.clear(consoleBkColor)

  console.init(fb, left = 8, top = 16, font = fnt, maxCols = 158, maxRows = 62,
    color = consoleBkColor)

  writeln("""    _          _                    ___  ____  """, 0xa0caef)
  writeln("""   / \   __  _(_) ___  _ __ ___    / _ \/ ___| """, 0xa0caef)
  writeln("""  / _ \  \ \/ / |/ _ \| '_ ` _ \  | | | \___ \ """, 0xa0caef)
  writeln(""" / ___ \  >  <| | (_) | | | | | | | |_| |___) |""", 0xa0caef)
  writeln("""/_/   \_\/_/\_\_|\___/|_| |_| |_|  \___/|____/ """, 0xa0caef)
  writeln("")


  loadFont()

  ##  ACPI
  acpi.init(sysTable)

  #############################################
  ##  Setup interrupts

  ##  Local APICs
  lapic.init()

  ## I/O APIC
  ioapic0 = ioapic.init(madt0)
  # set keyboard interrupt: interrupt input 1 => vector 21h
  ioapic0.setRedirEntry(1, 0x21)

  pic.disable()
  idt.init()

  keyboard.init(keyHandler)
  timer.init()

  shell.init(sysTable)

  writeln("Welcome to AxiomOS")
  writeln("")
  write("] ")

  sched.init()

  # let t1 = createThread(shell.start)

  # createThread(spinner).start()

  # idle thread
  var t0 = createThread(idle, ThreadPriority.low)
  jumpToThread(t0)


  # setInterruptHandler(0, isr00)
  # asm """
  #   mov rcx, 0
  #   div rcx
  # """
