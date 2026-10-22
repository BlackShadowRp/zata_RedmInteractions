# Eigene Änderungen an kibooks redm-interactions

## Herkunft und Vergleichsstände

Original: https://github.com/kibook/redm-interactions, Remote `upstream`. Das Organisationsrepository ist ein öffentliches Fork unter https://github.com/BlackShadowRp/zata_RedmInteractions, Arbeitsbranch `master`. Pflege: Zatarion. Dank und ursprüngliche Urheberschaft von kibook bleiben ausdrücklich erhalten.

Geprüfter Original-Master: `02374f5eeed2f7bc1dd1137d4fc810518bfab2b0`. Bereits vorhandene eigene Basis laut Historie: BlackShadowRp `51e7246`, einschließlich angepasster Betten und Bezeichnungen. Lokaler Ausgangsstand des Batches: `09f90ac`; BS-Live hatte `4405284`. Die fünf nachfolgenden Commits betreffen Zeppelinbänke und Schachsperren, nicht einen neuen Hersteller-Release.

Ungesicherte Performancearbeit wurde in `197575a` auf `backup/batch-20261022-bsdev` erhalten. Vollständige Zusammenführung des Featurebranches `upstream/explicit-interactions` bei `213ba17` in Integrationscommit `2139b2c57b32ddd156257b061c33c2104899ac09`. Beide Upstreamspitzen sind als Vorfahren enthalten. Beim nächsten Update zunächst Master und relevante Featurebranches fetchen und die tatsächlichen Diffs prüfen; eigene Dateien nicht durch einen frischen Upstream-Checkout ersetzen.

## Config, Modelle und Übersetzungen

`config.lua` und `common.lua` erhalten eigene Bettpositionen einschließlich `p_bed01x`, `p_bed15brassx`, `p_bedking01x` sowie die konkrete Hausbadewanne. Der einzige Featurebranch-Konflikt lag am Listenende: Hausbadewanne behalten, alle 28 zusätzlichen Bett-/Schlafsackvarianten ergänzen. Die alte generische Badewanne nicht versehentlich über die lokale Hausposition zurücksetzen.

Neue intime Varianten sind an `IsPedAdult` gebunden. Die Figuren-/Geschlechtsprüfungen in `common.lua` und die Verwendung von Kompatibilitätsrückgaben in `client.lua` werten native Boolean-/0-/1-Werte korrekt aus; unbekannte Adult-Rückgaben geben die Varianten nicht frei. Die aktuelle Liste hat 75 Einträge, gemeinsame Modellgruppen enthalten 131 Stuhl- und 36 Bankmodelle.

`translations_scenarios.lua` und `translations_props.lua` enthalten deutsche Szenario-/Objektnamen. Badeanimationen und Seitenbezeichnungen besitzen nun tatsächliche Übersetzungen statt leerer Fallbacks. Technische Modell-, Animationsdict- und Szenariokennungen bleiben unverändert. Bei Upstream-Updates neue technische Schlüssel hinzufügen, sichtbare Namen separat übersetzen.

## Eingaben, Drehung und Lebenszyklus

`client.lua` ergänzt getrennte Pfeil-nach-unten-Auswahl und sofortiges Pfeil-nach-oben-Aufstehen, lautloses Links-/Rechts-Drehen mit Framezeit, Geschwindigkeit, Beschleunigung und rohem gehaltenem Tastaturzustand. Beide Tasten zusammen, Bewegung, deaktivierte Controls, Mount/Fahrzeuge, Kampf, Tod, Fesseln, Szenarien und blockierende Menüs stoppen die Drehung. Es entstehen keine Drehprompts.

Picker und aktive Haltung sind getrennt. Posenwechsel behalten die erste Rückkehrposition. Normales Aufstehen stellt diese wieder her; Tod oder externe Übernahme lösen nur die eigene Sperre und dürfen neue Aufgaben/Positionen nicht zerstören. Unterbrochene Haltungen werden nicht automatisch neu gestartet. Escape/Nutzung beenden kann auch eine native/externe Sitzanimation lösen; „Schließen“ schließt nur den Picker.

Animationsladen ist auf fünf Sekunden begrenzt und durch Generationen gegen verspäteten Start nach Stop/Abbruch geschützt. Ungültige, veraltete, entfernte oder inkompatible NUI-Auswahlen schließen sicher und geben den eigenen Fokus frei. Browserkoordinaten und frei übermittelte Animationsnamen ersetzen keine zuvor ermittelte Auswahl.

## Menüadapter und Suchkosten

Menüabfragen verwenden bevorzugt `zata_IsMenuOpen` von Feather/VORP und andernfalls die bisherigen API-Adapter. Fehlende leichte Exporte werden bis zum nächsten Provider-Stopp nicht ständig erneut versucht. Ereignisse und Provider-Stopp invalidieren den 100-ms-Cache, Interaktions-/Drehbeginn prüft frisch. NUI-Fokus und schnelle physische Sperren bleiben framebezogen; eigener Picker-Fokus wird gezielt ausgenommen.

