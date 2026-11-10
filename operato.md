# Operato - MyPlaylist

## Sessione 2026-11-09: Implementazione Tags

### Obiettivo
Implementare la gestione dei tag (comma-separated) memorizzati nei file .nfo, visualizzati nella locandina/dettagli video, e disponibili come filtro (simile ai generi).

### File modificati

#### 1. Parser NFO - `lib/utils/nfo_strategies/kodi_nfo_strategy.dart`
- Aggiunta estrazione elementi `<tag>` dal NFO
- Tag uniti come stringa comma-separated nel campo `tags`

#### 2. Generatore NFO - `lib/utils/nfo_generator.dart`
- Aggiunta scrittura elementi `<tag>` per film e serie TV
- Split della stringa tags per creare elementi `<tag>` multipli

#### 3. Database - `lib/database/app_database.dart`
- Aggiunta colonna `tags` alla tabella Videos (schema v7)
- Migrazione per creare colonna tags e indice
- `getValuesWithCounts`: aggiunto case 'tags' con CTE ricorsiva
- `getFilteredPlaylist`: aggiunti parametri `tags` e `excludedTags`
- CRUD (insert, update, _mapDriftToModel): gestione campo tags

#### 4. Modello FilterSettings - `lib/models/filter_settings.dart`
- Aggiunti campi `tags` e `excludedTags` con serializzazione JSON

#### 5. Dialog Filtri - `lib/screens/filter_dialog.dart`
- Aggiunta scheda "Tag" (indice 6) con voce sidebar
- Multi-select tag con include/esclude
- Aggiornamento contatori summary e reset

#### 6. Video Details Dialog - `lib/screens/video_details_dialog.dart`
- Aggiunta sezione visualizzazione tag dopo generi

#### 7. Video Preview Dialog - `lib/screens/video_preview_dialog.dart`
- Aggiunto chip tag nella riga info

#### 8. Localizzazione - `lib/l10n/app_it.arb`, `lib/l10n/app_en.arb`
- `sectionTags`: "TAG" / "TAGS"
- `tabTags`: "Tag" / "Tags"

#### 9. Test aggiornati
- `test/fakes/fake_video_repository.dart`
- `test/statistics_service_test.dart`
- `test/voice_tab_test.dart`

### Verifiche eseguite
- `flutter analyze`: **Nessun errore**
- `flutter test`: **195 test passati**
- `flutter build linux --release`: **Build riuscita**

### Stato: COMPLETATO

## Sessione 2026-11-09: Implementazione Voto Personale (Personal Rating)

### Obiettivo
Aggiungere il "voto personale" (voto che l'utente attribuisce al video), gestito nella scheda 'Modifica Video', visualizzato nella scheda della sezione del poster, e utilizzabile come filtro.

### File modificati

#### 1. Modello Video - `lib/models/video.dart`
- Aggiunto campo `personalRating` (double, default 0.0)
- Aggiornato `fromMap`, `toMap`, `copyWith` per includere `personalRating`

#### 2. Database - `lib/database/app_database.dart`
- Aggiunta colonna `personalRating` alla tabella Videos (schema v8)
- Migrazione per creare colonna e indice
- CRUD (insert, update, _mapDriftToModel): gestione campo `personalRating`
- `getFilteredPlaylist`: aggiunto parametro `personalRatingMin` per filtro per rating minimo

#### 3. Parser NFO - `lib/utils/nfo_strategies/kodi_nfo_strategy.dart`
- Aggiunta parsing elementi `<personalrating>` e `<myrating>` dal NFO
- Valore restituito nel map come `personalRating`

#### 4. Generatore NFO - `lib/utils/nfo_generator.dart`
- Aggiunta scrittura elemento `<personalrating>` per film e serie TV (solo se > 0)

#### 5. Dialog Modifica Video - `lib/screens/edit_video_dialog.dart`, `lib/screens/edit/video_info_column.dart`
- Aggiunto controller `_personalRatingController`
- Campo "Voto Personale (0-10)" tra Tag e Registi
- Salvataggio nel Video aggiornato

#### 6. Video Details Dialog - `lib/screens/video_details_dialog.dart`
- Aggiunta sezione "VOTO PERSONALE" dopo TAG (se > 0)

#### 7. Video Preview Dialog - `lib/screens/video_preview_dialog.dart`
- Aggiunto chip "❤ Voto Personale" rosso nella riga info (se > 0)

#### 8. Filtri - `lib/models/filter_settings.dart`, `lib/screens/filter_dialog.dart`
- Aggiunto `personalRatingMin` in FilterSettings
- Slider "Voto Personale Minimo" nella scheda Generale (0-10, colore rosso)
- Passaggio al repository per filtraggio

#### 9. Repository - `lib/repositories/video_repository.dart`
- Aggiunto parametro `personalRatingMin` in `getFilteredPlaylist`

#### 10. Localizzazione - `lib/l10n/app_it.arb`, `lib/l10n/app_en.arb`
- `labelPersonalRating`: "Voto Personale (0-10)" / "Personal Rating (0-10)"
- `minPersonalRating`: "Voto Personale Minimo:" / "Minimum Personal Rating:"
- `filterByPersonalRating`: "Filtra per voto personale ≥ {rating}" / "Filter by personal rating ≥ {rating}"
- `sectionPersonalRating`: "VOTO PERSONALE" / "PERSONAL RATING"

#### 11. Test aggiornati
- `test/fakes/fake_video_repository.dart`
- `test/statistics_service_test.dart`
- `test/voice_tab_test.dart`

### Verifiche eseguite
- `flutter analyze`: **Solo 1 info (prefer_conditional_assignment)**
- `flutter test`: **195 test passati**
- `flutter build linux --release`: **Build riuscita**

### Stato: COMPLETATO

## Sessione 2026-11-10: Bug Fix - Comando vocale "Locandina"

### Bug 1: Comando "Locandina" restituisce "Locandina non disponibile" anche con video in riproduzione

**Causa**: Il path restituito da VLC (tramite comando `info`) non corrispondeva esattamente al path salvato nel database (es. prefisso `file://`, URL encoding, case sensitivity).

**Soluzione**: Modificato `getVideoByPath` in `lib/database/app_database.dart` per:
1. Rimuovere prefisso `file://`
2. Decodificare URL encoding
3. Tentare match esatto normalizzato
4. Tentare match case-insensitive usando `lower()`
5. Tentare match parziale sul nome file

### File modificati
- `lib/database/app_database.dart`: metodo `getVideoByPath` migliorato

### Verifiche eseguite
- `flutter analyze`: **Solo 1 info (prefer_conditional_assignment)**
- `flutter test`: **195 test passati**
- `flutter build linux --release`: **Build riuscita**

### Stato: COMPLETATO