# OneDev Agent

Ein [OneDev-Agent](https://docs.onedev.io/administration-guide/agent-management) verbindet
sich mit einem OneDev-Server und führt dessen CI/CD-Jobs aus. Das Add-on entspricht

```bash
docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd)/agent/work:/agent/work \
    -e serverUrl=… -e agentToken=… 1dev/agent
```

Der Server kann das OneDev-Add-on aus diesem Repository oder eine beliebige andere OneDev-Instanz sein.

## Einrichtung

1. In OneDev unter *Administration → Agents → Add Agent* ein Token erzeugen.
2. `server_url` und `agent_token` in den Add-on-Optionen eintragen.
3. Für Docker-Jobs den **Schutzmodus** des Add-ons deaktivieren (siehe unten).
4. Add-on starten. Der Agent erscheint in OneDev unter *Administration → Agents*.
5. In OneDev unter *Administration → Job Executors* einen **Remote Docker Executor**
   (Docker-Jobs) oder **Remote Shell Executor** (Shell-Jobs im Agent-Container) anlegen.

## Docker-Zugriff und Schutzmodus

Docker-Jobs startet der Agent als Container über den Docker-Daemon des Hosts. Den Zugriff
darauf gibt der Supervisor nur frei, wenn der **Schutzmodus** auf der Info-Seite des
Add-ons ausgeschaltet ist. Ohne Docker-Zugriff funktionieren nur Shell-Jobs.

Damit erhalten der Agent und alle Jobs, die er ausführt, vollen Zugriff auf den Host.
Verbinde ihn nur mit einem Server, dessen Build-Specs du vertraust.

Der Supervisor zählt fremde Container auf dem Host als nicht unterstützte Software. Solange
ein Job läuft, kann Home Assistant deshalb eine entsprechende Warnung anzeigen.

## Optionen

| Option               | Beschreibung |
|----------------------|--------------|
| `server_url`         | Adresse des OneDev-Servers, z. B. `https://onedev.example.com` |
| `agent_token`        | Agent-Token aus OneDev; jedes Token kann nur ein Agent nutzen |
| `agent_name`         | Name in OneDev; leer = Hostname des Add-ons |
| `attributes`         | Agent-Attribute als Liste von `name`/`value`, z. B. für Job-Executor-Filter |
| `max_memory_percent` | Maximaler Anteil des Arbeitsspeichers für die Java-VM (Standard `50`) |
| `trust_certs`        | Zertifikatsdateien (PEM), denen der Agent zusätzlich vertraut; relativ zu `/ssl` |
| `http_proxy`, `https_proxy`, `no_proxy` | Proxy-Einstellungen für die Verbindung zum Server |

Beispiel:

```yaml
server_url: https://onedev.example.com
agent_token: "!secret onedev_agent_token"
agent_name: homeassistant
attributes:
  - name: os
    value: linux
max_memory_percent: 50
trust_certs:
  - onedev-ca.pem
```

### Token aus `secrets.yaml`

`agent_token` kann auf einen Eintrag in der `secrets.yaml` von Home Assistant verweisen
(`"!secret onedev_agent_token"`). Nach einer Änderung in `secrets.yaml` das Add-on neu starten.

### Selbst signierte Zertifikate

Nutzt der Server ein Zertifikat einer eigenen CA, die CA-Datei nach `/ssl` legen (z. B. mit
dem File-Editor- oder Samba-Add-on) und unter `trust_certs` eintragen.

## Arbeitsverzeichnis und Backup

Das Arbeitsverzeichnis des Agents (`/agent/work` mit Job-Workspaces und Caches) liegt im
Add-on-Konfigurationsordner `/addon_configs/<id>_onedev-agent`. Der Agent ermittelt daraus
den Host-Pfad, den er in Job-Container einbindet.

Der Inhalt wird nicht gesichert: Caches und Workspaces lassen sich jederzeit neu erzeugen,
und die Optionen speichert der Supervisor separat.

## Updates

Der Agent aktualisiert seine Programmdateien beim Verbinden selbst auf die Version des
Servers. Das Add-on muss daher nicht zur Server-Version passen.
