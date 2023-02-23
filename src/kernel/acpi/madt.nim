#[
  ACPI: MADT (Multiple APIC Description Table)

  Responsibilities:
  - ???

  Requires:
  - acpi.tables.xsdt

  Provides:
  - acpi.tables.madt
]#

import std/options
import std/strformat

import table, xsdt
import ../devices/console

type
  MultipleApicFlag {.size: sizeof(uint32).} = enum
    PcAtCompat  = "PC/AT Compatible PIC"
  MultipleApicFlags = set[MultipleApicFlag]

  Madt* {.packed.} = object
    hdr: TableDescriptionHeader
    lapicAddress: uint32
    flags: MultipleApicFlags

  InterruptControllerType {.size: sizeof(uint8).}= enum
    ictLocalApic                 = "Local APIC"
    ictIoapic                    = "I/O APIC"
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

  Ioapic* {.packed.} = object
    hdr: InterruptControllerHeader
    id*: uint8
    reserved: uint8
    address*: uint32
    gsiBase*: uint32

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

var
  madt0*: ptr Madt


proc init*() =
  let hdr = xsdt.findBySignature(['A', 'P', 'I', 'C'])
  if hdr.isSome:
    madt0 = cast[ptr Madt](hdr.get())
  else:
    writeln("Could not initialize MADT")
    flush()


iterator intCtrlStructs(madt: ptr Madt): ptr InterruptControllerHeader {.inline.} =
  var intCtrlStruct = cast[ptr InterruptControllerHeader](cast[uint64](madt) + sizeof(TableDescriptionHeader).uint64 + 8)
  while cast[uint64](intCtrlStruct) - cast[uint64](madt) < madt.hdr.length:
    yield intCtrlStruct
    intCtrlStruct = cast[ptr InterruptControllerHeader](cast[uint64](intCtrlStruct) + intCtrlStruct.len)


# Local APICs
iterator lapics*(madt: ptr Madt): ptr LocalApic =
  for intCtrlStruct in intCtrlStructs(madt):
    if intCtrlStruct.typ == ictLocalApic:
      yield cast[ptr LocalApic](intCtrlStruct)


# I/O APICs
iterator ioapics*(madt: ptr Madt): ptr Ioapic =
  for intCtrlStruct in intCtrlStructs(madt):
    if intCtrlStruct.typ == ictIoapic:
      yield cast[ptr Ioapic](intCtrlStruct)


# Interrupt Source Overrides
iterator interruptSourceOverrides*(madt: ptr Madt): ptr InterruptSourceOverride =
  for intCtrlStruct in intCtrlStructs(madt):
    if intCtrlStruct.typ == ictInterruptSourceOverride:
      yield cast[ptr InterruptSourceOverride](intCtrlStruct)


# Local APIC NMIs
iterator lapicNMIs*(madt: ptr Madt): ptr LocalApicNmi =
  for intCtrlStruct in intCtrlStructs(madt):
    if intCtrlStruct.typ == ictLocalApicNmi:
      yield cast[ptr LocalApicNmi](intCtrlStruct)


proc showMadt*() =
  writeln("")
  writeln("MADT (Multiple APIC Description Table)")
  writeln(&"  Local APIC Address: {madt0.lapicAddress:0>8x}")
  writeln(&"  Flags:              {madt0.flags}")
  writeln("")
  writeln(&"  Interrupt Controller Structures")

  for intCtrlStruct in intCtrlStructs(madt0):
    writeln("")
    writeln(&"    {intCtrlStruct.typ}")
    case intCtrlStruct.typ
      of ictLocalApic:
        let lapic = cast[ptr LocalApic](intCtrlStruct)
        writeln(&"      Processor UID: {lapic.processorUid}")
        writeln(&"      LAPIC ID:      {lapic.lapicId}")
        writeln(&"      Flags:         {lapic.flags}")
      of ictIoApic:
        let ioapic = cast[ptr Ioapic](intCtrlStruct)
        writeln(&"      I/O APIC ID:   {ioapic.id}")
        writeln(&"      Address:       {ioapic.address:0>8x}")
        writeln(&"      GSI Base:      {ioapic.gsiBase}")
      of ictInterruptSourceOverride:
        let intSrcOverride = cast[ptr InterruptSourceOverride](intCtrlStruct)
        writeln(&"      Bus:           {intSrcOverride.bus}")
        writeln(&"      Source:        {intSrcOverride.source}")
        writeln(&"      GSI:           {intSrcOverride.gsi}")
        writeln(&"      Flags:         {intSrcOverride.flags}")
      of ictLocalApicNmi:
        let lapicNmi = cast[ptr LocalApicNmi](intCtrlStruct)
        writeln(&"      Processor UID: {lapicNmi.processorUid:0>2x}h")
        writeln(&"      Flags:         {lapicNmi.flags}")
        writeln(&"      LINT#:         {lapicNmi.lintN}")
      else: discard
