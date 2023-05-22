import std/strformat

import ../devices/console
import ../../graphics/font

proc showFont*() =
  writeln("")
  writeln(&"PSF Font: Dina 8x16")
  writeln(&"  Magic    = {dina8x16[0]:0>2x} {dina8x16[1]:0>2x} {dina8x16[2]:0>2x} {dina8x16[3]:0>2x}")
  writeln(&"  Version  = {cast[ptr uint32](addr dina8x16[4])[]}")
  writeln(&"  HdrSize  = {cast[ptr uint32](addr dina8x16[8])[]}")
  writeln(&"  Flags    = {cast[ptr uint32](addr dina8x16[12])[]}")
  writeln(&"  Length   = {cast[ptr uint32](addr dina8x16[16])[]}")
  writeln(&"  CharSize = {cast[ptr uint32](addr dina8x16[20])[]}")
  writeln(&"  Height   = {cast[ptr uint32](addr dina8x16[24])[]}")
  writeln(&"  Width    = {cast[ptr uint32](addr dina8x16[28])[]}")
