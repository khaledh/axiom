import std/strformat

import ../devices/console

type
  Rsdp* = object
    signature*: array[8, uint8]
    checksum*: uint8
    oemId*: array[6, uint8]
    revision*: uint8
    rsdtAddress*: uint32
    length*: uint32
    xsdtAddress*: pointer
    extendedChecksum*: uint8
    reserved*: array[3, uint8]

var
  rsdp0*: ptr Rsdp

proc initRsdp*(acpiConfigTable: pointer) =
  rsdp0 = cast[ptr Rsdp](acpiConfigTable)

proc showRsdp*() =
  writeln("")
  writeln("RSDP")
  writeln(&"  Revision:  {rsdp0.revision:x}")
  writeln(&"  XSDT addr: {cast[uint64](rsdp0.xsdtAddress):0>8x}h")
