#!/bin/bash

set -Eeuo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "❌ This script must be run as root"
  exit 1
fi

cleanup() {
}

trap cleanup EXIT
trap 'echo "❌ Failed at line $LINENO"' ERR

main() {
	cp ./backup/restic-backup.sh /usr/local/sbin/
	chmod 700 /usr/local/sbin/restic-backup.sh

	cp ./backup/backup.service ./backup/backup.timer /etc/systemd/system/
	mkdir -p /var/cache/restic

	systemctl daemon-reload
	systemctl enable --now backup.timer
	systemctl list-timers | grep backup

	exit 0
}

main
