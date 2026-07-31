#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this uninstaller as root, for example: sudo ./uninstall.sh" >&2
  exit 1
fi

systemctl disable --now hibernate-and-reboot-cleanup.service 2>/dev/null || true
systemctl disable --now update-windows-boot-id.service 2>/dev/null || true
rm -f /etc/systemd/sleep.conf.d/90-hibernate-and-reboot.conf
rm -f /etc/systemd/system/hibernate-and-reboot.service
rm -f /etc/systemd/system/hibernate-and-reboot-cleanup.service
rm -f /etc/systemd/system/reboot-to-windows.service
rm -f /etc/systemd/system/update-windows-boot-id.service
rm -f /etc/hibernate-and-reboot.conf
rm -f /usr/local/lib/hibernate-and-reboot/update-windows-boot-id
rm -f /usr/local/libexec/hibernate-and-reboot/update-windows-boot-id
rm -f /var/lib/hibernate-and-reboot/pending
rmdir /var/lib/hibernate-and-reboot 2>/dev/null || true
rmdir /usr/local/lib/hibernate-and-reboot 2>/dev/null || true
rmdir /usr/local/libexec/hibernate-and-reboot 2>/dev/null || true
systemctl daemon-reload

echo "Removed hibernate-and-reboot system files."
