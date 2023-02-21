#[
  ACPI: XSDt0 (eXtended System Description Table)

  Responsibilities:
  - ???

  Requires:
  - acpi.rsdp

  Provides:
  - acpi.tables.xsdt
]#

import std/options
import std/strformat

import table
import ../devices/console

type
  Xsdt* = ref object
    hdr: ptr TableDescriptionHeader
    numEntries: int

var
  xsdt0: Xsdt


proc initXsdt*(xsdtAddr: pointer) =
  xsdt0 = new(Xsdt)
  let hdr = cast[ptr TableDescriptionHeader](xsdtAddr)
  xsdt0.hdr = hdr
  xsdt0.numEntries = (hdr.length.int - sizeof(TableDescriptionHeader)) div 8



iterator entries(): ptr TableDescriptionHeader =
  for i in 0 ..< xsdt0.numEntries:
    let tablePtrLoc = cast[ptr uint64](cast[int](xsdt0.hdr) + sizeof(TableDescriptionHeader) + i.int * 8)
    let tableHdr = cast[ptr TableDescriptionHeader](tablePtrLoc[])
    yield tableHdr
 

proc findBySignature*(sig: array[4, char]): Option[ptr TableDescriptionHeader] =
  for hdr in entries():
    if hdr.signature == sig:
      return some(hdr)


proc showXsdt*() =
  writeln("")
  writeln("XSDT")
  writeln(&"  Address: {cast[uint64](xsdt0.hdr):8>x}h")
  writeln(&"  Revision: {xsdt0.hdr.revision}h")
  writeln(&"  Number of Entries: {xsdt0.numEntries}")
  writeln("")

  for hdr in entries():
    writeln(&"  {hdr.signature}  addr={cast[uint64](hdr):0>8x}  length={hdr.length}")
