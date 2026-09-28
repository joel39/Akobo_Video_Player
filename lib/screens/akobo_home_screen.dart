import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/media_item.dart';
import '../services/akobo_playback_manager.dart';
import '../services/media_scanner_service.dart';
import '../theme/cyber_theme.dart';
import '../widgets/video_thumbnail_widget.dart';
import 'akobo_player_screen.dart';

enum NavTab {
  video,
  music,
  settings,
}

enum SortCriteria {
  dateAdded,
  title,
  duration,
  fileSize,
}

class AkoboHomeScreen extends StatefulWidget {
  final MediaScannerResult? initialMedia;

  const AkoboHomeScreen({super.key, this.initialMedia});

  @override
  State<AkoboHomeScreen> createState() => _AkoboHomeScreenState();
}

class _AkoboHomeScreenState extends State<AkoboHomeScreen> {
  NavTab _selectedTab = NavTab.video;
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isGridView = true;

  // Sorting
  SortCriteria _sortCriteria = SortCriteria.dateAdded;
  bool _sortAscending = false;

  String? _selectedMusicFolder;

  late List<MediaItem> _videos;
  late List<MediaItem> _audios;
  late List<MediaItem> _all;

  @override
  void initState() {
    super.initState();
    AkoboPlaybackManager.instance.addListener(_onPlaybackChanged);
    if (widget.initialMedia != null) {
      _videos = List.from(widget.initialMedia!.videos);
      _audios = List.from(widget.initialMedia!.audios);
      _all = List.from(widget.initialMedia!.all);
    } else {
      _videos = List.from(MediaItem.defaultLibrary);
      _audios = [];
      _all = List.from(MediaItem.defaultLibrary);
      _rescanMedia();
    }
  }

