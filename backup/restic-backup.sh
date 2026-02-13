#!/bin/bash

set -Eeuo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "❌ This script must be run as root"
  exit 1
fi

BACKUP_ENV_FILE=/home/om/dev/om-homelab/backup/.env.restic
DOCKER_STOPPED=false
NOW="$(date '+%Y-%m-%d %H:%M:%S')"
HOSTNAME="$(hostname)"

cleanup() {
	echo "🧹 Cleaning up..."
	rm -f $IMMICH_DB_BACKUP_LOCATION

	if [ "$DOCKER_STOPPED" == true ]; then
		docker compose -f $DOCKER_COMPOSE_FILE start > /dev/null
	fi
}

send_telegram() {
  local message="$1"

  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="${TELEGRAM_CHAT_ID}" \
    -d text="${message}" \
    -d disable_notification=true \
    >/dev/null
}

trap cleanup EXIT
trap 'echo "❌ Failed at line $LINENO"' ERR
trap 'send_telegram "❌ Backup FAILED on ${HOSTNAME} at ${NOW} (line ${LINENO})"' ERR

prepare()  {
	set -a
	source $BACKUP_ENV_FILE
	set +a

	echo "💾 Preparing database backup..."
	docker exec -t immich_postgres pg_dumpall --clean --if-exists --username=postgres > $IMMICH_DB_BACKUP_LOCATION

	docker compose -f $DOCKER_COMPOSE_FILE stop
	DOCKER_STOPPED=true
}

backup() {
	echo "📦 Backing up data..."
	# --- Run restic backup ---
	BACKUP_OUTPUT=$(
		restic backup \
			$IMMICH_DB_BACKUP_LOCATION \
			/srv/jellyfin/config \
			/srv/immich \
			/srv/nginx-proxy-manager \
			/var/lib/docker/volumes/om-homelab_grafana-data \
			/srv/samba \
			--exclude /srv/immich/library/encoded-video \
			--exclude /srv/immich/library/thumbs \
			--no-scan
			--json
	)

	# --- Get added bytes ---
	ADDED_BYTES=$(echo "$BACKUP_OUTPUT" | jq -r 'select(.message_type=="summary") | .data_added')
	ADDED_HUMAN=$(numfmt --to=iec "$ADDED_BYTES")

	# --- Get total repo size ---
	STATS_OUTPUT=$(restic stats --mode raw-data --json)
	TOTAL_BYTES=$(echo "$STATS_OUTPUT" | jq -r '.total_size')
	TOTAL_HUMAN=$(numfmt --to=iec "$TOTAL_BYTES")

	# --- Prune old snapshots ---
	restic forget \
		--keep-daily 7 \
		--keep-weekly 4 \
		--keep-monthly 6 \
		--prune
}

main() {
	START_TIME=$(date +%s)
	prepare
	backup

	END_TIME=$(date +%s)
	DURATION=$((END_TIME - START_TIME))

	send_telegram "✅ Backup SUCCESS on ${HOSTNAME}
💾 Added: ${ADDED_HUMAN}
📦 Repo size: ${TOTAL_HUMAN}
⏱️ Duration: ${DURATION}s"
	exit 0
}

main
