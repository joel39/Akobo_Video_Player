import 'package:flutter/material.dart';
import '../../models/media_item.dart';
import '../../theme/cyber_theme.dart';

class QueueSheet extends StatefulWidget {
  final List<MediaItem> playlist;
  final MediaItem currentMedia;
  final ValueChanged<MediaItem> onSelectMedia;
  final VoidCallback onAddFiles;
  final ValueChanged<MediaItem> onRemoveMedia;

  const QueueSheet({
    super.key,
    required this.playlist,
    required this.currentMedia,
    required this.onSelectMedia,
    required this.onAddFiles,
    required this.onRemoveMedia,
  });

  @override
  State<QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<QueueSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredList = widget.playlist.where((item) {
      return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    final isDark = CyberTheme.isDark(context);
    final bg = CyberTheme.getCard(context);
    final surface = CyberTheme.getSurface(context);
    final activeColor = CyberTheme.primaryBlue;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: activeColor.withValues(alpha: 0.3), width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.playlist_play, color: activeColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'MEDIA QUEUE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: widget.onAddFiles,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: activeColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: activeColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Add File',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: activeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: TextField(
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                filled: true,
                fillColor: surface,
                hintText: 'Filter media queue...',
                hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.search, color: activeColor, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: activeColor),
                ),
              ),
            ),
          ),

          // Playlist Items
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Text(
                      'No media found in queue',
                      style: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final isSelected = item.id == widget.currentMedia.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeColor.withValues(alpha: 0.12)
                              : surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? activeColor : borderColor,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? activeColor.withValues(alpha: 0.2)
                                  : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isSelected ? Icons.graphic_eq : Icons.play_arrow,
                              color: isSelected ? activeColor : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? activeColor : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: activeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.resolution,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: activeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            widget.onSelectMedia(item);
                            Navigator.of(context).pop();
                          },
                          trailing: widget.playlist.length > 1
                              ? IconButton(
                                  icon: Icon(Icons.close, size: 18, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                  onPressed: () => widget.onRemoveMedia(item),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
}
