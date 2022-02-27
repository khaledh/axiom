import bitops
import std/strbasics
import std/strformat
import std/strutils
import std/tables
import typetraits

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
import ioapic
import keyboard
import lapic
import paging
import pci
import physmem
import uefi
import uefitypes
import uefi/gop
import uefi/simpletext
import lib/libc
import lib/malloc
import lib/guid

var sysTable: ptr EfiSystemTable

proc printError(msg: string) =
  println(msg)

proc handleUnhandledException(e: ref Exception) {.tags: [], raises: [].} =
  printError(e.msg)

proc efiMain*(imageHandle: EfiHandle, systemTable: ptr EfiSystemTable): uint {.exportc.} =
  sysTable = systemTable
  heapBumpPtr = cast[int](addr heap)

  initDebug(sysTable.conOut)

  errorMessageWriter = printError
  unhandledExceptionHook = handleUnhandledException

  let GOP_GUID = parseGuid("9042a9de-23dc-4a38-fb96-7aded080516a")
  var igop: pointer
  let st = sysTable.bootServices.locateProtocol(unsafeAddr GOP_GUID, nil, addr igop)
  var gop = cast[ptr EfiGraphicsOutputProtocol](igop)

  discard sysTable.conOut.setMode(sysTable.conOut, 2)

  # discard sysTable.conOut.clearScreen(systemTable.conOut)
  discard sysTable.conOut.enableCursor(systemTable.conOut, false)

  println("""
      _          _                    ___  ____  
     / \   __  _(_) ___  _ __ ___    / _ \/ ___| 
    / _ \  \ \/ / |/ _ \| '_ ` _ \  | | | \___ \ 
   / ___ \  >  <| | (_) | | | | | | | |_| |___) |
  /_/   \_\/_/\_\_|\___/|_| |_| |_|  \___/|____/ 
  """)

  dumpFirmwareVersion(sysTable)

  let memoryMapKey = dumpMemoryMap(sysTable.bootServices)

  dumpSimpletext(sysTable.conOut)

  dumpGop(gop)

  loadFont()
  dumpFont()

  # discard gop.setMode(gop, 14)  # 1280x1024
  # var fb = initFramebuffer(gop.mode.frameBufferBase, width=1280, height=1024)

  # # BGA (Bochs Graphics Adapter)
  # let bgaId = bgaReadRegister(BxvbePortIndexId)
  # println(&"BGA ID = {bgaId:0>4x}")

  # bgaSetVideoMode(1280, 1024, 32)

  # let virtWidth = bgaReadRegister(BxvbePortIndexVirtWidth)
  # let virtHeight = bgaReadRegister(BxvbePortIndexVirtHeight)
  # println(&"BGA VirtualRes = {virtWidth}x{virtHeight}")

  # var fb = initFramebuffer(BxvbeLfbPhysicalAddress, width=1280, height=1024)

  # # clear background
  # fb.clear(0x2d363d'u32)


  # var fnt = loadFont16()
  # var con = initConsole(fb, left=8, top=16, font=fnt, maxCols=158, maxRows=62, color=0x2d363d'u32)

  # con.write("""    _          _                    ___  ____  """); con.write("\n")
  # con.write("""   / \   __  _(_) ___  _ __ ___    / _ \/ ___| """); con.write("\n")
  # con.write("""  / _ \  \ \/ / |/ _ \| '_ ` _ \  | | | \___ \ """); con.write("\n")
  # con.write(""" / ___ \  >  <| | (_) | | | | | | | |_| |___) |"""); con.write("\n")
  # con.write("""/_/   \_\/_/\_\_|\___/|_| |_| |_|  \___/|____/ """); con.write("\n")
  # con.write("\n");
  # con.write("Nim is awesome!", 0xa0caef)
  # con.flush()

  # discard systemTable.bootServices.exitBootServices(imageHandle, memoryMapKey)

  # halt()

  dumpCpuid()
  dumpControlRegisters()

  dumpGdt()
  dumpIdt()

  # Get physical and linear address sizes
  var eax, ebx, ecx, edx: uint32
  eax = 0x80000008'u32
  cpuid(addr eax, addr ebx, addr ecx, addr edx)
  println("")
  println(&"  # Physical Address Bits: {eax and 0xff}")
  println(&"  # Linear Address Bits:   {(eax shr 8) and 0xff}")

  dumpPagingTables()

  #############################################
  ##  UEFI Configuration Tables

  dumpUefiConfigTables(sysTable)

  #############################################
  ##  ACPI Tables

  let configTables = getUefiConfigTables(sysTable)

  var acpiTable = configTables.getOrDefault(EfiAcpi2TableGuid)
  if not isNil(acpiTable):
    let rsdp = cast[ptr RSDP](configTables[EfiAcpi2TableGuid])
    println("")
    println("RSDP")
    println(&"  Revision: {rsdp.revision:x}")

    let xsdt = parseXsdt(rsdp.xsdtAddress)
    dumpXsdt(xsdt)

    var hdr: ptr TableDescriptionHeader

    hdr = xsdt.entries.getOrDefault(['F', 'A', 'C', 'P'])
    if not isNil(hdr):
      let fadt = parseFadt(cast[pointer](hdr))
      dumpFadt(fadt)

    hdr = xsdt.entries.getOrDefault(['A', 'P', 'I', 'C'])
    if not isNil(hdr):
      let madt = cast[ptr MADT](hdr)
      dumpMadt(madt)

  #############################################
  ##  APICs

  lapicLoadBaseAddress()
  dumpLapic()

  dumpIoapic()

  #############################################
  ##  PCI

  dumpPciConfig()
  dumpAhci(bus=0, dev=0x1f, fn=2, sysTable.bootServices)

  #############################################
  ##  Exit UEFI Boot Services

  # let ebsStatus = sysTable.bootServices.exitBootServices(imageHandle, memoryMapKey)

  #############################################
  ##  Setup interrupts

  # let's disable the PIC
  # const
  #   Pic1DataPort = 0x21
  #   Pic2DataPort = 0xA1

  # # mask all interrupts
  # portOut8(Pic1DataPort, 0xff);
  # portOut8(Pic2DataPort, 0xff);

  lapicSetTimer()

  #############################################
  ##  Shutdown

  # shutdown()
  # halt()
  idle()
