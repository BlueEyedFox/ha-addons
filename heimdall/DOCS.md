# Heimdall

[Heimdall](https://heimdall.site) ist ein Dashboard, auf dem du Links zu deinen
Web-Anwendungen als Kacheln ablegst. Für viele Anwendungen gibt es „Enhanced Apps“,
die direkt Statuswerte anzeigen (z. B. laufende Downloads).

## Ersteinrichtung

1. Add-on starten und **Web-UI öffnen** (Port `8002`).
2. Über **Application list → Add** die ersten Kacheln anlegen.
3. Optional unter **Users** ein Passwort für den Admin-Benutzer setzen. Ohne Passwort
   kann jeder im Netzwerk das Dashboard bearbeiten.

Die Weboberfläche ist nicht in die HA-Seitenleiste eingebunden (kein Ingress). Du kannst
sie aber als Webseiten-Dashboard (*Einstellungen → Dashboards → Webseite*) einbinden.

## Ports

| Port     | Zweck                      |
|----------|----------------------------|
| `80/tcp` | Weboberfläche (HTTP), auf dem Host standardmäßig `8002` |

## Optionen

| Option | Beschreibung |
|--------|--------------|
| `PUID` | Benutzer-ID, unter der Heimdall läuft (Standard `1001`) |
| `PGID` | Gruppen-ID, unter der Heimdall läuft (Standard `1001`) |
| `TZ`   | Zeitzone, z. B. `Europe/Berlin` (optional, sonst UTC) |

## Daten und Backup

Alle Daten (Datenbank, hochgeladene Icons, nginx- und PHP-Konfiguration) liegen im
Konfigurationsordner des Add-ons, auf dem Host unter `/addon_configs/<id>_heimdall/`.
Er wird von Home-Assistant-Backups erfasst. Das Add-on wird für die Dauer eines Backups
gestoppt (`backup: cold`), damit die SQLite-Datenbank konsistent gesichert wird.

## Umstieg von einem anderen Heimdall-Add-on

Daten werden nicht automatisch übernommen. Exportiere die Einstellungen im alten Heimdall
über die Export-Funktion der App und importiere sie im neuen Heimdall wieder.

Beide Add-ons nutzen standardmäßig Port `8002`. Stoppe das alte Add-on vor dem ersten
Start dieses Add-ons.
