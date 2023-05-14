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

import table

type
  Xsdt* = ref object
    hdr: ptr TableDescriptionHeader
    numEntries: int

var
  xsdt0: Xsdt


proc init*(xsdtAddr: pointer) =
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
