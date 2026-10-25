# OneDev

[OneDev](https://onedev.io) ist ein selbst gehosteter Git-Server mit eingebautem CI/CD,
Issue-Tracking, Pull Requests und Code-Suche.

## Ersteinrichtung

1. Add-on starten und **Web-UI öffnen** (Port `6610`).
2. Im Setup-Assistenten einen Administrator anlegen.
3. Als **Server URL** die Adresse eintragen, unter der du OneDev erreichst,
   z. B. `http://homeassistant.local:6610`. OneDev verwendet sie für Clone-URLs und Links.

Die Weboberfläche ist nicht in die HA-Seitenleiste eingebunden (kein Ingress), weil OneDev
nicht unter einem Unterpfad laufen kann.

## Ports

| Port       | Zweck                     |
|------------|---------------------------|
| `6610/tcp` | Weboberfläche und Git über HTTP(S) |
| `6611/tcp` | Git über SSH              |

Wenn du den SSH-Port im Add-on änderst, passe in OneDev unter
*Administration → System Settings → SSH Root URL* die Adresse an.

## Optionen

Standardmäßig nutzt OneDev die eingebaute HSQLDB-Datenbank. Für mehr Nutzer oder große
Repositories wird eine externe Datenbank empfohlen.

| Option        | Beschreibung |
|---------------|--------------|
| `external_db` | Externe Datenbank statt HSQLDB verwenden |
| `db_type`     | `postgresql`, `mariadb` oder `mysql` |
| `db_url`      | JDBC-URL, z. B. `jdbc:mariadb://core-mariadb:3306/onedev` |
| `db_user`     | Datenbank-Benutzer |
| `db_password` | Datenbank-Passwort |

Die Datenbank muss bereits existieren und leer sein. Ein Wechsel der Datenbank bei
bestehender Installation erfordert einen Export/Import über OneDev
(siehe [OneDev-Doku](https://docs.onedev.io/administration-guide/backup-restore)).

## CI/CD

Das Add-on hat keinen Zugriff auf den Docker-Daemon des Hosts. Verwende in OneDev einen
**Server Shell Executor** oder verbinde externe [OneDev-Agents](https://docs.onedev.io/administration-guide/agent-management)
für Docker-basierte Builds.

## Daten und Backup

Alle Daten (Repositories, Datenbank, Konfiguration) liegen im Add-on-Datenverzeichnis und
werden von Home-Assistant-Backups erfasst. Das Add-on wird für die Dauer eines Backups
gestoppt (`backup: cold`), damit die eingebettete Datenbank konsistent gesichert wird.
