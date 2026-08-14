# f2ban-bans

Ein Bash-Script zum Anzeigen, Filtern und Entsperren gesperrter IPs über alle
fail2ban-Jails hinweg – inklusive Bash-Tab-Completion für Jail-Namen.

## Inhalt des Pakets

| Datei                         | Zweck                                              |
|--------------------------------|-----------------------------------------------------|
| `f2ban-bans`                   | Das eigentliche Script (nach `/usr/local/sbin/`)    |
| `f2ban-bans-completion.bash`   | Bash-Completion (nach `/etc/bash_completion.d/`)    |
| `README.md`                    | Diese Dokumentation                                 |

## Voraussetzungen

- Linux mit `bash`
- `fail2ban` installiert und `fail2ban-client` im `$PATH`
- root-Rechte (`fail2ban-client` erfordert das)
- optional: Paket `bash-completion` für die automatische Tab-Vervollständigung

## Installation

### 1. Hauptscript installieren

```bash
sudo cp f2ban-bans /usr/local/sbin/f2ban-bans
sudo chmod 750 /usr/local/sbin/f2ban-bans
sudo chown root:root /usr/local/sbin/f2ban-bans
```

`/usr/local/sbin` liegt normalerweise im `$PATH` von root, danach ist das
Script einfach als `f2ban-bans` von überall aufrufbar.

### 2. Tab-Completion installieren (optional, aber empfohlen)

```bash
sudo cp f2ban-bans-completion.bash /etc/bash_completion.d/f2ban-bans
source /etc/bash_completion.d/f2ban-bans   # für die aktuelle Session
```

Für neue Shells wird die Datei automatisch geladen, sofern das Paket
`bash-completion` installiert ist:

```bash
# Debian/Ubuntu
apt install bash-completion

# RHEL/CentOS/SUSE
dnf install bash-completion    # bzw. zypper install bash-completion
```

