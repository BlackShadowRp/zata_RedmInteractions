> Historischer Bericht: Seit 25.10.2026 gilt ausschließlich `role.admin` oder die kanonische Script-ACE; frühere Whitelist-/VORP-Adminfreigaben sind entfernt.

# Batch – zata_RedmInteractions

## Quellen und Integration

Auftrag „zaata_RedmInteractions“ eindeutig als vorhandene Resource `zata_RedmInteractions` aufgelöst. Öffentliches Organisations-Forkrepository, Branch master; Original kibook/redm-interactions, master 02374f5eeed2f7bc1dd1137d4fc810518bfab2b0 bereits enthalten. GitHub-Forkmetadaten und bestehender upstream-Remote bestätigen die Herkunft. Keine anderen Organisationsbranches außer dem vollständigen Sicherungsstand.

BSDev/GitHub vor Beginn 09f90ac; Live 4405284, sauber. Die fünf neueren lokalen/GitHub-Commits erhalten die mitbewegte Zeppelinbank, deren Start-/Stopübergaben und die Schachsperre. Noch nicht gesicherte Performancearbeit wurde als 197575a auf backup/batch-20261022-bsdev gesichert: 100-ms-Menücache, leichte boolesche Menüexports mit kompatiblem Fallback, eine Objektenumeration pro Suche und reduzierte Prüfungen beim inaktiven Drehen. Diese Änderungen bleiben erhalten.

Upstream-Featurebranch explicit-interactions 213ba17 wird mit voller Historie integriert. Er ergänzt 430 Zeilen mit Bett-/Schlafsack-Animationsvarianten. Der einzige Konflikt am Ende von config.lua wird so aufgelöst, dass Kittykats konkrete Badewanne und alle neuen Upstream-Varianten erhalten bleiben. Die Varianten sind an die bestehende IsPedAdult-Kompatibilität gebunden; deren 0/1-Nativerückgabe wird korrekt normalisiert. Technische Animationskennungen und Positionen bleiben unverändert. Kein Feature verworfen; die alte generische Badewanne wird nicht gegen die ausdrücklich vorhandene Hausposition zurückgesetzt.

Gemeinsamer Eintrittsstand und Standardisierung werden nach erfolgreicher Synchronisierung ergänzt. Keine Aktivierung im Batch.

## Bestandsgleichheit vor NUI-Änderung

Vollständiger gemeinsamer Eintrittsstand: `2139b2c57b32ddd156257b061c33c2104899ac09`. BSDev und BS-Live jeweils sauber auf master, GitHub identisch, Fetch von origin/upstream auf beiden Seiten erfolgreich. Upstream master und explicit-interactions vollständig enthalten; keine ungeklärten relevanten Branches. GitHub-Identität `mrumler` und Rechte auf beiden Servern geprüft. Die gemeinsame Kittykat-AGENTS war unlesbar; zugängliche gemeinsame AGENTS verwendet, keine Rechte umgangen.

## Standardisierung und Fehlerkorrekturen

