import std/strformat

import console

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

  TableDescriptionHeader* {.packed.} = object
    signature*: array[4, char]
    length*: uint32
    revision*: uint8
    checksum*: uint8
    oem_id*: array[6, char]
    oem_table_id*: array[8, char]
    oem_revision*: uint32
    creator_id*: array[4, uint8]
    creator_revision*: uint32

proc dumpRsdp*(rsdp: ptr Rsdp) =
  writeln("")
  writeln("RSDP")
  writeln(&"  Revision: {rsdp.revision:x}")
