import std/strbasics
import std/strformat
import std/strutils
import std/tables

import acpi
import acpi/fadt
import acpi/madt
import acpi/xsdt
import ahci
import bxvbe
import console
import cpu
import debug
import firmware
import font
import framebuffer
import gdt
import idt
import interrupt
import ioapic
import keyboard
import lapic
import paging
import pci
import physmem
import shell
import task
import timer
import uefi
import uefitypes
import uefi/gop
import uefi/simpletext
import lib/libc
import lib/malloc
import lib/guid

var sysTable: ptr EfiSystemTable

proc printError(msg: string) =
  writeln(msg)

proc handleUnhandledException(e: ref Exception) {.tags: [], raises: [].} =
  printError(e.msg)


proc thread1() {.cdecl.} =
  # while true:
  for i in 0..<20:
    write(".")
    for i in 0..250000:
      asm "pause"

proc thread2() {.cdecl.} =
  # while true:
  for i in 0..<20:
    write("o")
    for i in 0..250000:
      asm "pause"

var
  rsdp: ptr Rsdp
  xsdt0: Xsdt
  fadt0: ptr Fadt
  madt0: ptr Madt
  ioapic0: ioapic.Ioapic
  lineBuffer: string

proc showHelp() =
  writeln("Commands")
  writeln("")
  writeln("  ping          Respond with 'pong'")
  writeln("  firmware      Show firmware version")
  writeln("  memory        Show the memory map")
  writeln("  uefi tables   Show UEFI config table")
  writeln("  uefi text     Show UEFI text modes")
  writeln("  rsdp          Show ACPI RSDP")
  writeln("  xsdt          Show ACPI XSDT table")
  writeln("  fadt          Show ACPI FADT table")
  writeln("  madt          Show ACPI MADT table")
  writeln("  idt           Show Interrupt Descriptor Table")
  writeln("  gdt           Show Global Descriptor Table")
  writeln("  lapic         Show Local APIC information")
  writeln("  iopic         Show I/O APIC information")
  writeln("  pci           Show PCI configuration")
  writeln("  ahci          Show AHCI configuration")
  writeln("  cpuid         Show CPUID information")
  writeln("  ctlreg        Show CPU control registers")
  writeln("  font          Show font information")
  writeln("  halt          Halt without shutting down")
  writeln("  shutdown      Shutdown")

proc dispatchCommand(cmd: string) =
  case cmd:
  of "help":
    showHelp()
  of "ping":
    writeln("pong")
  of "rsdp":
    showRsdp(rsdp)
  of "xsdt":
    showXsdt(xsdt0)
  of "fadt":
    showFadt(fadt0)
  of "madt":
    showMadt(madt0)
  of "idt":
    showIdt()
  of "gdt":
    showGdt()
  of "lapic":
    lapic.show()
  of "ioapic":
    ioapic0.show()
  of "pci":
    showPciConfig()
  of "ahci":
    showAhci(bus=0, dev=0x1f, fn=2, sysTable.bootServices)
  of "font":
    showFont()
  of "cpuid":
    showCpuid()
  of "ctlreg":
    showControlRegisters()
  of "memory":
    discard showMemoryMap(sysTable.bootServices)
  of "paging":
    showPagingTables()
  of "firmware":
    showFirmwareVersion(sysTable)
  of "uefi tables":
    showUefiConfigTables(sysTable)
  of "uefi text":
    showSimpletext(sysTable.conOut)
  of "shutdown":
    writeln("Shutting down")
    shutdown()
  of "halt":
    writeln("Halt")
    halt()
  else:
    writeln("Uknown command")

proc keyHandler(evt: KeyEvent) =
  if evt.eventType == KeyDown and evt.ch != '\0':
    if evt.ch == '\n':
      writeln("")
      dispatchCommand(lineBuffer)
      writeln("")
      write("] ")
      lineBuffer = ""
    elif evt.ch == '\b':
      lineBuffer.delete(len(lineBuffer)-1 .. len(lineBuffer)-1)
      write(&"{evt.ch}")
    else:
      lineBuffer &= evt.ch
      write(&"{evt.ch}")

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

  #############################################
  ##  ACPI Tables

  initEfiGuids()
  let configTables = getUefiConfigTables(sysTable)

  var acpiTable = configTables.getOrDefault(EfiAcpi2TableGuid)
  if not isNil(acpiTable):
    let rsdp = cast[ptr Rsdp](configTables[EfiAcpi2TableGuid])

    let xsdt = initXsdt(rsdp)
    xsdt0 = xsdt
    # showXsdt(xsdt)

    var hdr = xsdt.entries.getOrDefault(['F', 'A', 'C', 'P'])
    if not isNil(hdr):
      fadt0 = parseFadt(cast[pointer](hdr))

    madt0 = initMadt(xsdt)

    #############################################
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
  portOut8(Pic1DataPort, 0xff);
  portOut8(Pic2DataPort, 0xff);

  initIdt()
  initKeyboard(keyHandler)
  initTimer()

  writeln("Welcome to AxiomOS")

  # halt()

  initThreads()

  let t0 = createThread(idle, ThreadPriority.low)
  t0.startThread()

  # let t1 = createThread(thread1)
  # let t2 = createThread(thread2)

  # t1.startThread()
  # t2.startThread()

  # let t1 = createThread(shell.start)


  writeln("")
  write("] ")
  jumpToThread(t0)


  # setInterruptHandler(0, isr00)
  # asm """
  #   mov rcx, 0
  #   div rcx
  # """

  #############################################
  ##  Exit UEFI Boot Services

  # let ebsStatus = sysTable.bootServices.exitBootServices(imageHandle, memoryMapKey)
