import std/tables

import acpi/[fadt, madt, rsdp, xsdt]
import ../boot/[uefi, uefitypes]


proc init*(sysTable: ptr EfiSystemTable) =
  let configTables = getUefiConfigTables(sysTable)
  var acpiConfigTable = configTables.getOrDefault(EfiAcpi2TableGuid)

  if isNil(acpiConfigTable):
    quit("Cannot find ACPI table")

  rsdp.init(acpiConfigTable)
  xsdt.init(rsdp0.xsdtAddress)
  fadt.init()
  madt.init()
