import std/importutils
import std/strformat

import ../devices/console
import ../ioapic {.all.}

privateAccess(Ioapic)
privateAccess(IoapicIdRegister)
privateAccess(IoapicVersionRegister)
privateAccess(IoapicRedirectionEntry)


proc show*() =
  let ioapic = ioapic0
  writeln("")
  writeln("I/O APIC")

  let ioapicId = cast[IoApicIdRegister](ioapic.readRegister(0))
  let ioapicVer = cast[IoApicVersionRegister](ioapic.readRegister(1))
  writeln(&"  ID = {ioapicId.id}")
  writeln(&"  Address = {ioapic.address:x}h")
  writeln(&"  Version = {ioapicVer.version:0>2x}h")
  writeln(&"  MaxRedirectionEntry = {ioapicVer.maxRedirEntry}")
  writeln("")
  writeln("  IOREDTBL")
  writeln("       Vector  DeliveryMode  DestMode  Dest  Polarity  TriggerMode  DeliveryStatus  RemoteIRR  Mask")
  for i in 0..ioapicVer.maxRedirEntry:
    let lo = ioapic.readRegister(2*i.int + 0x10)
    let hi = ioapic.readRegister(2*i.int + 0x11)
    let entry = cast[IoapicRedirectionEntry](hi.uint64 shl 32 or lo)
    write(&"  [{i: >2}] {entry.vector:0>2x}h     {entry.deliveryMode: <12}  {entry.destinationMode: <8}  {entry.destination: <4}")
    writeln(&"  {entry.polarity: <8}  {entry.triggerMode: <11}  {entry.deliveryStatus: <14}  {entry.remoteIrr: <9}  {entry.mask}")
