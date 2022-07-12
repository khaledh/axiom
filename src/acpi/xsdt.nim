#[
  ACPI: XSDT (eXtended System Description Table)

  Responsibilities:
  - ???

  Requires:
  - acpi.rsdp

  Provides:
  - acpi.tables.xsdt
]#

import std/strformat
import std/tables

import ../acpi
import ../console

type
  Xsdt* = object
    hdr*: ptr TableDescriptionHeader
    entries*: Table[array[4, char], ptr TableDescriptionHeader]


proc initXsdt*(rsdp: ptr Rsdp): Xsdt =
  let p = rsdp.xsdtAddress
  let hdr = cast[ptr TableDescriptionHeader](p)
  result.hdr = hdr

  let numEntries = (hdr.length.int - sizeof(TableDescriptionHeader)) div 8
  for i in 0 ..< numEntries:
    let tablePtrLoc = cast[ptr uint64](cast[int](p) + sizeof(TableDescriptionHeader) + i.int * 8)
    let tableHdr = cast[ptr TableDescriptionHeader](tablePtrLoc[])
    result.entries[tableHdr.signature] = tableHdr

proc showXsdt*(xsdt: Xsdt) =
  writeln("")
  writeln("XSDT")
  writeln(&"  Revision: {xsdt.hdr.revision}h")
  writeln(&"  Number of Entries: {xsdt.entries.len}")
  writeln("")

  # var madt: ptr MADT

  for sig, hdr in xsdt.entries:
    # let tablePtrLoc = cast[ptr uint64](cast[int](xsdt) + sizeof(TableDescriptionHeader) + i.int * 8)
    # let table = cast[ptr TableDescriptionHeader](tablePtrLoc[])
    # if table.signature == "APIC":
    #   madt = cast[ptr MADT](table)
    writeln(&"  {sig}  addr={cast[uint64](hdr):0>8x}  length={hdr.length}")
