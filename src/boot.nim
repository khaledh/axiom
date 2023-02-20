import std/strformat

import acpi, acpi/madt
import bxvbe
import console
import cpu
import debug
import font
import framebuffer
import idt
import ioapic
import keyboard
import lapic
import pic
import shell
import sched
import thread
import threaddef
import timer
import uefi, uefitypes
import lib/[libc, malloc]


proc printError(msg: string) {.gcsafe.} =
  writeln("Unhandled Exception")
  writeln(msg)

proc handleUnhandledException(e: ref Exception) {.tags: [], raises: [].} =
  printError(e.msg)

errorMessageWriter = printError
unhandledExceptionHook = handleUnhandledException

proc spinner() {.cdecl.} =
  const spinner = ['-', '\\', '|', '/']
  var index = 0

  while true:
    # if ticks mod 250_000 == 0:
      putCharAt(spinner[index mod len(spinner)], 61, 156)
      inc index
      sleep()
    # inc ticks
    # asm "pause"

proc NimMain() {.cdecl, importc.}

proc efiMain*(imageHandle: EfiHandle, systemTable: ptr EfiSystemTable): uint {.exportc.} =
  NimMain()

  var sysTable = systemTable

  initDebug(sysTable.conOut)

  discard sysTable.conOut.setMode(sysTable.conOut, 2)

  # discard sysTable.conOut.clearScreen(systemTable.conOut)
  # discard sysTable.conOut.enableCursor(systemTable.conOut, true)
  # discard sysTable.conOut.enableCursor(systemTable.conOut, false)

  # when false:

  # let GOP_GUID = parseGuid("9042a9de-23dc-4a38-fb96-7aded080516a")
  # var igop: pointer
  # discard sysTable.bootServices.locateProtocol(unsafeAddr GOP_GUID, nil, addr igop)
  # var gop = cast[ptr EfiGraphicsOutputProtocol](igop)
  # showGop(gop)

  # discard gop.setMode(gop, 14)  # 1280x1024
  # var fb = initFramebuffer(gop.mode.frameBufferBase, width=1280, height=1024)

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

  #############################################
  ##  Exit UEFI Boot Services

  # let ebsStatus = sysTable.bootServices.exitBootServices(imageHandle, memoryMapKey)
