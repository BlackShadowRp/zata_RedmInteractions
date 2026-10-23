# zata_RedmInteractions

Möbel- und Ortsinteraktionen für RedM. Pflege: **Zatarion**. Grundlage ist [kibooks redm-interactions](https://github.com/kibook/redm-interactions); vielen Dank an kibook für das ursprüngliche System. Die Umbenennung macht daraus keine vollständige Eigenentwicklung.

## Überblick

Die Resource sucht passende Stühle, Bänke, Betten, Klaviere, Schlafgelegenheiten und konfigurierte Badeplätze in der Nähe. Spieler wählen eine passende Haltung oder Animation, stehen sofort wieder auf oder drehen sich im Stand mit gehaltenen Pfeiltasten.

Die aktuelle Konfiguration enthält 75 Interaktionseinträge, darunter 28 aus dem zusätzlichen Upstream-Branch übernommene Bett-/Schlafsackvarianten. Die gemeinsamen Modelllisten umfassen 131 Stuhl- und 36 Bankmodelle. Nicht jede Haltung ist für jedes Spielfigurenmodell geeignet.

Eigene Ergänzungen erhalten deutsche Bezeichnungen, Schach- und Zeppelin-Anbindungen, sichere Eingabesperren, sanftes Drehen, Diagnosewerkzeuge und die kompakte klassische Auswahloberfläche.

## Voraussetzungen und Einstieg

Stelle dich in die konfigurierte Reichweite eines passenden Möbels oder Orts. Es werden keine Items, Berufe, Geldzahlungen oder Inventaränderungen benötigt. Allgemeine Spieleraktionen sind öffentlich, Diagnosebefehle sind dem Team vorbehalten.

Bei Tod, Mount-/Fahrzeugnutzung, Kampf, Fesseln, Sturz, Schwimmen, Pause oder blockierenden Menüs werden die normalen Interaktionsinputs gesperrt. Eine absichtlich deaktivierte Resource bietet keine Oberfläche oder Drehung an.

Die 28 zusätzlichen intimen Bett-/Schlafsackposen werden ausschließlich erwachsenen menschlichen Spielfiguren angeboten. Modellabhängige Einschränkungen gelten außerdem für bestimmte Sitz-, Instrument- und Schlafhaltungen.

## Bedienung

**Pfeil nach unten** öffnet die Auswahl oder wechselt während einer bestehenden Haltung zur Posenauswahl. Alternativ `/zata_redminteractions_interact` verwenden. Die Öffnung wird vom Server freigegeben.

Im Picker mit Pfeil hoch/runter wählen, mit Eingabe starten. Home/End springen zum ersten/letzten Eintrag. Die gewählte Zeile scrollt sichtbar mit und markiert das zugehörige Ziel in der Welt. Mausauswahl ist ebenfalls möglich.

„Schließen“ schließt nur die Auswahl und gibt den Fokus frei. Escape beziehungsweise „Nutzung beenden“ beendet zusätzlich die bisherige Haltung oder native/externe Sitzanimation. Außerhalb des Pickers beendet **Pfeil nach oben** eine aktive eigene Interaktion sofort.

**Pfeil links/rechts halten** dreht den stehenden Charakter ohne eigene Drehprompts. Beide Richtungen zusammen, Bewegung oder eine blockierende Aktion stoppen die Drehung sofort.

## Funktionen und Abläufe

Die Suche prüft Interaktionsradius, Objektmodell und Figurenkompatibilität. Feste Badeplätze arbeiten mit Weltkoordinaten; Möbel verwenden relative Offsets und Ausrichtung. Die Auswahl wird lokal zwischengespeichert. Beim Bestätigen werden Eintrag, Version, Kompatibilität und Entfernung erneut geprüft; beliebige Browserkoordinaten werden nicht als Ziel übernommen.

Eine normale Interaktion merkt sich die ursprüngliche Position, stoppt alte Aufgaben und sperrt die Figur während der Haltung. Aufstehen stellt die Ausgangsposition wieder her. Ein Posenwechsel erhält die erste Rückkehrposition.

Animationen haben eine begrenzte Ladezeit. Tod, Abbruch oder ein neuer Start verhindern, dass ein alter Ladevorgang später doch eine Animation aktiviert. Unterbrochene Haltungen werden nicht automatisch neu gestartet.

## Funktionen und Abläufe – Unterbrechung und Anbindungen

Tod, Figurenwechsel, Aufsitzen, Fahrzeuge, Fesseln oder Unterbrechungen lösen die eigene Positionssperre. Bei Tod oder fremder Übernahme werden weder neue Aufgaben gelöscht noch alte Weltpositionen wiederhergestellt.

Erkannte Zeppelinbänke nutzen die vorhandenen Start-/Status-/Stop-Hooks von `zata_Zeppelin`. Ihre Haltung bewegt sich mit dem Rumpf; Aufstehen führt nicht zur alten festen Weltposition. Eine bereits übernommene Zeppelinsteuerung wird nicht nachträglich durch eine Aufgabenlöschung beschädigt.

Wenn `zata_Chess:blocksInteractions()` aktiv ist, übernehmen die Schachprompts. Ohne laufende optionale Integration bleiben normale Möbel nutzbar. Das Verhalten mit bewegten Bänken, Schachkamera und gleichzeitigen Menüs ist weiterhin im Spiel zu prüfen.

## Funktionen und Abläufe – Eingaben und Leistung

Die Drehung verwendet reale Framezeit, standardmäßig 90 Grad pro Sekunde und einen Anlauf von 0,2 Sekunden. Die gehaltenen Tastaturzustände umgehen unzuverlässige Wiederholimpulse der Spielmenütasten. Bei deaktivierten Bewegungscontrols, Zielen, Schießen, Anhängen, Szenarien oder tatsächlicher Bewegung wird nicht gedreht.

Möbelsuche erfolgt alle 500 ms. Pro Suche werden Objekte nur einmal aufgezählt und ihre Positionen innerhalb derselben Suche wiederverwendet. Drehprüfungen laufen nur bei genau einer gehaltenen Richtung.

Feather-/VORP-Menüzustände werden für höchstens 100 ms zwischengespeichert. Vor Auswahl- und Drehbeginn wird frisch geprüft. Leichte `zata_IsMenuOpen`-Exporte werden bevorzugt; fehlen sie, bleibt der bisherige Adapter erhalten. Das ist keine gemessene Zusage einer bestimmten Ingame-CPU-Ersparnis.

## Teamverwaltung

Es gibt keine Admin-NUI, Datenbankpflege oder Spielerinventarverwaltung. Zwei geschützte Diagnosebefehle zeigen im lokalen F8-Log Eingabesperren, Promptzustand und Drehwerte. Sie schalten keine blockierten Controls frei.

Die ausführliche Drehdiagnose läuft nach Freigabe zehn Sekunden mit 500-ms-Abstand. Dabei Chat/Konsole schließen, im Stand beide Richtungen einzeln halten und auf den gemeldeten Blockgrund achten. Außerhalb des freigegebenen Fensters entstehen keine Dreh-Traces.

Serverseitige LogBridge-Meldungen dokumentieren die Freigabe der Diagnose. Die eigentlichen F8-Ausgaben bleiben lokal. Weitere Teamkonten und Gruppen wurden im Batch nicht freigeschaltet.

## Befehle und Rechte

| Befehl | Zugang | Zweck |
|---|---|---|
| `/zata_redminteractions_interact` | Spieler | Auswahl naher Interaktionen |
| `/zata_redminteractions_debug` | Admin | Eingabe-/Promptdiagnose in F8 |
| `/zata_redminteractions_turndebug` | Admin | Zehn Sekunden Drehdiagnose |

Die früheren Namen `zata_interact`, `zata_interactionsdebug` und `zata_interactionsturndebug` werden nicht als Aliase registriert. Spielerfunktionen erhalten keine Adminpflicht; Diagnosefreigaben werden serverseitig geprüft. Die Befehle sind für spielende Clients gedacht, nicht für die Serverkonsole.

Adminzugriff gilt alternativ über aktivierte `zata.admin`, aktivierte `zata.redminteractions`, die konfigurierte Steam64-Whitelist oder eine konfigurierte VORP-Charaktergruppe. Die Gruppenliste ist standardmäßig leer. Whitelistwerte sind Dezimalstrings, Steam-ACE-Identifier sind hexadezimal.

## Befehle und Rechte – ACE-Beispiele

```cfg
add_ace group.zata_redminteractions zata.redminteractions allow
add_principal identifier.license:<Spieler-Lizenz-ID> group.zata_redminteractions
```

Nur für einen einzelnen Account geht auch:

```cfg
add_ace identifier.license:<Spieler-Lizenz-ID> zata.redminteractions allow
```

Globale Admins können `add_ace group.admin zata.admin allow` verwenden. Platzhalter durch den tatsächlichen Identifier ersetzen. Eine VORP-Gruppe ist ein eigener Zugangsweg und keine ACE. Die produktive `server.cfg` enthält die Resourcegruppe und die vorhandene Zatarion-Zuordnung; vorbereitete Teamrollen bleiben kommentiert.

## Hilfe und Grenzen

Ohne passenden Eintrag, bei abgelaufener Auswahl oder einem entfernten Objekt die Auswahl schließen, neu zum Möbel stellen und erneut öffnen. Eine ungültige Auswahl darf weder eine fremde Position übernehmen noch einen unsichtbaren Fokus festhalten.

Beliebige fremde Menüs ohne Fokus, Control-Sperre oder bekannte Ereignisse können nicht universell erkannt werden. Solche Integrationen gehören in `Config.IsInputBlocked`. Ein Menü ohne Fokus/Ereignis kann eine laufende Drehung bis zum nächsten 100-ms-Menüabgleich fortsetzen.

Möbel haben keine globale Mehrspielerreservierung. Native Animationsabschlüsse sind Clientmeldungen; Logs kennzeichnen diese Grenze ausdrücklich. Die Auswahlvalidierung schützt den regulären NUI-Pfad, lokale Native-Effekte lassen sich gegen einen vollständig manipulierten Client damit nicht serverseitig erzwingen.

Ingame-Abnahme für Drehung, NUI-Fokus, Fixed-size NUI, reale Animationsvarianten, Tod, Schach und Zeppelinbänke steht aus. Tests mit Stubs und Browserbildern ersetzen diese Prüfung nicht.

## Installation und Abhängigkeiten

Pflicht ist `uiprompt` aus kibooks redm-uiprompt. Vor `zata_RedmInteractions` starten. Die Auswahl verwendet wieder ihre lokale Schrift und benötigt keine gemeinsame Assetresource. VORP ist ausschließlich für den optionalen Charaktergruppenweg und ergänzende Charakterdaten im Logging nutzbar; die Grundfunktion benötigt kein VORP-Inventar.

Optional: `feather-menu`, `vorp_menu`, `zata_Chess` und `zata_Zeppelin`. Fehlende leichte Menüexports werden kompatibel abgefangen. Der Batch hat diese Abhängigkeiten weder geändert noch neu gestartet.

Es gibt keine Itemdefinitionen, SQL-Seeds oder eigenen Datenbanktabellen. Itemabgleich, manuelle Item-SQL und automatische Schemamigrationen entfallen. Keine leeren SQL-Platzhalter importieren.

## Konfiguration

`Config.Enabled` aktiviert die Resource. `InteractControl`, `StopControl`, `StopLabel` und die vier `Menu*Control`-Werte bestimmen Eingaben. Native Prompts behalten ihre bisherige Standardschrift.

`Config.Turn` enthält Richtungstasten, rohe Tastaturcodes, Geschwindigkeit, Anlauf und Bewegungsschwelle. Rohe Tasten auf `false` setzen, um nur konfigurierte Spielcontrols zu verwenden. `Config.IsInputBlocked` liefert `true`, wenn eine zusätzliche eigene Aktivität sperren soll.

`Config.Interactions` legt Modelle, Radien, Welt-/Relativkoordinaten, Heading, Szenarien, Animationen, Kompatibilität und Effekte fest. `Config.Effects.clean` entfernt Verschmutzung, Blut und Decals der eigenen Figur. Namen von Natives, Modellen und Animationsbibliotheken nicht übersetzen; sichtbare Bezeichnungen liegen in den Übersetzungstabellen.

## Daten und Schnittstellen

Alles bleibt flüchtig: Picker-Auswahl, Sessiontoken, aktuelle Interaktion, Ausgangsposition, Menücache und Diagnosefenster. Disconnect oder Resource-Stopp beendet die jeweilige Sitzung. Es werden keine Inventare, Guthaben oder anderen Spielerbestände gelesen oder geändert.

`server.lua` prüft Diagnoseberechtigungen, gibt öffentliche Auswahlöffnungen frei und nimmt ausschließlich begrenzte Auditereignisse mit passenden Sessiontoken und konfigurierten Aktionskennungen an. Spielerkennung und Koordinaten kommen vom Server. Ein Clientstart wird ausdrücklich als gemeldeter Start und nicht als bewiesener nativer Erfolg protokolliert.

LogBridge verwendet den exakten Alias `zata_RedmInteractions`. Reportschalter trennen Picker, Interaktionen, Adminfreigaben und Sicherheit. Meldungen sind UTF-8-sicher begrenzt/geteilt, Mentions deaktiviert. Keine Tick-/Positionslogs, keine eigenen HTTP-Retries; Loggingfehler blockieren keine Spielerfunktion.

## Betrieb und Wartung

Im Batch wurden die relevanten Upstream-Historien und lokalen Änderungen integriert, auf GitHub gesichert und per Git auf beide Server übernommen. Sicherungsstand: `backup/batch-20261022-bsdev`. Details und Prüfergebnisse stehen in `BATCH_REPORT.md`; eigene Upstream-Anpassungen in `UPGRADE_NOTES.md`.

Die wieder in die Clientpackliste aufgenommene Schrift erfordert ein erneutes Einlesen. Vom Betreiber nach eigener Planung ausführen:

```text
refresh
ensure zata_RedmInteractions
```

Der Batch hat diese Befehle nicht ausgeführt. Die notwendigen ACE-Blöcke wurden auf beiden Servern nur vorbereitet; ihre Änderungen liegen außerhalb des Resource-Repositories. Es fand keine Datenbankänderung statt.

## Entwicklung und Prüfung

`common.lua` enthält Modell-/Szenariolisten und Figurenprüfungen, `config.lua` die Interaktionen. `client.lua` verwaltet Eingaben, Auswahl und Lebenszyklus; `server.lua` Freigaben und LogBridge. `ui/` enthält wieder die kompakte, rechts zentrierte halbtransparente Liste mit Chinese Rocks und weißer Auswahlmarkierung. Unsichtbarer Start, Freigaben, Auswahlvalidierung, Mausbedienung und Schließen bleiben erhalten; lange Listen scrollen ohne Begrenzung auf 50 Einträge.

Vier Lua-Prüfungen: `tests/input_gates_test.lua`, `tests/picker_lifecycle_test.lua`, `tests/config_integration_test.lua`, `tests/server_access_logging_test.lua`. Jeweils mit `lua <Datei>` aus der Resource starten. Sie verwenden Native-, Netzwerk- und HTTP-Stubs.

`node tests/ui_render.cjs` prüft den Picker in acht Größen mit Playwright und Sharp. Module und Browser sind per `PLAYWRIGHT_MODULE`, `SHARP_MODULE` und `BROWSER_EXECUTABLE` austauschbar. Verlustfreie Bilder und Index bleiben unter `tests/render-output/`, ignoriert und außerhalb der Clientpackliste. Unter Linux gegebenenfalls benötigte Browserbibliotheken über `LD_LIBRARY_PATH` bereitstellen.