- NUI auf 1920×1080 mit proportionaler Skalierung und rechtem 730×800-Picker. Unsichtbarer transparenter HTML-Start vor externem CSS/JavaScript. Eigener Fokus erst bei bewusster serverseitig freigegebener Öffnung; eigene Fokusausnahme, unmittelbares lokales Schließen und Freigabe bei ungültiger Auswahl, Tod/Stopp und Benutzerabbruch. „Schließen“ erhält eine bestehende Haltung; Escape/Nutzung beenden beendet sie.
- Zentrale RDR-Lino-/Cormorant-Fonts, Gold-Slices, gedimmtes blaues/dunkles Holz, v2-Lederbutton, feste Headeraktionen. Kompakte transparente Auswahlzeilen ohne Zwischenräume, getrennter äußerer Scrollrahmen, Scrollleisten mit Richtungspfeilen. Vorabdekodierung aller verwendeten Grafiken/Fonts. Der Client wartet auf die Browserbereitschaft, bevor er den Picker anbietet oder Fokus nimmt. Keine neuen Rastergrafiken, keine lokalen PNG-Assets zu konvertieren; alte lokale Schrift bleibt Quelle, nicht Clientpackinhalt.
- Keine stille Begrenzung auf 50 Einträge; alle ermittelten Einträge sind erreichbar. Zeilenlabels verwenden textContent statt innerHTML. Browser übermittelt ausschließlich Auswahlindex/Version; tatsächliche Koordinaten/Animationen stammen aus dem zuvor ermittelten lokalen Cache. Figurenkompatibilität, Objektbestand und Reichweite werden erneut geprüft. Ungültige Auswahl kann keinen unsichtbaren Fokus behalten.
- Asynchrone Animationsladung begrenzt und generationengeprüft; Abbruch verhindert verspäteten Start. Kompatibilitätsrückgaben normalisieren Boolean/0/1, einschließlich Geschlechts-/Adultprüfungen. Gleiche Entfernungen mit Objekt-/Ortsmischung führen nicht zu einem nil-Vergleich. Verschwundene Markerobjekte werden verworfen. Bestehende Menü-/Dreh-/Objektsuchoptimierungen und Zeppelin-/Schachübergaben erhalten.
- Neue öffentliche Auswahlfreigabe und geschützte Diagnosen im Serverscript. Alle drei Commands heißen `zata_redminteractions_interact`, `zata_redminteractions_debug`, `zata_redminteractions_turndebug`. Die Spielerfunktion bleibt öffentlich; Diagnose wird über Admin-ACE, Script-ACE, Steam64 oder optional konfigurierte VORP-Charaktergruppe autorisiert. Standardgruppenliste leer, keine neuen Konten/Rollen, keine privilegierten Suggestions.
- Produktive server.cfg beider Server gezielt um alphabetischen `zata_RedmInteractions`-Block ergänzt: eigene Gruppe `group.zata_redminteractions`, ACE `zata.redminteractions`, vorhandene Zatarion-Zuordnung und fünf kommentierte Teamrollenvorlagen. Globale Admin-/Rollenrechte und andere Accounts erhalten. Je Server geschützte Sicherung; Dateien außerhalb des Resourcecommits, nicht aktiviert.

## Hook-Matrix

| Ablauf | Hook und Aussage | Volumen/Felder |
|---|---|---|
| Auswahlöffnung | Serverfreigabe plus passende Session; Client meldet geöffnet | einmal pro Öffnung; Spieler, Koordinaten, Nachricht |
| Auswahl schließen | nur tatsächlich offene bestätigte Session; wiederholtes Schließen ohne Doppelmeldung | einmal; Spieler, Koordinaten, Nachricht |
| Interaktion starten | nur konfigurierte Aktionskennung mit passendem Sessiontoken; ausdrücklich Clientmeldung, kein behaupteter nativer Erfolgsbeweis | pro Start; Interaktion, Nachricht, Serveridentität/-koordinaten |
| Startfehler | Laden, Reichweite/Kompatibilität oder Start fehlgeschlagen | pro Fehler; konfigurierte Interaktion und Ergebnis |
| Interaktionsende | gespeicherte aktive Kennung, Stop/Unterbrechung | pro Ende; kein ungeprüfter Clientname als alter Zustand |
| Diagnosen | zentrale Freigabe/Ablehnung | pro Anfrage; Aktion debug/turndebug und Ergebnis |
| Disconnect/Resource-Stopp | aktive Sitzung beendet | einmal je Sitzung; keine Ticklogs |

Ausschließlich `http://127.0.0.1:50120/api/webhooks/zata_RedmInteractions`. Vorher gab es kein Webhooksystem. Neue Reportschalter je Ereignisklasse. Serveridentität/Koordinaten, UTF-8-sichere Aufteilung großer Meldungen mit Audit-ID, UTF-16-/Discord-Grenzen, gesperrte Mentions, keine eigenen Retries. HTTP-Fehler blockieren keine Spielaktion. Alle HTTP-Prüfungen synthetisch; keine echten externen Nachrichten gesendet.

## Items, Daten und ausgelassene Schritte

