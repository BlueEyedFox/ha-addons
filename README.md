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

## Neues Add-on hinzufügen

1. Ordner `<slug>/` mit `config.yaml`, `Dockerfile`, `DOCS.md`, `README.md`, `CHANGELOG.md` anlegen.
2. In `config.yaml` `image: ghcr.io/blueeyedfox/ha-addon-<slug>-{arch}` setzen.
3. `<slug>` in der Matrix von `.github/workflows/build.yaml` ergänzen.
4. Nach dem ersten Build das ghcr.io-Paket auf **public** stellen.

Ein Image wird gebaut, sobald sich Dateien im Add-on-Ordner ändern. Zum Veröffentlichen
einer neuen Version `version` in `config.yaml` erhöhen.
