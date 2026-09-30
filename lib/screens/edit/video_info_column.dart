import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

import 'edit_video_text_field.dart';

/// Dati mostrati a sinistra nel dialog di modifica: titolo, anno, durata,
/// generi, cast, locandina, saga e data.
///
/// [onDateChanged] riceve la nuova data e deve aggiornare anche i campi testo:
/// i controller restano di proprietà del dialog.
Widget buildVideoInfoColumn({
  required BuildContext context,
  required TextEditingController titleController,
  required TextEditingController yearController,
  required TextEditingController durationController,
  required TextEditingController genresController,
  required TextEditingController directorsController,
  required TextEditingController actorsController,
  required TextEditingController posterPathController,
  required TextEditingController sagaController,
  required TextEditingController sagaIndexController,
  required TextEditingController dateAddedController,
  required TextEditingController timeController,
  required DateTime? dateAdded,
  required ValueChanged<DateTime> onDateChanged,
}) {
  final l10n = AppLocalizations.of(context)!;

  return SingleChildScrollView(
    child: Column(
      children: [
        editVideoTextField(context, titleController, l10n.labelTitle, true),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: editVideoTextField(
                context,
                yearController,
                l10n.labelYear,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: editVideoTextField(
                context,
                durationController,
                l10n.labelDuration,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        editVideoTextField(context, genresController, l10n.labelGenres),
        const SizedBox(height: 10),
        editVideoTextField(context, directorsController, l10n.labelDirectors),
        const SizedBox(height: 10),
        editVideoTextField(context, actorsController, l10n.labelActors),
        const SizedBox(height: 10),
        editVideoTextField(context, posterPathController, l10n.labelPoster),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: editVideoTextField(
                context,
                sagaController,
                l10n.labelSaga,
                false,
                1,
                l10n.sagaTooltip,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: editVideoTextField(
                context,
                sagaIndexController,
                l10n.labelSagaIndex,
                false,
                1,
                l10n.sagaIndexTooltip,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: dateAdded ?? DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate == null) return;
                  final current = dateAdded ?? DateTime.now();
                  onDateChanged(
                    DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      current.hour,
                      current.minute,
                    ),
                  );
                },
                child: AbsorbPointer(
                  child: editVideoTextField(
                    context,
                    dateAddedController,
                    l10n.labelDateAdded,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(
                      dateAdded ?? DateTime.now(),
                    ),
                  );
                  if (pickedTime == null) return;
                  final current = dateAdded ?? DateTime.now();
                  onDateChanged(
                    DateTime(
                      current.year,
                      current.month,
                      current.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    ),
                  );
                },
                child: AbsorbPointer(
                  child: editVideoTextField(
                    context,
                    timeController,
                    l10n.labelTime,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Colonna destra: voto e trama. [onRatingChanged] segnala lo slider.
Widget buildVideoRatingColumn({
  required BuildContext context,
  required double rating,
  required TextEditingController plotController,
  required ValueChanged<double> onRatingChanged,
}) {
  final l10n = AppLocalizations.of(context)!;

  return SingleChildScrollView(
    child: Column(
      children: [
        Text(l10n.colRating, style: const TextStyle(color: Colors.white70)),
        Slider(
          value: rating,
          max: 10,
          divisions: 20,
          label: rating.toString(),
          activeColor: const Color(0xFF4CAF50),
          onChanged: onRatingChanged,
        ),
        Text(
          l10n.ratingLabel(rating.toStringAsFixed(1)),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 20),
        editVideoTextField(context, plotController, l10n.labelPlot, false, 15),
      ],
    ),
  );
}

/// Aggiorna i controller di data e ora dopo una modifica.
String formatDateAdded(DateTime value) =>
    DateFormat('yyyy-MM-dd').format(value);

String formatTimeAdded(DateTime value) => DateFormat('HH:mm').format(value);
