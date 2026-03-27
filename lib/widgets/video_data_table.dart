import 'package:flutter/material.dart';
import '../models/video.dart';
import 'package:my_playlist/l10n/app_localizations.dart';

class VideoDataTable extends StatefulWidget {
  final List<Video> videos;
  final Function(Video) onEdit;
  final Function(Video) onDelete;
  final Function(int, bool) onSort;
  final int? sortColumnIndex;
  final bool isSortedAscending;

  const VideoDataTable({
    super.key,
    required this.videos,
    required this.onEdit,
    required this.onDelete,
    required this.onSort,
    this.sortColumnIndex,
    this.isSortedAscending = true,
  });

  @override
  State<VideoDataTable> createState() => _VideoDataTableState();
}

class _VideoDataTableState extends State<VideoDataTable> {
  late final ScrollController _horizontalController;
  late final ScrollController _verticalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Total width calculation: 250+80+100+80+150+200+150+120 = 1130
    const double totalTableWidth = 1130;

    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalController,
        child: SizedBox(
          width: totalTableWidth,
          child: Column(
            children: [
              _buildTableHeader(context),
              Expanded(
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: ListView.builder(
                    controller: _verticalController,
                    itemCount: widget.videos.length,
                    itemExtent:
                        50, // Fixed height for performance if rows are uniform
                    itemBuilder: (context, index) =>
                        _buildTableRow(context, widget.videos[index], index),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white10
          : Colors.black12,
      child: Row(
        children: [
          _buildHeaderColumn(context, l10n.colTitle, 250, 2),
          _buildHeaderColumn(context, l10n.colYear, 80, 5),
          _buildHeaderColumn(context, l10n.colDuration, 100, 4),
          _buildHeaderColumn(context, l10n.colRating, 80, 11),
          _buildHeaderColumn(context, l10n.colSaga, 150, 14),
          _buildHeaderColumn(context, l10n.colGenres, 200, 3),
          _buildHeaderColumn(context, l10n.colDirectors, 150, 6),
          _buildHeaderColumn(context, l10n.colActions, 120, -1),
        ],
      ),
    );
  }

  Widget _buildHeaderColumn(
    BuildContext context,
    String label,
    double width,
    int index,
  ) {
    final isSorted = widget.sortColumnIndex == index;
    return InkWell(
      onTap: index != -1
          ? () => widget.onSort(
              index,
              isSorted ? !widget.isSortedAscending : true,
            )
          : null,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isSorted)
              Icon(
                widget.isSortedAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, Video video, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: index.isEven
            ? (isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.02))
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTableCell(
            Text(
              video.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            250,
          ),
          _buildTableCell(Text(video.year), 80),
          _buildTableCell(Text(video.duration), 100),
          _buildTableCell(
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(video.rating.toStringAsFixed(1)),
              ],
            ),
            80,
          ),
          _buildTableCell(
            Text(video.saga, maxLines: 1, overflow: TextOverflow.ellipsis),
            150,
          ),
          _buildTableCell(
            Text(video.genres, maxLines: 1, overflow: TextOverflow.ellipsis),
            200,
          ),
          _buildTableCell(
            Text(video.directors, maxLines: 1, overflow: TextOverflow.ellipsis),
            150,
          ),
          _buildTableCell(
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => widget.onEdit(video),
                  tooltip: AppLocalizations.of(context)!.editTooltip,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    size: 20,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => widget.onDelete(video),
                  tooltip: AppLocalizations.of(context)!.deleteTooltip,
                ),
              ],
            ),
            120,
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(Widget child, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );
  }
}
