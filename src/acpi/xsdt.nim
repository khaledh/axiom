import std/strformat
import std/tables

import ../acpi
import ../debug

type
  AcpiXsdt* = object
    hdr*: ptr TableDescriptionHeader
    entries*: Table[array[4, char], ptr TableDescriptionHeader]


proc parseXsdt*(p: pointer): AcpiXsdt =
  let hdr = cast[ptr TableDescriptionHeader](p)
  result.hdr = hdr

  let numEntries = (hdr.length.int - sizeof(TableDescriptionHeader)) div 8
  for i in 0 ..< numEntries:
    let tablePtrLoc = cast[ptr uint64](cast[int](p) + sizeof(TableDescriptionHeader) + i.int * 8)
    let tableHdr = cast[ptr TableDescriptionHeader](tablePtrLoc[])
    result.entries[tableHdr.signature] = tableHdr

proc dumpXsdt*(xsdt: AcpiXsdt) =
  println("")
  println("XSDT")
  println(&"  Revision: {xsdt.hdr.revision}h")
  println(&"  Number of Entries: {xsdt.entries.len}")
  println("")

  # var madt: ptr MADT

  for sig, hdr in xsdt.entries:
    # let tablePtrLoc = cast[ptr uint64](cast[int](xsdt) + sizeof(TableDescriptionHeader) + i.int * 8)
    # let table = cast[ptr TableDescriptionHeader](tablePtrLoc[])
    # if table.signature == "APIC":
    #   madt = cast[ptr MADT](table)
    println(&"  {sig}  addr={cast[uint64](hdr):0>8x}  length={hdr.length}")