Vollständiger Code-/Configabgleich zeigt keine Itemverweise, Inventarexports, Item-Seeds, SQL-Dateien oder eigenen Tabellen. Die einzigen Effekte ändern den lokalen Zustand der eigenen Spielfigur. Deshalb **Iteminventarisierung/Upserts, Item-Sicherung, manuelle Item-SQL und Schemamigrationen entfallen als nicht anwendbar**. Es wurden keine Datenbanken verändert und keine leeren SQL-Platzhalter angelegt. Keine Spielerbestände, Geldwerte oder Inventare übertragen.

24 benötigte Shared-Dateien auf BSDev und BS-Live bytegleich: Fonts, Haupt-/Titelrahmen, Texturen und Buttonteile. Kein Assetqueue-Auftrag erforderlich. Abhängigkeiten unverändert gelassen; ihre optionalen leichten Menüexports besitzen einen getesteten Fallback.

Suche nach alten Commands in lesbaren Lua-/JS-/Markdown-Dateien unter zata, NSS, Kittykat und Missy ergab nur die eigene historische Dokumentation. Drei unlesbare Prüfunterordner in kk_hairaccessories waren ausgenommen; deren Inhalte werden nicht als geprüft behauptet. Keine bekannten externen Aufrufer geändert oder fremde Resource übertragen.

## Prüfergebnisse und Grenzen

Vier Lua-Prüfungen bestanden: ursprüngliche Eingabesperren/Dreh-/Menü-/Suchprüfungen; Picker-Lebenszyklus mit Fokus, invaliden Auswahlwerten und abgebrochener Animation; 28 integrierte Varianten samt erhaltenen lokalen Möbelpositionen und nativen Rückgaben; zentrale Rechte/Sessions/Logginggrenzen mit synthetischen HTTP-Fehlern. Syntax aller Lua-/JS-Dateien separat geprüft, Cfx-Hashliterale für luac neutralisiert.

**120** persistierte verlustfreie WebP-Renderbilder in **1024×768, 1280×720, 1536×864, 1920×1080, 1920×1200, 2560×1440, 3440×1440, 3840×1080**. Szenarien, Animationen, lange Listen mit 180 Einträgen, leere Auswahl, Anfang/Ende, Hover und geschlossener Zustand. Font-/Assetwarmup, unverzerrte Fenstergrenzen, null Zeilenabstand, nicht mitscrollender Rahmen, deutsche Zeichen, escaped HTML-Labels, Tastatur/Callbackindex und blockierte Öffnung bei deaktivierter Resource bestanden. Keine JavaScriptfehler.

Renderbilder/Index verbleiben lokal unter tests/render-output, explizit ignoriert und nicht im Manifest. README hat 16 Sektionen; jede unter 2000 UTF-16-Einheiten. Keine separate FINDINGS-Datei ohne bestätigten verbleibenden Fehler angelegt. Betriebsgrenzen und nötige Ingame-Abnahme stehen in README/TODO: native Startmeldungen nicht serverseitig beweisbar, keine Mehrspieler-Sitzreservierung, fremde unerkannte Menüs benötigen Integrationshook, tatsächliche CPU-/Dreh-/Animations-/Zeppelin-/Schachprüfung ausstehend.

Die bekannten früheren Drehberichte sind ohne neue Spielbeobachtung keine neu bestätigte aktuelle Ursache; der Batch behauptet keine bestandene Ingame-Abnahme. Annahmen mit Evidenz, Entscheidung und Auswirkung stehen unter TODO „Zur Bestätigung“.

## Übergabe

Der finale geprüfte Resource-Stand wird auf master nach BlackShadowRp gepusht und über Git auf BS-Live übernommen. Vollständige finale Commit-ID und Sauberkeit werden im außerhalb der Resource geführten Laufprotokoll festgehalten. Kein Resource-/Server-Neustart, keine sofortige Aktivierung, kein refresh/ensure und keine Datenbankmigration im Batch.

🔴 **REFRESH ERFORDERLICH** – vom Betreiber: `refresh`, anschließend `ensure zata_RedmInteractions`.
