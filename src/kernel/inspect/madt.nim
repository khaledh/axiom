import std/strformat
import std/importutils

import ../acpi/madt {.all.}
import ../acpi/table {.all.}
import ../devices/console

privateAccess(InterruptControllerHeader)
privateAccess(InterruptSourceOverride)
privateAccess(LocalApic)
privateAccess(LocalApicNmi)
privateAccess(Madt)
privateAccess(TableDescriptionHeader)

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
