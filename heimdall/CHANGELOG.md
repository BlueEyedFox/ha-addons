# Changelog

## 2.8.3.3

- Versionsschema korrigiert: `2.8.3-2` galt in Home Assistant als älter als `2.8.3`, das
  Update ließ sich daher nicht installieren. Keine funktionale Änderung

## 2.8.3-2

- Automatische Übernahme der Daten aus dem BenoitAnastay-Add-on entfernt. Umzug stattdessen
  über die Export-/Import-Funktion von Heimdall (siehe Dokumentation)
- Kein Zugriff mehr auf `/share`

## 2.8.3-1

- Übernahme der Daten aus dem BenoitAnastay-Add-on korrigiert: Datenbank, `.env`
  (APP_KEY) und hochgeladene Icons/Hintergründe/Avatare aus `/share/heimdall` werden
  übernommen, auch wenn schon eine neue Installation existiert

## 2.8.3

- Erste Version des Add-ons auf Basis von `linuxserver/heimdall:2.8.3`
