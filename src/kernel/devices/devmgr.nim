#[
  Device Manager
]#

import std/tables

import bga
import pci

type
  PciDeviceInitializer = proc (dev: PciDeviceConfig) {.nimcall.}

let
  PciDevices: Table[(uint16, uint16), PciDeviceInitializer] = {
    (0x1234'u16, 0x1111'u16): bga.initPci,
  }.toTable


proc init*() =
  for pciDevice in enumeratePciBus(0):
    if PciDevices.hasKey((pciDevice.vendorId, pciDevice.deviceId)):
      PciDevices[(pciDevice.vendorId, pciDevice.deviceId)](pciDevice)