  void _onPlaybackChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AkoboPlaybackManager.instance.removeListener(_onPlaybackChanged);
    super.dispose();
  }

  Future<void> _rescanMedia() async {
    final result = await MediaScannerService.scanDeviceMedia();
    if (mounted) {
      setState(() {
        _videos = result.videos;
        _audios = result.audios;
        _all = result.all;
      });
      _showToast('Loaded ${_all.length} media files');
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: CyberTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openPlayer(MediaItem item, [List<MediaItem>? customPlaylist]) {
    HapticFeedback.lightImpact();
    List<MediaItem> activeList;
    if (customPlaylist != null && customPlaylist.isNotEmpty) {
      activeList = customPlaylist;
    } else if (_selectedTab == NavTab.music) {
      activeList = _sortedAudios;
    } else {
      activeList = _sortedVideos;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, anim, secAnim) => AkoboPlayerScreen(
          initialMedia: item,
          playlist: activeList,
        ),
        transitionsBuilder: (ctx, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  List<MediaItem> get _sortedVideos {
    List<MediaItem> list = List.from(_videos);


    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((item) =>
          item.title.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q) ||
          item.folderName.toLowerCase().contains(q)).toList();
    }

    // Sort
    list.sort((a, b) {
      int cmp = 0;
      switch (_sortCriteria) {
        case SortCriteria.dateAdded:
          final aDate = a.dateAdded ?? DateTime(2026, 9, 1);
          final bDate = b.dateAdded ?? DateTime(2026, 9, 1);
          cmp = aDate.compareTo(bDate);
          break;
        case SortCriteria.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case SortCriteria.duration:
          final aDur = a.duration?.inSeconds ?? 0;
          final bDur = b.duration?.inSeconds ?? 0;
          cmp = aDur.compareTo(bDur);
          break;
        case SortCriteria.fileSize:
          final aSize = a.sizeBytes ?? 0;
          final bSize = b.sizeBytes ?? 0;
          cmp = aSize.compareTo(bSize);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  List<MediaItem> get _sortedAudios {
    List<MediaItem> list = List.from(_audios);


    if (_selectedMusicFolder != null) {
      list = list.where((i) => i.folderName.toLowerCase() == _selectedMusicFolder!.toLowerCase()).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((item) =>
          item.title.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q) ||
          item.folderName.toLowerCase().contains(q)).toList();
    }

    list.sort((a, b) {
      int cmp = 0;
      switch (_sortCriteria) {
        case SortCriteria.dateAdded:
          final aDate = a.dateAdded ?? DateTime(2026, 9, 1);
          final bDate = b.dateAdded ?? DateTime(2026, 9, 1);
          cmp = aDate.compareTo(bDate);
          break;
        case SortCriteria.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case SortCriteria.duration:
          final aDur = a.duration?.inSeconds ?? 0;
          final bDur = b.duration?.inSeconds ?? 0;
          cmp = aDur.compareTo(bDur);
          break;
        case SortCriteria.fileSize:
          final aSize = a.sizeBytes ?? 0;
          final bSize = b.sizeBytes ?? 0;
          cmp = aSize.compareTo(bSize);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  List<String> get _musicFolders {
    final set = <String>{};
    for (final item in _audios) {
      if (item.folderName.isNotEmpty) {
        set.add(item.folderName);
      }
    }
    return set.toList()..sort();
  }

  void _openMusicFolderSheet() {
    final isDark = CyberTheme.isDark(context);
    final folders = _musicFolders;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? CyberTheme.darkCard : CyberTheme.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Music Folders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? CyberTheme.darkTextPrimary : CyberTheme.lightTextPrimary,
                      ),
                    ),
                    if (_selectedMusicFolder != null)
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedMusicFolder = null);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Show All', style: TextStyle(color: CyberTheme.primaryBlue)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (folders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No music folders found',
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        final isSelected = folder.toLowerCase() == _selectedMusicFolder?.toLowerCase();
                        final count = _audios.where((i) => i.folderName.toLowerCase() == folder.toLowerCase()).length;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? CyberTheme.primaryBlue.withValues(alpha: 0.15)
                                  : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEFF6FF)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.folder_rounded,
                              color: isSelected ? CyberTheme.primaryBlue : (isDark ? Colors.white70 : const Color(0xFF2563EB)),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            folder,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? CyberTheme.primaryBlue : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                          subtitle: Text(
                            '$count song${count == 1 ? '' : 's'}',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                          ),
                          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: CyberTheme.primaryBlue) : null,
                          onTap: () {
                            setState(() => _selectedMusicFolder = folder);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }


  void _openSortSheet() {
    final isDark = CyberTheme.isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? CyberTheme.darkCard : CyberTheme.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sort by',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? CyberTheme.darkTextPrimary : CyberTheme.lightTextPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() => _sortAscending = !_sortAscending);
                            setState(() {});
                          },
                          icon: Icon(
                            _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            size: 16,
                            color: CyberTheme.primaryBlue,
                          ),
                          label: Text(
                            _sortAscending ? 'Ascending' : 'Descending',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: CyberTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _sortOptionItem(
                      title: 'Date added',
                      criteria: SortCriteria.dateAdded,
                      icon: Icons.calendar_today_rounded,
                      setModalState: setModalState,
                    ),
                    _sortOptionItem(
                      title: 'Name / Title',
                      criteria: SortCriteria.title,
                      icon: Icons.sort_by_alpha_rounded,
                      setModalState: setModalState,
                    ),
                    _sortOptionItem(
                      title: 'Duration',
                      criteria: SortCriteria.duration,
                      icon: Icons.access_time_rounded,
                      setModalState: setModalState,
                    ),
                    _sortOptionItem(
                      title: 'File size',
                      criteria: SortCriteria.fileSize,
                      icon: Icons.data_usage_rounded,
                      setModalState: setModalState,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sortOptionItem({
    required String title,
    required SortCriteria criteria,
    required IconData icon,
    required StateSetter setModalState,
  }) {
    final isSelected = _sortCriteria == criteria;
    final isDark = CyberTheme.isDark(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isSelected ? CyberTheme.primaryBlue : (isDark ? CyberTheme.darkTextSecondary : CyberTheme.lightTextSecondary)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? CyberTheme.primaryBlue : (isDark ? CyberTheme.darkTextPrimary : CyberTheme.lightTextPrimary),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: CyberTheme.primaryBlue)
          : null,
      onTap: () {
        setModalState(() => _sortCriteria = criteria);
        setState(() {});
        Navigator.pop(context);
      },
    );
  }

  void _showItemOptionsMenu(MediaItem item) {
    final isDark = CyberTheme.isDark(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? CyberTheme.darkCard : CyberTheme.lightCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? CyberTheme.darkTextPrimary : CyberTheme.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded, color: CyberTheme.primaryBlue),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(ctx);
                _openPlayer(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: CyberTheme.primaryBlue),
              title: const Text('Properties'),
              subtitle: Text(item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '9/13/26';
    return '${dt.month}/${dt.day}/${dt.year.toString().substring(dt.year.toString().length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CyberTheme.isDark(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? CyberTheme.darkBg : CyberTheme.lightBg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // 1. Header matching Image 4 ("Arc Player")
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 12, 10),
                    child: Row(
                      children: [
                        // Akobo Video Player Logo & Title
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: CyberTheme.primaryBlue.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: CyberTheme.primaryBlue.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    color: CyberTheme.primaryBlue,
                                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                children: const [
                                  TextSpan(text: 'Akobo '),
                                  TextSpan(
                                    text: 'Player',
                                    style: TextStyle(
                                      color: CyberTheme.primaryBlue,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Cast Icon
                        IconButton(
                          icon: Icon(Icons.cast_rounded, color: isDark ? Colors.white70 : Colors.black87),
                          onPressed: () => _showToast('Searching for Cast receivers...'),
                        ),

                        // Search Icon
                        IconButton(
                          icon: Icon(
                            _isSearching ? Icons.close : Icons.search_rounded,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          onPressed: () {
                            setState(() {
                              _isSearching = !_isSearching;
                              if (!_isSearching) _searchQuery = '';
                            });
                          },
                        ),

                        // 3-dots Menu
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : Colors.black87),
                          onSelected: (val) {
                            if (val == 'rescan') _rescanMedia();
                            if (val == 'open_file') _openLocalFile();
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'rescan',
                              child: Row(
                                children: [
                                  Icon(Icons.refresh_rounded, size: 18, color: CyberTheme.primaryBlue),
                                  SizedBox(width: 10),
                                  Text('Rescan Device Media'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'open_file',
                              child: Row(
                                children: [
                                  Icon(Icons.file_open_outlined, size: 18, color: CyberTheme.primaryBlue),
                                  SizedBox(width: 10),
                                  Text('Open File...'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Search Bar (if searching)
                if (_isSearching)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      child: TextField(
                        autofocus: true,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search videos and audios...',
                          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                          filled: true,
                          fillColor: isDark ? CyberTheme.darkCard : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? CyberTheme.darkBorder : CyberTheme.lightBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? CyberTheme.darkBorder : CyberTheme.lightBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: CyberTheme.primaryBlue),
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                  ),


                // 3. Filter Row matching Image 4 ("All videos ▼", Grid/List toggle, Sort button ⇅)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 14, 8),
                    child: Row(
                      children: [
                        // "All videos ▼" or "All songs ▼" Filter dropdown
                        // "All videos" or "All songs" Title
                        Text(
                          _selectedTab == NavTab.music ? 'All songs' : 'All videos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),

                        // Folder Button next to "All songs" for music
                        if (_selectedTab == NavTab.music) ...[
                          const SizedBox(width: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: _openMusicFolderSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _selectedMusicFolder != null
                                    ? CyberTheme.primaryBlue.withValues(alpha: 0.15)
                                    : (isDark ? Colors.white.withValues(alpha: 0.06) : CyberTheme.blueSoftTint),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedMusicFolder != null
                                      ? CyberTheme.primaryBlue
                                      : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder_rounded,
                                    size: 16,
                                    color: CyberTheme.primaryBlue,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _selectedMusicFolder ?? 'Folders',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedMusicFolder != null
                                          ? CyberTheme.primaryBlue
                                          : (isDark ? Colors.white70 : const Color(0xFF2563EB)),
                                    ),
                                  ),
                                  if (_selectedMusicFolder != null) ...[
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => setState(() => _selectedMusicFolder = null),
                                      child: const Icon(Icons.close, size: 14, color: CyberTheme.primaryBlue),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),

                        // Grid / List Toggle Icon
                        IconButton(
                          tooltip: _isGridView ? 'Switch to List view' : 'Switch to Grid view',
                          icon: Icon(
                            _isGridView ? Icons.grid_view_rounded : Icons.view_agenda_outlined,
                            size: 20,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          onPressed: () => setState(() => _isGridView = !_isGridView),
                        ),

                        // Sort Button (⇅ vertical arrows as shown in Image 4)
                        IconButton(
                          tooltip: 'Sort options',
                          icon: const Icon(
                            Icons.swap_vert_rounded,
                            size: 24,
                            color: CyberTheme.primaryBlue,
                          ),
                          onPressed: _openSortSheet,
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Main Body Content (Videos, Music, or Settings)
                ..._buildMainContent(bottomInset),
              ],
            ),
          ),

          // Floating mini-player pill (matching Image 4 bottom-right blue pill: "▶ (መልካም ነ...)")
          if (AkoboPlaybackManager.instance.hasActiveMedia)
            Positioned(
              right: 18,
              bottom: (bottomInset > 0 ? bottomInset : 8) + 68,
              child: _buildFloatingMiniPlayerPill(),
            ),

          // Bottom Footer Navigation matching Image 4 (Video, Music, Settings)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNav(bottomInset),
          ),
        ],
      ),
    );
  }


  List<Widget> _buildMainContent(double bottomInset) {
    final effectiveBottomPad = 80.0 + (bottomInset > 0 ? bottomInset : 12.0);

    if (_selectedTab == NavTab.settings) {
      return [_buildSettingsContent(effectiveBottomPad)];
    }

    if (_selectedTab == NavTab.music) {
      final audios = _sortedAudios;
      if (audios.isEmpty) {
        return [_buildEmptyState('No music found', 'Tap rescan to search phone audio tracks')];
      }
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 6, 16, effectiveBottomPad),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildAudioCard(audios[index]),
              childCount: audios.length,
            ),
          ),
        ),
      ];
    }

    // Video Tab
    final videos = _sortedVideos;
    if (videos.isEmpty) {
      return [_buildEmptyState('No videos found', 'Tap rescan to discover phone videos')];
    }

    if (_isGridView) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(14, 4, 14, effectiveBottomPad),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.88, // Clean 16:9 thumbnail + title + subtitle
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildVideoGridCard(videos[index]),
              childCount: videos.length,
            ),
          ),
        ),
      ];
    } else {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(14, 4, 14, effectiveBottomPad),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildVideoListCard(videos[index]),
              childCount: videos.length,
            ),
          ),
        ),
      ];
    }
  }

  /// 16:9 Horizontal Thumbnail Video Card matching Image 4
  Widget _buildVideoGridCard(MediaItem item) {
    final isDark = CyberTheme.isDark(context);
    final dateStr = _formatDate(item.dateAdded);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openPlayer(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 Thumbnail with Rounded Corners & Date Overlay
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? CyberTheme.darkCard : const Color(0xFFE2E8F0),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoThumbnailWidget(item: item),

                    // Date Overlay at Bottom-Left (matching Image 4 e.g. "9/13/26")
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Title & 3-dots Menu Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? CyberTheme.darkTextPrimary : CyberTheme.lightTextPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showItemOptionsMenu(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, top: 2),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 16,
                      color: isDark ? CyberTheme.darkTextSecondary : CyberTheme.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),

            // Duration (e.g. "00:28/01:21")
            Text(
              item.duration != null
                  ? _formatDuration(item.duration!)
                  : (item.subtitle.isNotEmpty ? item.subtitle : '00:28/01:21'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: isDark ? CyberTheme.darkTextSecondary : CyberTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// List layout with 16:9 thumbnail
  Widget _buildVideoListCard(MediaItem item) {
    final isDark = CyberTheme.isDark(context);
    final dateStr = _formatDate(item.dateAdded);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: CyberTheme.adaptiveCard(context, borderRadius: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openPlayer(item),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoThumbnailWidget(item: item),
                          Positioned(
                            left: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                dateStr,
                                style: const TextStyle(fontSize: 9, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? CyberTheme.darkTextSecondary : CyberTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                  onPressed: () => _showItemOptionsMenu(item),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioCard(MediaItem item) {
    final isDark = CyberTheme.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: CyberTheme.adaptiveCard(context, borderRadius: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openPlayer(item),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: CyberTheme.primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.music_note_rounded, color: CyberTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? CyberTheme.darkTextSecondary : CyberTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent(double bottomPad) {
    final isDark = CyberTheme.isDark(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SETTINGS & PREFERENCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? CyberTheme.darkTextSecondary : CyberTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _settingsTile(
              icon: Icons.brightness_auto_rounded,
              title: 'Theme & Appearance',
              subtitle: 'Automatically adapts to system Light and Dark mode',
              trailing: Text(
                isDark ? 'Dark Mode' : 'Light Mode',
                style: const TextStyle(fontWeight: FontWeight.bold, color: CyberTheme.primaryBlue),
              ),
            ),
            _settingsTile(
              icon: Icons.headphones_rounded,
              title: 'Background Play & Lock Screen',
              subtitle: 'Keep media playing on lock screen and when minimized',
              trailing: Switch(
                value: AkoboPlaybackManager.instance.isBackgroundPlayEnabled,
                activeThumbColor: CyberTheme.primaryBlue,
                onChanged: (val) {
                  AkoboPlaybackManager.instance.setBackgroundPlay(val);
                  setState(() {});
                },
              ),
            ),
            _settingsTile(
              icon: Icons.screen_lock_portrait_rounded,
              title: 'Lock Screen Media Player',
              subtitle: 'Active system media session notification',
              trailing: const Icon(Icons.check_circle_rounded, color: CyberTheme.primaryBlue, size: 20),
            ),
            _settingsTile(
              icon: Icons.storage_rounded,
              title: 'Rescan Storage',
              subtitle: 'Refresh local video and audio libraries',
              onTap: _rescanMedia,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = CyberTheme.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: CyberTheme.adaptiveCard(context, borderRadius: 14),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CyberTheme.primaryBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: CyberTheme.primaryBlue, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? CyberTheme.darkTextSecondary : CyberTheme.lightTextSecondary,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  /// Floating Mini-Player Pill matching Image 4 (Blue pill: "▶ (መልካም ነ...)")
  /// Floating Mini-Player Pill matching Image 4 with Next & Prev icons
  Widget _buildFloatingMiniPlayerPill() {
    final manager = AkoboPlaybackManager.instance;
    final title = manager.currentMedia?.title ?? 'Playing';
    final isPlaying = manager.isPlaying;

    return Material(
      color: Colors.transparent,
      elevation: 6,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CyberTheme.primaryBlue,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: CyberTheme.primaryBlue.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Previous button
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.lightImpact();
                manager.previous();
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.skip_previous_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 2),

            // Play / Pause button
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.lightImpact();
                manager.togglePlayPause();
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 2),

            // Next button
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.lightImpact();
                manager.next();
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.skip_next_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Media Title (tap to open full player)
            InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                if (manager.currentMedia != null) {
                  _openPlayer(manager.currentMedia!, manager.playlist);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Footer Navigation matching Image 4: Video, Music, Settings
  Widget _buildBottomNav(double bottomInset) {
    final isDark = CyberTheme.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? CyberTheme.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? CyberTheme.darkBorder : CyberTheme.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                tab: NavTab.video,
                label: 'Video',
                icon: Icons.play_arrow_rounded,
              ),
              _navItem(
                tab: NavTab.music,
                label: 'Music',
                icon: Icons.music_note_rounded,
              ),
              _navItem(
                tab: NavTab.settings,
                label: 'Settings',
                icon: Icons.settings_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required NavTab tab,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == tab;
    final isDark = CyberTheme.isDark(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTab = tab);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? CyberTheme.primaryBlue.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? CyberTheme.primaryBlue : (isDark ? CyberTheme.darkTextSecondary : CyberTheme.lightTextSecondary),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? CyberTheme.primaryBlue : (isDark ? CyberTheme.darkTextSecondary : CyberTheme.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    final isDark = CyberTheme.isDark(context);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 48, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? CyberTheme.darkTextSecondary : CyberTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _openLocalFile() async {
    try {
      final res = await FilePickerPlatform.instance.pickFiles();
      if (res.isNotEmpty && res.first.path != null) {
        final path = res.first.path!;
        final name = res.first.name;
        final item = MediaItem(
          id: 'manual-${path.hashCode}',
          title: name,
          subtitle: 'Local File',
          url: path,
          isLocal: true,
        );
        _openPlayer(item);
      }
    } catch (_) {}
  }
}
