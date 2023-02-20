#[
  ACPI: XSDT (eXtended System Description Table)

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
import ../console
import ../lib/memstream


import binarylang
import bitstreams

struct(tableDescHeader, endian = l):
  8: signature[4]
  32: length
  8: revision
  8: checksum
  s: oemId(6)
  s: oemTableId(8)
  32: oemRevision
  s: creatorId(4)
  32: creatorRevision

struct(xsdt, endian = l):
  *tableDescHeader: hdr
  64: entries[(hdr.length - s.getPosition) div 8]

var
  xsdt0: Xsdt

proc newMemoryBitStream(buf: pointer, bufLen: int): BitStream =
  var p = cast[ptr UncheckedArray[byte]](buf)
  result = BitStream(stream: newMemoryStream(p, bufLen))


proc initXsdt*(xsdtAddr: pointer) =
  var bs = newMemoryBitStream(xsdtAddr, 100)
  xsdt0 = xsdt.get(bs)

iterator entries(): ptr TableDescriptionHeader =
  for i in 0 ..< xsdt0.entries.len:
    let tableHdr = cast[ptr TableDescriptionHeader](xsdt0.entries[i])
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
  writeln(&"  Number of Entries: {xsdt0.entries.len}")
  writeln("")

  for hdr in entries():
    writeln(&"  {hdr.signature}  addr={cast[uint64](hdr):0>8x}  length={hdr.length}")
