import std/strformat

import ../uefitypes
import ../../kernel/devices/console


proc showFirmwareVersion*(sysTable: ptr EfiSystemTable) =
  let uefiMajor = sysTable.header.revision shr 16
  let uefiMinor = sysTable.header.revision and 0xffff
  let fwMajor = sysTable.firmwareRevision shr 16
  let fwMinor = sysTable.firmwareRevision and 0xffff
  let vendor = sysTable.firmwareVendor
  writeln("Firmware Version")
  write(&"  UEFI {uefiMajor}.{uefiMinor} (")
  write($vendor)
  writeln(&", {fwMajor}.{fwMinor})")
