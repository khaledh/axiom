import std/strformat

import acpi, acpi/[madt]
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
import shell
import sched
import thread
import threaddef
import timer
import uefi, uefitypes
import lib/[libc, malloc]

var
  sysTable: ptr EfiSystemTable

proc printError(msg: string) {.gcsafe, locks: 0.} =
  writeln(msg)

proc handleUnhandledException(e: ref Exception) {.tags: [], raises: [].} =
  printError(e.msg)

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

proc efiMain*(imageHandle: EfiHandle, systemTable: ptr EfiSystemTable): uint {.exportc.} =
  sysTable = systemTable
  heapBumpPtr = cast[int](addr heap)

  initDebug(sysTable.conOut)

  errorMessageWriter = printError
  unhandledExceptionHook = handleUnhandledException

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

  var fb = initFramebuffer(BxvbeLfbPhysicalAddress, width=1280, height=1024)

  # clear background
  fb.clear(0x2d363d'u32)


  var fnt = loadFont16()
  # let consoleBkColor = 0x2d363d'u32
  # let consoleBkColor = 0x1d262d'u32
  let consoleBkColor = 0x0d161d'u32
  initConsole(fb, left=8, top=16, font=fnt, maxCols=158, maxRows=61, color=consoleBkColor)

  writeln("""    _          _                    ___  ____  """, 0xa0caef)
  writeln("""   / \   __  _(_) ___  _ __ ___    / _ \/ ___| """, 0xa0caef)
  writeln("""  / _ \  \ \/ / |/ _ \| '_ ` _ \  | | | \___ \ """, 0xa0caef)
  writeln(""" / ___ \  >  <| | (_) | | | | | | | |_| |___) |""", 0xa0caef)
  writeln("""/_/   \_\/_/\_\_|\___/|_| |_| |_|  \___/|____/ """, 0xa0caef)
  writeln("")


  loadFont()

  initEfiGuids()

  ##  ACPI
  initAcpi(sysTable)

  ##  APICs
  initLapic()

  ioapic0 = initIoapic(madt0)
  # set keyboard interrupt: interrupt input 1 => vector 21h
  ioapic0.setRedirEntry(1, 0x21)


  #############################################
  ##  Setup interrupts

  # let's disable the PIC
  const
    Pic1DataPort = 0x21
    Pic2DataPort = 0xA1

  # # mask all interrupts
  portOut8(Pic1DataPort, 0xff)
  portOut8(Pic2DataPort, 0xff)

  initIdt()
  initKeyboard(keyHandler)
  initTimer()

  shell.init(sysTable)

  writeln("Welcome to AxiomOS")
  writeln("")
  write("] ")

  initThreads()
  initScheduler()

  # let t1 = createThread(shell.start)

  createThread(spinner).start()

  # idle thread
  var t0 = createThread(idle, ThreadPriority.low)
  t0.state = tsRunning
  jumpToThread(t0)


  # setInterruptHandler(0, isr00)
  # asm """
  #   mov rcx, 0
  #   div rcx
  # """

  #############################################
  ##  Exit UEFI Boot Services

  # let ebsStatus = sysTable.bootServices.exitBootServices(imageHandle, memoryMapKey)
