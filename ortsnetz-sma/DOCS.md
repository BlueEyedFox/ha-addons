# Ortsnetz-Auslastung SMA

Der SMA Sunny Home Manager 2.0 und das SMA Energy Meter senden ihre Messwerte als
Speedwire-Multicast (SMA-EMETER-Protokoll) ins lokale Netz. Das Add-on empfängt diese
Telegramme ohne Sunny-Portal-Zugang, liest die Spannungen L1–L3 und (beim Home Manager 2.0)
die Netzfrequenz aus und sendet sie direkt nach dem Start und danach alle fünf Minuten an
[ortsnetz-auslastung.de](https://www.ortsnetz-auslastung.de).

Grundlage ist das Script
[`ortsnetz-sma-shm2.py`](https://github.com/thomaslehmann1234/datenerfassung-ortsnetz-auslastung/tree/master/sma-shm2-ortsnetz-auslastung).

## Voraussetzungen

- SMA Sunny Home Manager 2.0 oder SMA Energy Meter (EMETER-20)
- Der Home-Assistant-Host liegt im **selben Netz (Layer 2)** wie der Zähler. Die Telegramme
  gehen an `239.12.255.254`, UDP-Port `9522`, und überqueren keine VLAN- oder Subnetz-Grenzen.
  Access Points filtern Multicast oft – eine Kabelverbindung ist zuverlässiger.
- Das Add-on läuft im Host-Netz von Home Assistant, damit die Telegramme ankommen.

## Ersteinrichtung

1. Optionen setzen (siehe unten), **Testmodus** einschalten und das Add-on starten.
2. Im Reiter **Protokoll** erscheint jede Minute die Seriennummer des Zählers und die
   Messung, die gesendet würde. Spannungen mit einer vorhandenen Anzeige vergleichen.
3. Passt alles, den Testmodus ausschalten und das Add-on neu starten. Im Protokoll steht
   dann alle fünf Minuten `OK: L1=… L2=… L3=… V, f=… Hz`.

## Optionen

| Option | Beschreibung |
|--------|--------------|
| `latitude` | Breitengrad des Messorts, z. B. `52.520008`. Leer: Standort aus Home Assistant |
| `longitude` | Längengrad des Messorts, z. B. `13.404954`. Leer: Standort aus Home Assistant |
| `interface_ip` | IP des HA-Hosts im Zähler-Netz (Standard `0.0.0.0` = Standard-Interface). Bei mehreren Netzwerkkarten oder VLANs setzen |
| `meter_serial` | Seriennummer des Zählers. Nur nötig, wenn mehrere SMA-Zähler senden |
| `send_grid_power` | Netzleistung am Hausanschluss senden (Standard an) |
| `plant_capacity_kwp` | Installierte PV-Leistung in kWp (optional) |
| `battery_capacity_kwh` | Nutzbare Batteriekapazität in kWh (optional) |
| `battery_soc_entity` | Sensor mit dem Batterie-Ladezustand in % (optional) |
| `pv_forecast_entity` | Sensor mit der heutigen PV-Prognose (optional) |
| `dry_run` | Testmodus: Messungen nur im Protokoll anzeigen, nichts senden |

## Zusätzliche Angaben

Neben den Zählerwerten kann das Add-on weitere Angaben an ortsnetz-auslastung.de senden:

- **Netzleistung** (`send_grid_power`): Wirkleistung aller Phasen am Hausanschluss aus
  denselben Zähler-Telegrammen, Bezug positiv, Einspeisung negativ. Gesendet wird der
  Mittelwert aller Telegramme seit der letzten Messung (etwa eines pro Sekunde). Nur
  eingeschaltet lassen, wenn der Zähler am Hausanschluss sitzt (beim Sunny Home Manager 2.0
  üblich). Misst ein SMA Energy Meter nur den Wechselrichter, ausschalten – die API verbietet,
  Wechselrichterleistung als Netzleistung zu senden.
- **Anlagengröße und Batteriekapazität** werden nach jedem Start mit der ersten Messung
  gesendet; der Server speichert sie für den Standort.
- **Batterie-Ladezustand** wird mit jeder Messung aus der angegebenen Entität gelesen.
- **PV-Prognose für heute** wird mit jeder Messung gelesen, z. B. aus Forecast.Solar
  (`sensor.energy_production_today`). Wh und MWh werden in kWh umgerechnet. Die Prognose
  wird nur gesendet, wenn `plant_capacity_kwp` gesetzt ist und sie höchstens 10 kWh je kWp
  beträgt – sonst würde der Server die ganze Messung ablehnen.

Ist eine Entität nicht verfügbar oder nicht numerisch, wird das Feld weggelassen und
einmalig ein Hinweis ins Protokoll geschrieben. Im Testmodus erscheinen alle Felder in der
angezeigten Messung.

**Datenschutz:** Die Koordinaten werden mit jeder Messung an ortsnetz-auslastung.de gesendet.
Ohne eigene Angabe ist das der in Home Assistant hinterlegte Heimstandort. Wer den genauen
Standort nicht übertragen möchte, trägt gerundete Koordinaten ein.

## Fehleranalyse

- `Kein gültiges EMETER-Telegramm … empfangen`: `interface_ip`, `meter_serial` und VLANs
  prüfen. Switches/APs müssen die Multicast-Gruppe weiterleiten (bei IGMP-Snooping den
  Querier prüfen). Sind im Sunny Portal direkte Empfänger eingetragen, sendet der Home Manager
  keinen Multicast mehr; dann den HA-Host zusätzlich als Empfänger eintragen.
- Falscher Zähler: `meter_serial` auf die Seriennummer aus dem Testmodus setzen.
- `LATITUDE muss zwischen … gesetzt sein`: Koordinaten fehlen in den Optionen und in Home
  Assistant.
- `HTTP …`: Die API hat die Messung abgelehnt; Antwort im Protokoll prüfen.
- `Übertragung fehlgeschlagen`: Internetzugang, DNS und Systemzeit prüfen.
