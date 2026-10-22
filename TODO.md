# Offene Abnahme und Entscheidungen

## Zur Bestätigung

- **Zusätzliche Upstream-Varianten.** Evidenz: `upstream/explicit-interactions` enthält 28 zuvor fehlende Bett-/Schlafsack-Animationsvarianten. Entscheidung: im Batch vollständig integriert, nur für erwachsene menschliche Figuren und mit deutschen Labels. Begründung: ausdrücklich freigegebene Featurebranch-Integration unter Erhalt eigener Positionen. Auswirkung: zusätzliche Auswahlmöglichkeiten an den entsprechenden Möbeln. Bestätigung: reale Positionen/Animationen und gewünschte RP-Verwendung im Spiel abnehmen; die Integration selbst ist umgesetzt.
- **Mausfokus für den Picker.** Evidenz: sichtbare Schließen-Funktion und auswählbare Zeilen sollen normal bedienbar sein; bisher lief die Steuerung über abgefangene Spielinputs. Entscheidung: bewusstes Öffnen nimmt eigenen NUI-Fokus, eigene Fokusprüfung lässt diesen Picker zu, Schließen gibt ihn unmittelbar frei. Begründung: konsistente Maus- und Tastaturbedienung. Auswirkung: während der Auswahl wird nicht gelaufen/gedreht; laufende fremde Menüs müssen weiterhin sperren. Bestätigung: Fixed-size NUI an/aus und gleichzeitige benutzerdefinierte Menüs in RedM prüfen.
- **Diagnosezugang.** Evidenz: bisherige Diagnosebefehle waren unbeschränkt und hatten keinen vollen Resource-Präfix. Entscheidung: serverseitige Adminfreigabe mit Standard-ACEs und bestehender Zatarion-Whitelist, keine zusätzliche aktive VORP-Gruppe. Begründung: vereinbarter Adminstandard, keine neuen Rollenzuweisungen erfinden. Auswirkung: normale Spieler behalten Möbelaktionen, lokale Diagnosen benötigen Teamrechte. Bestätigung: gewünschte zusätzliche Konten nur in einem ausdrücklichen Folgeauftrag ergänzen.

## Ingame-Abnahme

Die früher dokumentierte Drehblockade und die Leistungsverbesserungen mit aktuellem F8-/resmon-Befund prüfen. Beide Richtungen im Stand, Bewegungsabbruch, beide Tasten zugleich, Menü mit/ohne Cursor, Tod beim Sitzen sowie Schach-/Zeppelinübergaben testen. Browser-/Stubprüfungen sind abgeschlossen, ersetzen die realen Natives und andere gleichzeitig laufende Resources nicht. Keine Sitzreservierung oder andere neue Produktfunktion ist dadurch automatisch beauftragt.
