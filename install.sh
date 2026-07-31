#!/bin/sh
set -eu

usage() {
  echo "Usage: sudo ./install.sh [--windows-boot-id=NNNN]" >&2
}

if [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

windows_boot_id=""
if [ "$#" -gt 0 ]; then
  case "$1" in
    --windows-boot-id=*) windows_boot_id=${1#*=} ;;
    *) usage; exit 2 ;;
  esac
fi

if [ -n "$windows_boot_id" ] && ! printf '%s\n' "$windows_boot_id" | grep -Eq '^[0-9A-Fa-f]{4}$'; then
  echo "Windows boot ID must be four hexadecimal characters, for example 0001." >&2
  exit 2
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this installer as root, for example: sudo ./install.sh" >&2
  exit 1
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config_dir=/etc/systemd/sleep.conf.d
unit_dir=/etc/systemd/system
state_dir=/var/lib/hibernate-and-reboot
windows_config=/etc/hibernate-and-reboot.conf

command -v systemctl >/dev/null 2>&1 || {
  echo "systemctl is required." >&2
  exit 1
}

install -D -m 0644 "$script_dir/sleep.conf.d/90-hibernate-and-reboot.conf" \
  "$config_dir/90-hibernate-and-reboot.conf"
install -D -m 0644 "$script_dir/systemd/hibernate-and-reboot.service" \
  "$unit_dir/hibernate-and-reboot.service"
install -D -m 0644 "$script_dir/systemd/hibernate-and-reboot-cleanup.service" \
  "$unit_dir/hibernate-and-reboot-cleanup.service"
install -D -m 0644 "$script_dir/systemd/reboot-to-windows.service" \
  "$unit_dir/reboot-to-windows.service"
install -D -m 0644 "$script_dir/systemd/update-windows-boot-id.service" \
  "$unit_dir/update-windows-boot-id.service"
install -D -m 0755 "$script_dir/lib/update-windows-boot-id" \
  /usr/local/lib/hibernate-and-reboot/update-windows-boot-id
# Remove the helper location used by an earlier version of this installer.
rm -f /usr/local/libexec/hibernate-and-reboot/update-windows-boot-id
rmdir /usr/local/libexec/hibernate-and-reboot 2>/dev/null || true
install -d -m 0755 "$state_dir"

if [ ! -e "$windows_config" ] || [ -n "$windows_boot_id" ]; then
  if [ -z "$windows_boot_id" ] && command -v efibootmgr >/dev/null 2>&1; then
    windows_boot_id=$(efibootmgr 2>/dev/null | awk '
      /^Boot[[:xdigit:]]{4}\*?[[:space:]]+Windows Boot Manager/ {
        id = substr($1, 5, 4)
        gsub(/\*/, "", id)
        print id
        exit
      }
    ' || true)
  fi

  umask 022
  printf 'WINDOWS_BOOT_ID=%s\n' "$windows_boot_id" > "$windows_config"
fi

systemctl daemon-reload
systemctl enable hibernate-and-reboot-cleanup.service
systemctl enable update-windows-boot-id.service

echo "Installed. Run: sudo systemctl start hibernate-and-reboot"
if grep -Eq '^WINDOWS_BOOT_ID=[0-9A-Fa-f]{4}$' "$windows_config"; then
  echo "Windows BootNext is configured. Run: sudo systemctl start reboot-to-windows"
else
  echo "Windows BootNext is not configured. Re-run with --windows-boot-id=NNNN or edit $windows_config."
fi
