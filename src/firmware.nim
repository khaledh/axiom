import std/strformat

import debug
import uefitypes

proc dumpFirmwareVersion*(sysTable: ptr EfiSystemTable) =
  let uefiMajor = sysTable.header.revision shr 16
  let uefiMinor = sysTable.header.revision and 0xffff
  let fwMajor = sysTable.firmwareRevision shr 16
  let fwMinor = sysTable.firmwareRevision and 0xffff
  let vendor = sysTable.firmwareVendor
  println("Firmware Version")
  print(&"  UEFI {uefiMajor}.{uefiMinor} (")
  printws(vendor)
  println(&", {fwMajor}.{fwMinor})")
