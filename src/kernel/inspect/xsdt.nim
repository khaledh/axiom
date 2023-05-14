import std/strformat
import std/importutils

import ../acpi/table {.all.}
import ../acpi/xsdt {.all.}
import ../devices/console

privateAccess(TableDescriptionHeader)
privateAccess(Xsdt)

proc showXsdt*() =
  writeln("")
  writeln("XSDT")
  writeln(&"  Address: {cast[uint64](xsdt0.hdr):8>x}h")
  writeln(&"  Revision: {xsdt0.hdr.revision}h")
  writeln(&"  Number of Entries: {xsdt0.numEntries}")
  writeln("")

  for hdr in entries():
    writeln(&"  {hdr.signature}  addr={cast[uint64](hdr):0>8x}  length={hdr.length}")