**Wichtig:** Achte darauf, wirklich `f2ban-bans-completion.bash` (nicht das
Hauptscript `f2ban-bans`) unter diesem Pfad abzulegen. Siehe
[Troubleshooting](#troubleshooting) für die Folgen einer Verwechslung.

### 3. Installation prüfen

```bash
f2ban-bans -l
complete -p f2ban-bans
```

Die zweite Zeile sollte `complete -F _f2ban_bans_completion f2ban-bans`
ausgeben (nicht `_minimal`).

## Benutzung

```
Verwendung: f2ban-bans [-p Muster] [-j Jail] [-c] [-l] [-u IP] [-h]

  -p MUSTER    Gesperrte IPs per Regex filtern, z. B. '^92\.' oder '92.*'
  -j JAIL      Nur diese Jail statt aller Jails anzeigen/verwenden
  -c           Nur die Anzahl gesperrter IPs pro Jail ausgeben
  -l           Nur die aktiven Jails auflisten und beenden
  -u IP        Diese IP entsperren (alle Jails, oder nur -j Jail)
  -h           Diese Hilfe anzeigen
```

### Beispiele

```bash
# Alle gesperrten IPs, gruppiert nach Jail
f2ban-bans

# Aktive Jails auflisten (z. B. zur Auswahl für -j)
f2ban-bans -l

# Nach Muster filtern – Präfix reicht
f2ban-bans -p 92.

# Shell-Style-Muster wird automatisch in Regex umgewandelt
f2ban-bans -p '92.*'

# Volle Regex ist ebenfalls möglich
f2ban-bans -p '^92\.(1[0-9]|2[0-5])\.'

# Nur eine bestimmte Jail anzeigen
f2ban-bans -j sshd

# Jail + Muster kombinieren
f2ban-bans -j sshd -p 92.

# Nur die Anzahl gesperrter IPs pro Jail (+ Gesamtsumme)
f2ban-bans -c

# IP aus allen Jails entsperren, in denen sie gesperrt ist
f2ban-bans -u 92.1.2.3

# IP nur aus einer bestimmten Jail entsperren
f2ban-bans -u 92.1.2.3 -j sshd
```

### Tab-Completion

Nach der Installation der Completion-Datei:

```bash
f2ban-bans -j <TAB><TAB>
```

listet die aktuell aktiven Jail-Namen zur Auswahl auf.

## Funktionsweise / Eigenschaften

- **Aggregation über alle Jails**: fragt `fail2ban-client status` ab, um die
  Jail-Liste zu ermitteln, und anschließend `fail2ban-client status <jail>`
  je Jail für die gebannten IPs.
- **Sortierung & Deduplizierung**: die Ausgabe wird numerisch nach
  IP-Oktetten sortiert (`92.9.x` vor `92.10.x`) und doppelte Einträge
  werden entfernt.
- **Farbige Ausgabe**: nur aktiv, wenn stdout ein Terminal ist (kein
  ANSI-Code-Müll bei Umleitung in Dateien oder Pipes).
- **Muster-Filterung**: `-p` akzeptiert reguläre Ausdrücke (POSIX ERE).
  Ein einfaches Shell-Muster mit `*` am Ende (z. B. `92.*`) wird
  automatisch in eine passende Regex (`^92\.`) umgewandelt.
- **Root-Pflicht**: das Script bricht mit einer klaren Meldung ab, wenn es
  nicht als root läuft.
- **Source-Schutz**: das Script erkennt, wenn es versehentlich mit `source`
  statt direkt ausgeführt wird, und bricht kontrolliert ab, statt
  `set -euo pipefail` dauerhaft in die aufrufende Shell durchsickern zu
  lassen (siehe Troubleshooting).

## Troubleshooting

### Tab-Completion zeigt Dateinamen/Verzeichnisinhalte statt Jail-Namen

Ursache: `/etc/bash_completion.d/f2ban-bans` enthält nicht die
Completion-Datei, sondern versehentlich das Hauptscript (z. B. durch
Verwechslung beim Kopieren).

Prüfen:
```bash
head -5 /etc/bash_completion.d/f2ban-bans
```
Steht dort `# f2ban-bans - listet gesperrte IPs...` statt
`# Bash-Completion für f2ban-bans`, liegt die falsche Datei dort.

Beheben:
```bash
sudo cp f2ban-bans-completion.bash /etc/bash_completion.d/f2ban-bans
source /etc/bash_completion.d/f2ban-bans
```

### SSH-Session bricht ab mit „unbound variable" (z. B. `LC_BYOBU`)

Ursache: identisch zum obigen Punkt. Wird versehentlich das Hauptscript
(mit `set -euo pipefail`) statt der Completion-Datei automatisch
gesourced, bleibt `set -u` dauerhaft in der interaktiven Shell aktiv.
Referenziert die Shell (oder z. B. byobu) danach eine nicht gesetzte
Variable, terminiert `set -e` + `set -u` die Shell und damit die
SSH-Session.

Beheben: siehe oben. Ab der aktuellen Script-Version ist zusätzlich ein
Source-Schutz eingebaut (`BASH_SOURCE[0]` vs. `$0`-Prüfung), der das
Script bei einem `source`-Aufruf sofort mit einer Fehlermeldung
abbricht, statt die Shell zu beeinflussen – als zweite Absicherung
gegen genau dieses Problem.

### `fail2ban-client` nicht gefunden

```bash
which fail2ban-client
```
Falls leer: fail2ban ist nicht installiert, oder `/usr/bin` bzw. der
entsprechende Pfad fehlt im `$PATH` von root.

### „Dieses Script muss als root laufen"

Mit `sudo f2ban-bans ...` aufrufen, oder als root einloggen.

## Deinstallation

```bash
sudo rm -f /usr/local/sbin/f2ban-bans
sudo rm -f /etc/bash_completion.d/f2ban-bans
```

## Änderungshistorie

- Basis-Script: Statusabfrage über alle Jails, Regex-Filterung
- `-j` Jail-Filter, `-c` Zählmodus
- `-l` Auflistung aktiver Jails
- `-u` direktes Entsperren einer IP
- Numerische Sortierung + Deduplizierung der IP-Ausgabe
- Farbige Terminal-Ausgabe (terminal-sensitiv)
- Bash-Tab-Completion für Jail-Namen
- Source-Schutz gegen versehentliches Einlesen in eine interaktive Shell
