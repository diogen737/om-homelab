<h1 align="center">om-homelab</h1>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Docker Compose and configuration for my personal homelab: reverse proxy, media server, photo management, and file sharing.

> **Important:** These settings are specific to my personal homelab (paths, users, timezone, hardware). If you use this repo as reference or a starting point, **adjust everything to your own environment**—paths, usernames, passwords, timezone, and hardware (GPU/transcoding backend). Do not run as-is without reviewing and changing values for your use case.

---

## Contents

| File | Purpose |
| ---- | ------- |
| `docker-compose.yml` | Main stack: Nginx Proxy Manager, Jellyfin, Immich (server, ML, Redis, Postgres) |
| `.env.immich` | Immich environment (upload/DB paths, timezone, DB credentials). **Change passwords and paths before use.** |
| `hwaccel.transcoding.yml` | Immich hardware transcoding profiles (CPU, NVENC, QuickSync, RKMPP, VAAPI, VAAPI-WSL) |
| `smb.conf` | Samba share definitions (shared storage, Jellyfin media). **Replace users/paths for your setup.** |

---

## Services

- **Nginx Proxy Manager** — Reverse proxy and TLS (Let’s Encrypt). Ports 80, 81, 443. Data under `/srv/nginx-proxy-manager`.
- **Jellyfin** — Media server with GPU passthrough (`/dev/dri/renderD128`). Config/cache/media under `/srv/jellyfin`. Bound to localhost only; access via NPM.
- **Immich** — Photo/video library (server + ML + Redis + Postgres). Uses VAAPI for transcoding (see `hwaccel.transcoding.yml`). Upload and DB paths and secrets are in `.env.immich`.

---

## Usage notes

1. **Paths** — All `/srv/...` paths are for this host. Create the directories you need and point volumes/env vars to your own paths.
2. **Secrets** — Set strong `DB_PASSWORD` (and any other secrets) in `.env.immich`; the sample value is for reference only.
3. **Transcoding** — Immich extends `hwaccel.transcoding.yml` with `service: vaapi`. Change to `nvenc`, `quicksync`, `rkmpp`, `vaapi`, or `vaapi-wsl` to match your hardware.
4. **Samba** — `smb.conf` uses a specific user and paths; update `valid users` and `path` for your system and users.
5. **Immich install** — Prefer the [official Immich Docker Compose guide](https://docs.immich.app/install/docker-compose) and the [release compose file](https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml); this repo’s Immich section is tailored to this homelab.

---

## License

MIT — see [LICENSE](LICENSE).
