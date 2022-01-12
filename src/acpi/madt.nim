import std/strformat

import ../acpi
import ../debug
import ../ioapic

type
  MultipleApicFlag {.size: sizeof(uint32).} = enum
    PcAtCompat  = "PC/AT Compatible PIC"
  MultipleApicFlags = set[MultipleApicFlag]

  MADT* {.packed.} = object
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

  Ioapic* {.packed.} = object
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


proc dumpMadt*(madt: ptr MADT) =
  println("")
  println("MADT (Multiple APIC Description Table")
  println(&"  Local APIC Address: {madt.lapicAddress:0>8x}")
  println(&"  Flags:              {madt.flags}")
  println("")
  println(&"  Interrupt Controller Structures")

  var ioapic: ptr Ioapic

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
        setIoapic(ioapic.ioapicId, ioapic.address, ioapic.gsiBase)
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
