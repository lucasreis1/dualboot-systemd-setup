# Hibernate and reboot

This is a systemd-based helper for a dual-boot Linux machine.

`hibernate-and-reboot.service` temporarily sets `HibernateMode=reboot`, then
requests hibernation. It restores the normal hibernation setting after a normal
resume. If the hibernation action instead restarts the machine, an enabled
boot-time cleanup service restores the setting on the next Linux boot.

`reboot-to-windows.service` sets the UEFI `BootNext` entry, then runs the same
hibernate-and-reboot flow. Linux is hibernated before firmware boots Windows;
the permanent UEFI boot order is unchanged.

## Install

Run from this directory:

```sh
sudo ./install.sh
```

The installer detects the first UEFI boot entry named `Windows Boot Manager`.
To select one explicitly, use:

```sh
sudo ./install.sh --windows-boot-id=0001
```

The selected entry is stored in `/etc/hibernate-and-reboot.conf`. A normal
reinstall preserves an existing configuration; passing `--windows-boot-id`
replaces it.

An enabled boot-time service refreshes that ID on every Linux boot by finding
the first UEFI entry named `Windows Boot Manager`. If no matching entry can be
read, the prior ID is retained, so a temporary firmware or `efibootmgr` failure
does not erase the last known working value.

## Use

```sh
sudo systemctl start hibernate-and-reboot
sudo systemctl start reboot-to-windows
```

The second command requires UEFI and `efibootmgr`.

## Remove

```sh
sudo ./uninstall.sh
```
