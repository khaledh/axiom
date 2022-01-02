## Axiom OS

This is my attempt at creating a modern 64-bit kernel in Nim.

### Requirements

- Nim 1.6.2
- QEMU
- UEFI BIOS image:
  - Arch: `sudo pacman -S edk2-ovmf`
  - Ubuntu: `sudo apt install ovmf`

### Compile and run

```console
$ nim c --os:any --out:fatimg/EFI/BOOT/BOOTX64.EFI boot.nim
$ qemu-system-x86_64 -bios /usr/share/edk2-ovmf/x64/OVMF_CODE.fd \
    -nic none \
    -drive format=raw,file.driver=vvfat,file.rw=on,file.dir=fatimg \
    -machine q35 \
    -no-reboot \
    -nographic 
```

Note that the above path for `OVMF_CODE.fd` is the default install path on Arch. For Ubuntu use the path ` /usr/share/OVMF/OVMF_CODE.fd` instead.

### License

MIT
