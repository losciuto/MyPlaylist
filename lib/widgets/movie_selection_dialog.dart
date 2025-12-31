import 'package:flutter/material.dart';

class MovieSelectionDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> results;
  final bool isBulkMode;

  const MovieSelectionDialog({
    super.key,
    required this.title,
    required this.results,
    this.isBulkMode = false,
  });

  @override
  State<MovieSelectionDialog> createState() => _MovieSelectionDialogState();
}

class _MovieSelectionDialogState extends State<MovieSelectionDialog> {
  static const int itemsPerPage = 6;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final totalPages = (widget.results.length / itemsPerPage).ceil();
    final startIndex = _currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage < widget.results.length)
        ? startIndex + itemsPerPage
        : widget.results.length;
    final pagedResults = widget.results.sublist(startIndex, endIndex);

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        height: 650,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: pagedResults.length,
                separatorBuilder: (ctx, idx) => const Divider(color: Colors.white12),
                itemBuilder: (ctx, idx) {
                  final movie = pagedResults[idx];
                  final posterPath = movie['poster_path'];
                  final releaseDate = movie['release_date']?.toString().split('-').first ?? 'N/A';
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    leading: Container(
                      width: 50,
                      height: 75,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: posterPath != null
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w92$posterPath',
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Icon(Icons.movie, color: Colors.grey),
                            )
                          : const Icon(Icons.movie, color: Colors.grey),
                    ),
                    title: Text(
                      movie['title'] ?? 'Senza Titolo',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Anno: $releaseDate', style: const TextStyle(color: Colors.white70)),
                        if (movie['overview'] != null && movie['overview'].toString().isNotEmpty)
                          Text(
                            movie['overview'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, movie),
                  );
                },
              ),
            ),
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 16, color: Colors.white),
                      onPressed: _currentPage > 0
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    Text(
                      'Pagina ${_currentPage + 1} di $totalPages',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                      onPressed: _currentPage < totalPages - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.isBulkMode) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context, {'action': 'cancel'}),
                    child: const Text('INTERROMPI TUTTO', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(
                    widget.isBulkMode ? 'Salta questo video' : 'Annulla',
                    style: TextStyle(color: widget.isBulkMode ? Colors.orange : Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