Möbelsuche alle 500 ms, genau eine Objektenumeration und pro Objekt eine Positionslesung je Suche. Keine veralteten Snapshots zwischen Suchen. Aufwendige Drehprüfungen nur bei genau einer gehaltenen Richtung. Die Tests belegen Aufrufzahlen und Sperren; echte CPU-Ersparnis mit resmon/Profiler im Spiel messen. Provideranpassungen wurden innerhalb dieses Batches nicht übertragen.

## Zeppelin und Schach

`StartInteractionAtObject` fragt `zata_Zeppelin:client:startBenchInteraction` vor der Weltkoordinatenumrechnung. Erkennt der Adapter die Bank, darf nur dessen bestätigter Start die Interaktion übernehmen. Für normale Möbel bleibt der bisherige Start erhalten; anschließend kann `benchInteractionStarted` eine erkannte mitbewegte Bank übernehmen. Der Nachstart-Hook läuft nur bei tatsächlich gesetzter aktueller Interaktion.

Zeppelininteraktionen sind mit `zeppelinBench` markiert und kehren nicht an eine alte feste Weltposition zurück. Eigene Aufgaben werden vor dem Stop-Hook beendet, damit dessen Deck-Warmup nicht durch nachträgliches `ClearPedTasksImmediately` gelöst wird. `benchInteractionEnded` räumt nur den eigenen Zustand auf. `benchInteractionActive` fragt die lokale Sitzverwaltung ab und berücksichtigt die begrenzte Eintrittsphase; ein generisches Szenario darf zu einem anderen Punkt derselben Bank auflösen.

`zata_Chess:blocksInteractions()` blendet eigene Möbelprompts während Platzierung, Sitz und Brettkamera aus. Fehlt Resource oder Export, bleibt die normale Funktion erhalten. Bei einem Upstream-Update alle fünf Zeppelin-Hooks und den Schachexport zusammen prüfen.

## NUI, Freigaben und Logging

`ui/` verwendet eine zentrale 1920×1080-Designfläche, proportionale Skalierung, transparenten unsichtbaren Start, RDR Lino/Cormorant und Shared-Rahmen/-Materialien. Einzelne Listenzeilen bleiben ohne Zwischenraum. Der Auswahlrahmen scrollt nicht mit. Alle ermittelten Zeilen bleiben erreichbar; die frühere stille Beschränkung auf 50 entfällt. Beschriftungen werden als Text eingefügt, nicht als ausführbares HTML.

`client.lua` hält pro Öffnung die tatsächliche Auswahl und eine Version. `server.lua` gibt öffentliche Öffnungen sowie geschützte Diagnosen frei. Diagnose-Commands haben das vollständige Präfix `zata_redminteractions`; alte Aliase entfallen. Admin-ACE, Script-ACE, Steam64 und optionale aktuelle VORP-Charaktergruppe sind getrennte ODER-Wege.

Shared-Config und neues Serverscript stehen im Manifest, `uiprompt`/`unbrokenassets` sind Pflichtabhängigkeiten. Alte lokale Schrift nicht mehr ausliefern. Das neue Manifest erfordert `refresh` vor `ensure zata_RedmInteractions`.

LogBridge erhält Picker-Lebenszyklus, konfigurierte gemeldete Interaktionsstarts/-fehler/-enden, Diagnosefreigaben/-ablehnungen sowie Disconnect/Stopp. Native Clientwirkungen werden nicht als serverseitig bewiesen dargestellt. Identität/Koordinaten kommen vom Server; UTF-8-Aufteilung, Audit-ID, Reportschalter, gesperrte Mentions und nicht blockierende HTTP-Fehler erhalten. Kein Item- oder Datenbanksystem hinzufügen: Diese Resource hat keine entsprechenden Definitionen oder Migrationen.

## Wiederholbare Prüfungen

Vier Lua-Prüfungen unter `tests/`: Eingabesperren/Drehung/Adapter und Aufrufzahlen; Picker-Lebenszyklus mit Fokus, Auswahlvalidierung und Ladeabbruch; vollständige Featurebranch-Konfiguration und native Rückgaben; zentrale Rechte, Sessiontoken, Auditkennungen und HTTP-/Unicodegrenzen. Netzwerk, Natives und HTTP sind dabei gestubbt.

`tests/ui_render.cjs` rendert 120 verlustfreie WebPs in den acht vereinbarten Auflösungen. Ausgabe lokal unter `tests/render-output/`, nie committen oder packen. Dokumentierter Assetabgleich: 24 benötigte Shared-Dateien auf beiden Servern bytegleich.

Weiter im Spiel prüfen: Fixed-size NUI an/aus, Pfeile und Maus, Fokusfreigabe, Tod während der Haltung, reale Animationsdictionaries, Schach und bewegte Zeppelinbänke, weitere Menüs sowie tatsächliche resmon-Kosten. Frühere Berichte über Drehblockaden sind ohne neue F8-/Ingame-Beobachtung keine neu bestätigte Diagnose. Vollständiger Batchnachweis: `BATCH_REPORT.md`.
