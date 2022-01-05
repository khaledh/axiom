import std/strbasics
import std/strformat
import std/strutils
import std/tables
import typetraits

import acpi
import bitops
import clib
import cpu
import font
import ioapic
import lapic
import malloc
import util
import uefi


var sysTable: ptr EfiSystemTable

proc printws(wstr: WideCString) =
  discard sysTable.conOut.outputString(sysTable.conOut, wstr[0].addr)

proc print(str: string) =
  discard sysTable.conOut.outputString(sysTable.conOut, (newWideCString(str).toWideCString)[0].addr)

proc println(str: string) =
  print(str & "\r\n")

proc printError(msg: string) =
  println(msg)

unhandledExceptionHook = proc (e: ref Exception) = discard
errorMessageWriter = printError

proc dumpFirmwareVersion() =
  let uefiMajor = sysTable.header.revision shr 16
  let uefiMinor = sysTable.header.revision and 0xffff
  let fwMajor = sysTable.firmwareRevision shr 16
  let fwMinor = sysTable.firmwareRevision and 0xffff
  let vendor = sysTable.firmwareVendor
  println("Firmware Version")
  print(&"  UEFI {uefiMajor}.{uefiMinor} (")
  printws(vendor)
  println(&", {fwMajor}.{fwMinor})")

proc dumpMemoryMap(): uint =
  var mapSize: uint = 0
  var memoryMap: ptr UncheckedArray[EfiMemoryDescriptor]
  var mapKey: uint
  var descriptorSize: uint
  var descriptorVersion: uint32

  discard sysTable.bootServices.getMemoryMap(addr mapSize, memoryMap, addr mapKey, addr descriptorSize, addr descriptorVersion)
  inc mapSize, 2 * descriptorSize.int
  discard sysTable.bootServices.allocatePool(mtLoaderData, mapSize, cast[ptr pointer](addr memoryMap))
  discard sysTable.bootServices.getMemoryMap(addr mapSize, memoryMap, addr mapKey, addr descriptorSize, addr descriptorVersion)

  println(&"Memory Map")
  let numDescriptors = mapSize div descriptorSize
  var desc = addr memoryMap[0]
  println("             start  size (kb)  type")
  for i in 0..<numDescriptors:
    let s = &"  [{i:>3}] {desc.physicalStart.uint:>10x}  {desc.numberOfPages.int64 * 4:>9}  {desc.type}"
    println(s)
    desc = cast[ptr EfiMemoryDescriptor](cast[uint](desc) + descriptorSize)
  
  result = mapKey


proc efiMain*(imageHandle: EfiHandle, systemTable: ptr EfiSystemTable): uint {.exportc.} =

  sysTable = systemTable
  heapBumpPtr = cast[int](addr heap)

  let GOP_GUID = parseGuid("9042a9de-23dc-4a38-fb96-7aded080516a")
  var igop: pointer
  let st = sysTable.bootServices.locateProtocol(unsafeAddr GOP_GUID, nil, addr igop)
  var gop = cast[ptr EfiGraphicsOutputProtocol](igop)

  discard sysTable.conOut.setMode(sysTable.conOut, 2)
  # discard gop.setMode(gop, 20)


  # discard sysTable.conOut.clearScreen(systemTable.conOut)
  discard sysTable.conOut.enableCursor(systemTable.conOut, false)

  println("""
      _          _                    ___  ____  
     / \   __  _(_) ___  _ __ ___    / _ \/ ___| 
    / _ \  \ \/ / |/ _ \| '_ ` _ \  | | | \___ \ 
   / ___ \  >  <| | (_) | | | | | | | |_| |___) |
  /_/   \_\/_/\_\_|\___/|_| |_| |_|  \___/|____/ 
  """)

  println("")
  dumpFirmwareVersion()

  println("")
  let memoryMapKey = dumpMemoryMap()


  #############################################
  ##  UEFI: Simple Text Output Protocol

  println("")
  println("Simple Text Output Protocol")
  println(&"  Current Mode    = {sysTable.conOut.mode.currentMode} (Max Mode={sysTable.conOut.mode.maxMode})")

  println("")
  var cols, rows: uint
  for i in 0..<sysTable.conOut.mode.maxMode:
    discard sysTable.conOut.queryMode(sysTable.conOut, i.uint, addr cols, addr rows)
    println(&"  Mode {i:>2}: {cols:>3} x {rows:>3}")

  #############################################
  ##  UEFI: Graphics Output Protocol

  println("")
  println("Graphics Output Protocol")
  println(&"  Current Mode    = {gop.mode.currentMode} (Max Mode={gop.mode.maxMode})")
  println(&"  Resolution      = {gop.mode.info.horizontalResolution} x {gop.mode.info.verticalResolution}")
  println(&"  Pixel Format    = {gop.mode.info.pixelFormat}")
  # println(&"  Pixel Info      = {gop.mode.info.pixelInfo}")
  println(&"  Pixels/ScanLine = {gop.mode.info.pixelsPerScanLine}")

  println("")
  var modeInfo: ptr GopModeInfo
  var sizeOfInfo: uint
  for i in 0..<gop.mode.maxMode:
    discard gop.queryMode(gop, i, addr sizeOfInfo, addr modeInfo)
    println(&"  Mode {i:>2}: {modeInfo.horizontalResolution:>4} x {modeInfo.verticalResolution:>4}")

  loadFont()
  print(&"font={psfFont[0].uint8:0>2x} {psfFont[1].uint8:0>2x}")

  # for i in 0..<800*600:
  #   cast[ptr uint32](gop.mode.frameBufferBase + i.uint*4)[] = 0x353d45'u32

