#!/bin/bash
set -e

source ./backup/restic.env

docker compose down

restic backup \
  /srv/jellyfin/config \
  /srv/immich \
  /srv/nginx-proxy-manager \
	--exclude /srv/immich/library/encoded-video \
	--exclude /srv/immich/library/thumbs \
	--dry-run

docker compose up -d
