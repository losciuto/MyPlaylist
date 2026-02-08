import 'dart:io';
import 'package:flutter/material.dart';

class PersonAvatar extends StatelessWidget {
  final String name;
  final String thumbUrl;
  final double size;

  const PersonAvatar({
    super.key,
    required this.name,
    required this.thumbUrl,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: () => _showEnlargedImage(context),
      child: Container(
        width: size + 20,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Hero(
                tag: 'avatar_$name',
                child: ClipOval(
                  child: _buildAvatarImage(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showEnlargedImage(BuildContext context) {
    if (thumbUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Hero(
                tag: 'avatar_$name',
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildEnlargedImage(),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnlargedImage() {
    if (thumbUrl.startsWith('http')) {
      return Image.network(
        thumbUrl.replaceFirst('/w185/', '/w500/'), // Try to get higher resolution if from TMDB
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
      );
    } else {
      final file = File(thumbUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
        );
      }
    }
    return _buildErrorImage();
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[900],
      width: 300,
      height: 450,
      child: const Icon(Icons.person, size: 100, color: Colors.grey),
    );
  }

  Widget _buildAvatarImage() {
    if (thumbUrl.isEmpty) {
      return Icon(Icons.person, size: size * 0.6, color: Colors.grey);
    }

    if (thumbUrl.startsWith('http')) {
      return Image.network(
        thumbUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.person, size: size * 0.6, color: Colors.grey),
      );
    } else {
      // Local file
      final file = File(thumbUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.person, size: size * 0.6, color: Colors.grey),
        );
      }
    }

    return Icon(Icons.person, size: size * 0.6, color: Colors.grey);
  }
}