# orange: #f57956
# green: #8ebb8a
# blue: #608aaf
# blue-ish: #4a8e97
# dark grey/black: #222629

  # var fb = cast[ptr UncheckedArray[uint32]](gop.mode.frameBufferBase)
  # var pos = 10*800 + 10
  # var g = 0
  # for glyph in values(Glyphs):
  #   for r, bits in glyph:
  #     for i in 0..<8:
  #       if (rotateLeftBits(bits, i) and 1) == 1:
  #         fb[pos + i] = 0xd4dae7
  #     inc(pos, 800)
  #   inc g
  #   pos = 10*800 + 10 + g*8

  # discard systemTable.bootServices.exitBootServices(imageHandle, memoryMapKey)

  # for i in 800*20..<800*40:
  #   cast[ptr uint32](gop.mode.frameBufferBase + i.uint*4)[] = 0x0000ff00'u32
  halt()

  #############################################
  ##  CPU: CR0 register

  var cr0 = readCR0()

  println("")
  println(&"CR0 = {cr0:.>16x}h")
  println(&"  .PE          Protection Enable                   {cr0 shr  0 and 1}")
  println(&"  .MP          Monitor Coprocessor                 {cr0 shr  1 and 1}")
  println(&"  .EM          Emulation                           {cr0 shr  2 and 1}")
  println(&"  .TS          Task Switched                       {cr0 shr  3 and 1}")
  println(&"  .TS          Extension Type                      {cr0 shr  4 and 1}")
  println(&"  .NE          Numeric Error                       {cr0 shr  5 and 1}")
  println(&"  .WP          Write Protect                       {cr0 shr 16 and 1}")
  println(&"  .AM          Alignment Mask                      {cr0 shr 18 and 1}")
  println(&"  .NW          Not Write-through                   {cr0 shr 29 and 1}")
  println(&"  .CD          Cache Disable                       {cr0 shr 30 and 1}")
  println(&"  .PG          Paging                              {cr0 shr 31 and 1}")

  #############################################
  ##  CPU: CR4 register

  var cr4 = readCR4()

  println("")
  println(&"CR4 = {cr4:.>16x}h")
  println(&"  .VME         Virtual-8086 Mode Extensions        {cr4 shr  0 and 1}")
  println(&"  .PVI         Protected-Mode Virtual Interrupts   {cr4 shr  1 and 1}")
  println(&"  .TSD         Time Stamp Disable                  {cr4 shr  2 and 1}")
  println(&"  .DE          Debugging Extensions                {cr4 shr  3 and 1}")
  println(&"  .PSE         Page Size Extensions                {cr4 shr  4 and 1}")
  println(&"  .PAE         Physical Address Extension          {cr4 shr  5 and 1}")
  println(&"  .MCE         Machine-Check Enable                {cr4 shr  6 and 1}")
  println(&"  .PGE         Page Global Enable                  {cr4 shr  7 and 1}")
  println(&"  .PCE         Perf-Monitoring Counte Enable       {cr4 shr  8 and 1}")
  println(&"  .OSFXR       OS Support for FXSAVE & FXRSTOR     {cr4 shr  9 and 1}")
  println(&"  .OSXMMEXCPT  OS Support for Unmasked SIMD")
  println(&"               Floating-Point Exceptions           {cr4 shr 10 and 1}")
  println(&"  .UMIP        User-Mode Instruction Prevention    {cr4 shr 11 and 1}")
  println(&"  .LA57        57-bit linear addresses             {cr4 shr 12 and 1}")
  println(&"  .VMXE        VMX-Enable Bit                      {cr4 shr 13 and 1}")
  println(&"  .SMXE        SMX-Enable Bit                      {cr4 shr 14 and 1}")
  println(&"  .FSGSBASE    FSGSBASE-Enable Bit                 {cr4 shr 16 and 1}")
  println(&"  .PCIDE       PCID-Enable Bit                     {cr4 shr 17 and 1}")
  println(&"  .OSXSAVE     XSAVE and Processor Extended State-")
  println(&"               Enable Bit                          {cr4 shr 18 and 1}")
  println(&"  .KL          Key-Locker-Enable Bit               {cr4 shr 19 and 1}")
  println(&"  .SMEP        SMEP-Enable Bit                     {cr4 shr 20 and 1}")
  println(&"  .SMAP        SMAP-Enable Bit                     {cr4 shr 21 and 1}")
  println(&"  .PKE         Enable protection keys for user-")
  println(&"               mode pages                          {cr4 shr 22 and 1}")
  println(&"  .CET         Control-flow Enforcement Technology {cr4 shr 23 and 1}")
  println(&"  .PKS         Enable protection keys for")
  println(&"               supervisor-mode pages               {cr4 shr 24 and 1}")

  #############################################
  ##  CPU: IA32_EFER register

  var efer = readMSR(0xC0000080'u32)  # EFER
  println("")
  println(&"IA32_EFER = {efer:.>16x}h")
  println(&"  .SCE         SYSCALL Enable                      {efer shr  0 and 1}")
  println(&"  .LME         IA-32e Mode Enable                  {efer shr  8 and 1}")
  println(&"  .LMA         IA-32e Mode Active                  {efer shr 10 and 1}")
  println(&"  .NXE         Execute Disable Bit Enable          {efer shr 11 and 1}")

  #############################################
  ##  CPU: GDT

  type GdtDescriptor {.packed.} = object
    limit: uint16
    base: uint64

  var gdt_desc: GdtDescriptor

  asm """
    sgdt %0
    :"=m"(`gdt_desc`)
  """

  println("")
  println("Global Descritpor Table")
  println(&"  GDT Base  = {gdt_desc.base:0>16x}h")
  println(&"  GDT Limit = {gdt_desc.limit}")

  type SegmentDescriptor {.packed.} = object
    limit00: uint16
    base00:  uint16
    base16:  uint8
    `type`   {.bitsize: 4.}: uint8
    s        {.bitsize: 1.}: uint8
    dpl      {.bitsize: 2.}: uint8
    p        {.bitsize: 1.}: uint8
    limit16  {.bitsize: 4.}: uint8
    avl      {.bitsize: 1.}: uint8
    l        {.bitsize: 1.}: uint8
    d        {.bitsize: 1.}: uint8
    g        {.bitsize: 1.}: uint8
    base24:  uint8

  println("")
  println("  Segment Descriptors")
  for i in 0..8:
    let desc = cast[ptr SegmentDescriptor](gdt_desc.base + i.uint64 * 8)
    print(&"  [{i}] ")
    # print(&"{cast[uint64](desc[])}h ")
    if cast[uint64](desc[]) == 0:
      println("Null Descriptor")
      continue
  
    var segType = newStringOfCap(64)
    if (desc.type.uint8 and 0x8) == 0x8:
      segType &= "Code {Conforming: "
      segType &= (if (desc.type.uint8 and 0x4) == 0x4: "1" else: "0")
      segType &= ", Read: "
      segType &= (if (desc.type.uint8 and 0x2) == 0x2: "1" else: "0")
      segType &= ", Accessed:"
      segType &= (if (desc.type.uint8 and 0x1) == 0x1: "1" else: "0")
      segType &= "}  "
    else:
      segType &= "Data {Expand-down:"
      segType &= (if (desc.type.uint8 and 0x4) == 0x4: "1" else: "0")
      segType &= ", Write:"
      segType &= (if (desc.type.uint8 and 0x2) == 0x2: "1" else: "0")
      segType &= ", Accessed:"
      segType &= (if (desc.type.uint8 and 0x1) == 0x1: "1" else: "0")
      segType &= "}  "

    println(
      &"Selector={i * 8:0>2x}  " &
      &"P={desc.p}  " &
      &"S={desc.s}  " &
      &"DPL={desc.dpl}  " &
      &"Type={desc.type:0>4b} " & segType &
      &"D/B={desc.d}  " &
      &"L={desc.l}  " &
      &"G={desc.g}  " &
      &"Base={(desc.base24 shl 24) or (desc.base16 shl 16) or (desc.base00):x}  " &
      &"Limit={(desc.limit16.uint32 shl 16) or (desc.limit00):x}")

  #############################################
  ##  CPU: IDT

  type IdtDescriptor {.packed.} = object
    limit: uint16
    base: uint64

  var idt_desc: IdtDescriptor

  asm """
    sidt %0
    :"=m"(`idt_desc`)
  """

  println("")
  println("Interrupt Descritpor Table")
  println(&"  IDT Base  = {idt_desc.base:0>16x}h")
  println(&"  IDT Limit = {idt_desc.limit}")

  type InterruptDescriptor {.packed.} = object
    offset00: uint16
    selector: uint16
    ist       {.bitsize: 3.}: uint8
    zeros1    {.bitsize: 5.}: uint8
    `type`    {.bitsize: 4.}: uint8
    zeros2    {.bitsize: 1.}: uint8
    dpl       {.bitsize: 2.}: uint8
    present   {.bitsize: 1.}: uint8
    offset16: uint16
    offset32: uint32
    reserved: uint32

  {.push stackTrace:off.}
  proc kbdIntHandler(intFrame: pointer) {.codegenDecl: "__attribute__ ((interrupt)) $# $#$#".}=
    println("")
    println("  ===> Key pressed <===")
    lapicWrite(LapicOffset.Eoi, 0)
  {.pop.}

  println("")
  println("  Interrupt Descriptors")
  for i in 0..255:
    let desc = cast[ptr InterruptDescriptor](idt_desc.base + i.uint64 * 16)
    if (desc.present == 0):
      continue

    if i == 0x33:  # Keyboard
      println("  Setting keyboard interrupt handler (0x33)")
      let kbdIntHandlerAddr = cast[uint64](kbdIntHandler)
      desc.offset00 = uint16(kbdIntHandlerAddr and 0xffff'u64)
      desc.offset16 = uint16(kbdIntHandlerAddr shr 16 and 0xffff'u64)
      desc.offset32 = uint32(kbdIntHandlerAddr shr 32)

    if i in [0, 0x33, 255]:
      print(&"  [{i:>3}] ")
      # print(&"{cast[ptr uint64](cast[uint64](desc) + 8)[]}h")
      # println(&"{cast[uint64](desc[])} ")
      let descType = case desc.type
        of 0b0010: "LDT"
        of 0b1001: "64-bit TSS (Available)"
        of 0b1011: "64-bit TSS (Busy)"
        of 0b1100: "64-bit Call Gate"
        of 0b1110: "64-bit Interrupt Gate"
        of 0b1111: "64-bit Trap Gate"
        else: ""

      print(descType)

      print(&"  Selector={desc.selector:0>2x}")
      println(&"  Offset={(desc.offset32.uint64 shl 32) or (desc.offset16.uint64 shl 16) or (desc.offset00):x}h")

    elif i == 1:
      println("  ...")


  #############################################
  ##  CPU: CPUID

  var eax, ebx, ecx, edx: uint32

  eax = 0
  cpuid(addr eax, addr ebx, addr ecx, addr edx)

  proc registerToString(reg: uint32): string =
    result &= cast[char](reg shr 00)
    result &= cast[char](reg shr 08)
    result &= cast[char](reg shr 16)
    result &= cast[char](reg shr 24)

  var vendor: string
  vendor &= registerToString(ebx)
  vendor &= registerToString(edx)
  vendor &= registerToString(ecx)

  println("")
  println("CPUID")
  println(&"  Vendor:                    {vendor}")
  println(&"  Highest Basic Function:    {eax:0>2x}h")

  eax = 0x80000000'u32
  cpuid(addr eax, addr ebx, addr ecx, addr edx)
  println(&"  Highest Extended Function: {eax:0>2x}h")

  eax = 1
  cpuid(addr eax, addr ebx, addr ecx, addr edx)

  var procType = (eax shr 12) and 0x3
  var family = eax shr 8 and 0xf
  if family == 0xf:
    family = (eax shr 20 and 0xff) + family
  var model = eax shr 4 and 0xf
  if family in [0x6.uint32, 0xf]:
    model += (eax shr 16 and 0xf) shl 4
  var stepping = eax and 0xf

  println("")
  println(&"  Processor Type:            {procType:0>2x}h")
  println(&"  Family ID:                 {family:0>2x}h")
  println(&"  Model ID:                  {model:0>2x}h")
  println(&"  Stepping ID:               {stepping:1x}h")

  type CpuIdFeaturesEcx {.packed.} = object
    sse3        {.bitsize: 1.}: uint32
    pclmulqdq   {.bitsize: 1.}: uint32
    dtes64      {.bitsize: 1.}: uint32
    monitor     {.bitsize: 1.}: uint32
    dscpl       {.bitsize: 1.}: uint32
    vmx         {.bitsize: 1.}: uint32
    smx         {.bitsize: 1.}: uint32
    eist        {.bitsize: 1.}: uint32
    tm2         {.bitsize: 1.}: uint32
    ssse3       {.bitsize: 1.}: uint32
    cnxtid      {.bitsize: 1.}: uint32
    sdbg        {.bitsize: 1.}: uint32
    fma         {.bitsize: 1.}: uint32
    cmpxchg16b  {.bitsize: 1.}: uint32
    xtprupdctl  {.bitsize: 1.}: uint32
    pdcm        {.bitsize: 1.}: uint32
    res1        {.bitsize: 1.}: uint32
    pcid        {.bitsize: 1.}: uint32
    dca         {.bitsize: 1.}: uint32
    sse41       {.bitsize: 1.}: uint32
    sse42       {.bitsize: 1.}: uint32
    x2apic      {.bitsize: 1.}: uint32
    movbe       {.bitsize: 1.}: uint32
    popcnt      {.bitsize: 1.}: uint32
    tscdeadline {.bitsize: 1.}: uint32
    aesni       {.bitsize: 1.}: uint32
    xsave       {.bitsize: 1.}: uint32
    osxsave     {.bitsize: 1.}: uint32
    avx         {.bitsize: 1.}: uint32
    f16c        {.bitsize: 1.}: uint32
    rdrand      {.bitsize: 1.}: uint32
    res2        {.bitsize: 1.}: uint32

  type CpuIdFeaturesEdx {.packed.} = object
    fpu         {.bitsize: 1.}: uint32
    vme         {.bitsize: 1.}: uint32
    de          {.bitsize: 1.}: uint32
    pse         {.bitsize: 1.}: uint32
    tsc         {.bitsize: 1.}: uint32
    msr         {.bitsize: 1.}: uint32
    pae         {.bitsize: 1.}: uint32
    mce         {.bitsize: 1.}: uint32
    cx8         {.bitsize: 1.}: uint32
    apic        {.bitsize: 1.}: uint32
    res1        {.bitsize: 1.}: uint32
    sep         {.bitsize: 1.}: uint32
    mtrr        {.bitsize: 1.}: uint32
    pge         {.bitsize: 1.}: uint32
    mca         {.bitsize: 1.}: uint32
    cmov        {.bitsize: 1.}: uint32
    pat         {.bitsize: 1.}: uint32
    pse36       {.bitsize: 1.}: uint32
    psn         {.bitsize: 1.}: uint32
    clfsh       {.bitsize: 1.}: uint32
    res2        {.bitsize: 1.}: uint32
    ds          {.bitsize: 1.}: uint32
    acpi        {.bitsize: 1.}: uint32
    mmx         {.bitsize: 1.}: uint32
    fxsr        {.bitsize: 1.}: uint32
    sse         {.bitsize: 1.}: uint32
    sse2        {.bitsize: 1.}: uint32
    ss          {.bitsize: 1.}: uint32
    htt         {.bitsize: 1.}: uint32
    tm          {.bitsize: 1.}: uint32
    res3        {.bitsize: 1.}: uint32
    pbe         {.bitsize: 1.}: uint32

  println("")
  println(&"  Feature Info in ECX: {cast[CpuIdFeaturesEcx](ecx)}")
  println(&"  Feature Info in EDX: {cast[CpuIdFeaturesEdx](edx)}")

  #############################################
  ##  CPU: Paging Tables

  eax = 0x80000008'u32
  cpuid(addr eax, addr ebx, addr ecx, addr edx)

  var cr3 = readCR3()
  let pml4addr = cr3 and 0xfffffff000'u64

  println("")
  println("Page Tables")
  println(&"  # Physical Address Bits: {eax and 0xff}")
  println(&"  # Linear Address Bits:   {(eax shr 8) and 0xff}")
  println("")
  println(&"  PML4 Table Address = {pml4addr:.>16x}h")

  type PagingL4Entry {.packed.} = object
    present    {.bitsize:  1.}: uint64  # bit      0
    write      {.bitsize:  1.}: uint64  # bit      1
    supervisor {.bitsize:  1.}: uint64  # bit      2
    pwt        {.bitsize:  1.}: uint64  # bit      3
    pcd        {.bitsize:  1.}: uint64  # bit      4
    accessed   {.bitsize:  1.}: uint64  # bit      5
    ignored1   {.bitsize:  1.}: uint64  # bit      6
    reserved1  {.bitsize:  1.}: uint64  # bit      7
    ignored2   {.bitsize:  4.}: uint64  # bits 11: 8
    phyAddress {.bitsize: 28.}: uint64  # bits 39:12
    reserved2  {.bitsize: 12.}: uint64  # bits 51:40
    ignored3   {.bitsize: 11.}: uint64  # bits 62:52
    xd         {.bitsize:  1.}: uint64  # bit    63

  # A PML4 table comprises 512 64-bit entries (PML4Es)
  var pdpTableAddrs: seq[uint64]
  for i in 0..<512:
    let pml4e = cast[ptr PagingL4Entry](pml4addr + i.uint64 * 64)
    # If a paging-structure entry's P flag (bit 0) is 0 or if the entry sets any reserved bit,
    # the entry is used neither to reference another paging-structure entry nor to map a page.
    if pml4e.present == 1 and pml4e.reserved1 == 0 and pml4e.reserved2 == 0:
      print(&"  [{i:>3}]  ")
      let phyAddr = pml4e.phyAddress shl 12
      println(&"PhyAddress={phyAddr:0>8x}  Write={pml4e.write}  User/Supervisor={pml4e.supervisor}  Accessed={pml4e.accessed}  XD={pml4e.xd}")
      pdpTableAddrs &= phyAddr

  type PageDirectoryPointerEntry {.packed.} = object
    present    {.bitsize:  1.}: uint64  # bit      0
    write      {.bitsize:  1.}: uint64  # bit      1
    supervisor {.bitsize:  1.}: uint64  # bit      2
    pwt        {.bitsize:  1.}: uint64  # bit      3
    pcd        {.bitsize:  1.}: uint64  # bit      4
    accessed   {.bitsize:  1.}: uint64  # bit      5
    dirty      {.bitsize:  1.}: uint64  # bit      6
    pageSize   {.bitsize:  1.}: uint64  # bit      7
    global     {.bitsize:  1.}: uint64  # bit      8
    ignored1   {.bitsize:  3.}: uint64  # bits 11: 9
    pat        {.bitsize:  1.}: uint64  # bit     12
    reserved1  {.bitsize: 17.}: uint64  # bits 29:13
    phyAddress {.bitsize: 10.}: uint64  # bits 39:30
    reserved2  {.bitsize: 12.}: uint64  # bits 51:40
    ignored2   {.bitsize: 11.}: uint64  # bits 58:52
    protKey    {.bitsize:  4.}: uint64  # bits 62:59
    xd         {.bitsize:  1.}: uint64  # bit    63

  # println("")
  # println("  Page Directory Pointer Tables")
  # println("")
  # for pdpTableAddr in pdpTableAddrs:
  #   for i in 0..<512:
  #     let pdpte = cast[ptr PageDirectoryPointerEntry](pdpTableAddr + i.uint64 * 64)
  #     if pdpte.present == 1 and pdpte.reserved1 == 0 and pdpte.reserved2 == 0:
  #       println(&"  [{i:>3}]  PhyAddress={pdpte.phyAddress shl 30:0>10x}  PS={pdpte.pageSize}  Write={pdpte.write}  User/Supervisor={pdpte.supervisor}  Accessed={pdpte.accessed}  Dirty={pdpte.dirty}  XD={pdpte.xd}")
  #   println("")

  let efiGuids = {
    parseGuid("ee4e5898-3914-4259-6e9d-dc7bd79403cf"): ("LZMA_CUSTOM_DECOMPRESS_GUID", "LZMA Custom Decompress"),
    parseGuid("05ad34ba-6f02-4214-2e95-4da0398e2bb9"): ("DXE_SERVICES_TABLE_GUID", "DXE Services Table"),
    parseGuid("7739f24c-93d7-11d4-3a9a-0090273fc14d"): ("HOB_LIST_GUID", "HOB (Hand-Off Block) List"),
    parseGuid("4c19049f-4137-4dd3-109c-8b97a83ffdfa"): ("EFI_MEMORY_TYPE_INFORMATION_GUID", "Memory Type Information"),
    parseGuid("49152e77-1ada-4764-a2b7-7afefed95e8b"): ("EFI_DEBUG_IMAGE_INFO_TABLE_GUID", "Debug Image Info Table"),
    parseGuid("060cc026-4c0d-4dda-418f-595fef00a502"): ("MEMORY_STATUS_CODE_RECORD_GUID", "Memory Status Code Record"),
    parseGuid("eb9d2d31-2d88-11d3-169a-0090273fc14d"): ("SMBIOS_TABLE_GUID", "SMBIOS Table"),
    parseGuid("eb9d2d30-2d88-11d3-169a-0090273fc14d"): ("ACPI_TABLE_GUID", "ACPI 1.0 Table"),
    parseGuid("8868e871-e4f1-11d3-22bc-0080c73c8881"): ("EFI_ACPI_TABLE_GUID", "ACPI 2.0+ Table"),
    parseGuid("dcfa911d-26eb-469f-20a2-38b7dc461220"): ("EFI_MEMORY_ATTRIBUTES_TABLE_GUID", "Memory Attributes Table"),
  }.toTable

  var rsdp: ptr RSDP

  println("")
  println("UEFI Configuration Table")
  for i in 0..<sysTable.numTableEntries:
    let entry = sysTable.configTable[i]
    print(&"  {$entry.vendorGuid}")
    if efiGuids.contains(entry.vendorGuid):
      print(&"  {efiGuids[entry.vendorGuid][1]}")
      if efiGuids[entry.vendorGuid][0] == "EFI_ACPI_TABLE_GUID":
        rsdp = cast[ptr RSDP](entry.vendorTable)
    println("")

  type
    MultipleApicFlag {.size: sizeof(uint32).} = enum
      PcAtCompat  = "PC/AT Compatible PIC"
    MultipleApicFlags = set[MultipleApicFlag]

    MADT {.packed.} = object
      hdr: TableDescriptionHeader
      lapicAddress: uint32
      flags: MultipleApicFlags

    InterruptControllerType {.size: sizeof(uint8).}= enum
      ictLocalApic                 = "Local APIC"
      ictIoApic                    = "I/O APIC"
      ictInterruptSourceOverride   = "Interrupt Source Override"
      ictNmiSource                 = "NMI Source"
      ictLocalApicNmi              = "Local APIC NMI"
      ictLocalApicAddressOverride  = "Local APIC Address Override"
      ictIoSapic                   = "I/O SAPIC"
      ictLocalSapic                = "Local SAPIC"
      ictPlatformInterruptSources  = "Platform Interrupt Sources"
      ictLocalx2Apic               = "Local x2APIC"
      ictLocalx2ApicNmi            = "Local x2APIC NMI"
      ictGicCpuInterface           = "GIC CPU Interface (GICC)"
      ictGicDistributor            = "GIC Distributor (GICD)"
      ictGicMsiFrame               = "GIC MSI Frame"
      ictGicRedistributor          = "GIC Redistributor (GICR)"
      ictGicInterruptTranslationService = "GIC Interrupt Translation Service (ITS)"
      ictMultiprocessorWakeup      = "Multiprocessor Wakeup"

    InterruptControllerHeader {.packed.} = object
      typ: InterruptControllerType
      len: uint8

    LocalApic {.packed.} = object
      hdr: InterruptControllerHeader
      processorUid: uint8
      lapicId: uint8
      flags: LocalApicFlags
    LocalApicFlag {.size: sizeof(uint32).} = enum
      laEnabled        = "Enabled"
      laOnlineCapable  = "Online Capable"
    LocalApicFlags = set[LocalApicFlag]

    IoApic {.packed.} = object
      hdr: InterruptControllerHeader
      ioapicId: uint8
      reserved: uint8
      address: uint32
      gsiBase: uint32

    InterruptSourceOverride {.packed.} = object
      hdr: InterruptControllerHeader
      bus: uint8
      source: uint8
      gsi: uint32
      flags: MpsIntInFlags
    InterruptPolarity {.size: 2.} = enum
      ipBusConformant  = (0b00, "Bus Conformant")
      ipActiveHigh     = (0b01, "Active High")
      ipResreved       = (0b10, "Reserved")
      ipActiveLow      = (0b11, "Active Low")
    InterruptTriggerMode {.size: 2.} = enum
      itBusConformant  = (0b00, "Bus Conformant")
      itEdgeTriggered  = (0b01, "Edge-Triggered")
      itResreved       = (0b10, "Reserved")
      itLevelTriggered = (0b11, "Level-Triggered")
    MpsIntInFlags {.packed.} = object
      polarity    {.bitsize: 2.}: InterruptPolarity
      triggerMode {.bitsize: 2.}: InterruptTriggerMode

    LocalApicNmi {.packed.} = object
      hdr: InterruptControllerHeader
      processorUid: uint8
      flags: MpsIntInFlags
      lintN: uint8


  if rsdp != nil:
    println("")
    println("RSDP")
    println(&"  Revision: {rsdp.revision:x}")

    let xsdt = cast[ptr TableDescriptionHeader](rsdp.xsdtAddress)
    let numEntries = (xsdt.length.int - sizeof(TableDescriptionHeader)) div 8

    println("")
    println("XSDT")
    println(&"  Revision: {xsdt.revision}h")
    println(&"  Number of Entries: {numEntries}")
    println("")

    var madt: ptr MADT

    for i in 0..<numEntries:
      let tablePtrLoc = cast[ptr uint64](cast[int](xsdt) + sizeof(TableDescriptionHeader) + i.int * 8)
      let table = cast[ptr TableDescriptionHeader](tablePtrLoc[])
      if table.signature == "APIC":
        madt = cast[ptr MADT](table)
      var tag = ""
      tag.add(table.signature)
      println(&"  {tag}  addr={cast[uint64](table):0>8x}  length={table.length}")

    if not isNil(madt):
      println("")
      println("MADT")
      println(&"  Local APIC Address: {madt.lapicAddress:0>8x}")
      println(&"  Flags:              {madt.flags}")
      println("")
      println(&"  Interrupt Controller Structures")

      var ioapic: ptr IoApic

      var intCtrlStruct = cast[ptr InterruptControllerHeader](cast[uint64](madt) + sizeof(TableDescriptionHeader).uint64 + 8)
      while cast[uint64](intCtrlStruct) - cast[uint64](madt) < madt.hdr.length:
        println("")
        println(&"    {intCtrlStruct.typ}")
        case intCtrlStruct.typ
          of ictLocalApic:
            let lapic = cast[ptr LocalApic](intCtrlStruct)
            println(&"      Processor UID: {lapic.processorUid}")
            println(&"      LAPIC ID:      {lapic.lapicId}")
            println(&"      Flags:         {lapic.flags}")
          of ictIoApic:
            ioapic = cast[ptr IoApic](intCtrlStruct)
            println(&"      I/O APIC ID:   {ioapic.ioapicId}")
            println(&"      Address:       {ioapic.address:0>8x}")
            println(&"      GSI Base:      {ioapic.gsiBase}")
            setIoApic(ioapic.ioapicId, ioapic.address, ioapic.gsiBase)
          of ictInterruptSourceOverride:
            let intSrcOverride = cast[ptr InterruptSourceOverride](intCtrlStruct)
            println(&"      Bus:           {intSrcOverride.bus}")
            println(&"      Source:        {intSrcOverride.source}")
            println(&"      GSI:           {intSrcOverride.gsi}")
            println(&"      Flags:         {intSrcOverride.flags}")
          of ictLocalApicNmi:
            let lapicNmi = cast[ptr LocalApicNmi](intCtrlStruct)
            println(&"      Processor UID: {lapicNmi.processorUid:0>2x}h")
            println(&"      Flags:         {lapicNmi.flags}")
            println(&"      LINT#:         {lapicNmi.lintN}")
          else: discard
        intCtrlStruct = cast[ptr InterruptControllerHeader](cast[uint64](intCtrlStruct) + intCtrlStruct.len)

      if not isNil(ioapic):
        println("")
        println("I/O APIC")

        # set keyboard interrupt: interrupt input 1 => vector 33h
        let kbdRedirEntry = IoapicRedirectionEntry(
          vector           : 0x33,
          deliveryMode     : 0,  # Fixed
          destinationMode  : 0,  # Physical
          deliveryStatus   : 0,
          polarity         : 0,  # ActiveHigh
          remoteIrr        : 0,
          triggerMode      : 0,  # Edge
          mask             : 0,  # Enabled
          destination      : 0,  # Lapic ID 0
        )
        ioapicWrite(0x12, cast[uint32](cast[uint64](kbdRedirEntry) and 0xffff))
        ioapicWrite(0x13, cast[uint32](cast[uint64](kbdRedirEntry) shr 32))

        let ioapicId = cast[IoApicIdRegister](ioapicRead(0))
        let ioapicVer = cast[IoApicVersionRegister](ioapicRead(1))
        println(&"  IOAPICID  = {ioapicId.id}")
        println(&"  IOAPICVER = Version: {ioapicVer.version:0>2x}h, MaxRedirectionEntry: {ioapicVer.maxRedirEntry}")
        println("  IOREDTBL")
        println("       Vector  DeliveryMode  DestinationMode  Destination  Polarity  TriggerMode  DeliveryStatus  RemoteIRR  Mask")
        for i in 0..ioapicVer.maxRedirEntry:
          let lo = ioapicRead(2*i.int + 0x10)
          let hi = ioapicRead(2*i.int + 0x11)
          let entry = cast[IoapicRedirectionEntry](hi.uint64 shl 32 or lo)
          print(&"  [{i: >2}] {entry.vector:0>2x}h     {entry.deliveryMode: <12}  {entry.destinationMode: <15}  {entry.destination: <11}")
          println(&"  {entry.polarity: <8}  {entry.triggerMode: <11}  {entry.deliveryStatus: <14}  {entry.remoteIrr: <9}  {entry.mask}")

  lapicLoadBaseAddress()

  println("")
  println("IA32_APIC_BASE MSR")
  println(&"  Is Bootstrap Processor (BSP) = {lapicBaseMsr.isBsp}")
  println(&"  APIC Global Enable           = {lapicBaseMsr.enabled}")
  println(&"  APIC Base Address            = {lapicBaseAddress:0>8x}")

  println("")
  println("Local APIC Registers")

  let lapicid = cast[LapicIdRegister](lapicRead(LapicOffset.LapicId))
  println("")
  println("  APIC ID Register")
  println(&"    APIC ID      = {lapicid.apicId}")

  let lapicVersion = cast[LapicVersionRegister](lapicRead(0x30))
  println("")
  println("  APIC Version Register")
  println(&"    Version                           = {lapicVersion.version:0>2x}h")
  println(&"    Max LVT Entry:                    = {lapicVersion.maxLvtEntry}")
  println(&"    Suppress EOI-broadcasts Supported = {lapicVersion.suppressEoiBroadcastSupported}")


  let svr = cast[SupriousInterruptVectorRegister](lapicRead(LapicOffset.SpuriousInterrupt))
  println("")
  println("  Spurious Interrupt Vector Register")
  println(&"    Vector       = {svr.vector:0>2x}h")
  println(&"    APIC Enabled = {svr.apicEnable}")


  let timer = cast[LvtTimerRegister](lapicRead(LapicOffset.LvtTimer))
  let lint0 = cast[LvtRegister](lapicRead(LapicOffset.LvtLint0))
  let lint1 = cast[LvtRegister](lapicRead(LapicOffset.LvtLint1))
  let error = cast[LvtRegister](lapicRead(LapicOffset.LvtError))

  println("")
  println("  LVT Registers")
  println(&"           Vector  DeliveryMode  DeliveryStatus  Polarity    TriggerMode  RemoteIRRFlag  Mask")
  println(&"    Timer  {timer.vector:0>2x}                    {timer.deliveryStatus}                                                    {timer.mask}     TimerMode: {timer.timerMode}")
  println(&"    LINT0  {lint0.vector:0>2x}      {lint0.deliveryMode: <12}  {lint0.deliveryStatus}            {lint0.intPolarity}  {lint0.intTriggerMode}         {lint0.remoteIrrFlag}              {lint0.mask}")
  println(&"    LINT1  {lint1.vector:0>2x}      {lint1.deliveryMode: <12}  {lint1.deliveryStatus}            {lint1.intPolarity}  {lint1.intTriggerMode}         {lint1.remoteIrrFlag}              {lint1.mask}")
  println(&"    Error  {error.vector:0>2x}                    {error.deliveryStatus}                                                    {error.mask}")
  if lapicVersion.maxLvtEntry >= 4:
    let perf = cast[LvtRegister](lapicRead(0x340))
    println(&"    Perf   {perf.vector:0>2x}      {perf.deliveryMode: <12}  {perf.deliveryStatus}                                                    {perf.mask}")
  if lapicVersion.maxLvtEntry >= 5:
    let therm = cast[LvtRegister](lapicRead(0x330))
    println(&"    Therm  {therm.vector:0>2x}      {therm.deliveryMode: <12}  {therm.deliveryStatus}                                                    {therm.mask}")

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


  #############################################
  ##  Shutdown

  # shutdown()
  # halt()

  while true:
    asm """
      hlt
    """


#############################################
## binarylang is not working right now due to an issue with inheritance
## using ref sematnics under `--os:any` and `passl:"-nostdlib"
## https://github.com/nim-lang/Nim/issues/19205#issuecomment-1003503808

# import binarylang
# import binarylang/plugins

# struct(tableDescHeader, endian = l):
#   8:  signature[4]
#   32: length
#   8:  revision
#   8:  checksum
#   s:  oemId(6)
#   s:  oemTableId(8)
#   32: oemRevision
#   s:  creatorId(4)
#   32: creatorRevision

# struct(xsdt, endian = l):
#   *tableDescHeader: hdr
#   64: entry[(hdr.length - s.getPosition) div 8]

# proc newMemoryBitStream(buf: pointer, bufLen: int): BitStream =
#   BitStream(stream: newMemoryStream(buf, bufLen), buffer: 0, bitsLeft: 0)
