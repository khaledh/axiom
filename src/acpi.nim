import std/tables

import acpi/[fadt, madt, rsdp, xsdt]
import uefi, uefitypes


proc init*(sysTable: ptr EfiSystemTable) =
  let configTables = getUefiConfigTables(sysTable)
  var acpiConfigTable = configTables.getOrDefault(EfiAcpi2TableGuid)

  if isNil(acpiConfigTable):
    quit("Cannot find ACPI table")

  initRsdp(acpiConfigTable)
  initXsdt(rsdp0.xsdtAddress)
  initFadt()
  initMadt()
