# Home Assistant Add-ons

Eigene Add-ons für Home Assistant.

## Installation

[![Repository zu Home Assistant hinzufügen](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FBlueEyedFox%2Fha-addons)

Oder manuell: **Einstellungen → Add-ons → Add-on-Store → ⋮ → Repositories** und
`https://github.com/BlueEyedFox/ha-addons` hinzufügen.

## Add-ons

| Add-on | Beschreibung |
|--------|--------------|
| [OneDev](onedev/) | Git-Server mit CI/CD, Issues und Pull Requests |
| [Heimdall](heimdall/) | Dashboard mit Kacheln für alle Web-Anwendungen |

## Neues Add-on hinzufügen

1. Ordner `<slug>/` mit `config.yaml`, `Dockerfile`, `DOCS.md`, `README.md`, `CHANGELOG.md` anlegen.
2. In `config.yaml` `image: ghcr.io/blueeyedfox/ha-addon-<slug>-{arch}` setzen.
3. `<slug>` in der Standard-Matrix von `.github/workflows/build.yaml` ergänzen.
4. Upstream-Image in `.github/upstream.yaml` eintragen (für automatische Updates).
5. Optional `<slug>/smoke-test.sh <image>` anlegen (ausführbar). Er läuft vor jedem Push des Images.
6. Nach dem ersten Build das ghcr.io-Paket auf **public** stellen.

Ein Image wird gebaut, sobald sich Dateien im Add-on-Ordner ändern. Zum Veröffentlichen
einer neuen Version `version` in `config.yaml` erhöhen.

## Automatische Updates

Der Workflow **Update add-ons** prüft jeden Montag um 04:00 UTC, ob es für die Add-ons in
`.github/upstream.yaml` neue Versionen auf Docker Hub gibt. Falls ja:

1. Er erhöht `version` in `config.yaml`, die `ARG …_VERSION` im `Dockerfile` und ergänzt
   `CHANGELOG.md` auf dem Branch `auto-update`.
2. Er baut das Image und führt den Smoke-Test aus. Bei Erfolg wird das Image nach ghcr.io gepusht.
3. Erst danach wird `main` aktualisiert, und Home Assistant zeigt das Update an.

Schlägt Build oder Smoke-Test fehl, bleibt `main` unverändert, und GitHub verschickt eine
Fehler-Mail. Manuell starten: **Actions → Update add-ons → Run workflow**.
Lokal prüfen: `.github/scripts/check-upstream.sh` (benötigt `curl` und `yq`).

Für Änderungen nur am Add-on (gleiche Upstream-Version) die Version mit Suffix erhöhen,
z. B. `16.9.7-1`.
