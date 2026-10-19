import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'file_storage.dart';
import 'quality_check_center.dart';
import 'theme.dart';
import 'video_library.dart';
import 'video_library_store.dart';

class VideoLibraryScreen extends StatefulWidget {
  const VideoLibraryScreen({super.key});

  @override
  State<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends State<VideoLibraryScreen> {
  List<VideoAsset> _videos = const [];
  bool _loading = true;
  VideoStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await VideoLibrary.getAll();
    if (!mounted) return;
    setState(() {
      _videos = all;
      _loading = false;
    });
  }

  List<VideoAsset> get _visible {
    if (_statusFilter != null) {
      return _videos.where((v) => v.status == _statusFilter!).toList();
    }
    return _videos;
  }

  Future<void> _uploadVideo() async {
    final scaffold = ScaffoldMessenger.of(context);
    final contentIdController = TextEditingController();
    final titleController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contentIdController,
              decoration: const InputDecoration(
                labelText: 'Content ID',
                hintText: 'e.g. h01',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final contentId = contentIdController.text.trim();
    final title = titleController.text.trim();
    if (contentId.isEmpty) {
      scaffold.showSnackBar(const SnackBar(content: Text('Content ID is required')));
      return;
    }
    try {
      final uploaded = await VideoLibrary.pickAndUpload(
        contentId: contentId,
        title: title.isNotEmpty ? title : contentId,
      );
      if (uploaded != null && mounted) {
        setState(() => _videos.insert(0, uploaded));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _changeStatus(VideoAsset asset, VideoStatus status) async {
    await VideoLibrary.updateStatus(asset.id, status);
    if (!mounted) return;
    setState(() {
      final idx = _videos.indexWhere((v) => v.id == asset.id);
      if (idx != -1) _videos[idx] = _videos[idx].copyWith(status: status);
    });
  }

  Future<void> _runQualityCheck(VideoAsset asset) async {
    final report = await QualityCheckCenter.checkVideo(asset: asset);
    await QualityCheckCenter.save(report);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quality check complete: ${report.overallStatus}')),
    );
  }

  void _previewVideo(VideoAsset asset) {
    showDialog(
      context: context,
      builder: (context) => VideoPreviewDialog(asset: asset),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Library'),
        actions: [
          if (_statusFilter != null)
            IconButton(
              tooltip: 'Clear filter',
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () => setState(() => _statusFilter = null),
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? const Center(child: Text('No videos yet. Tap + to upload one.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    itemCount: _visible.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final asset = _visible[i];
                      return _VideoTile(
                        asset: asset,
                        onTap: () => _previewVideo(asset),
                        onStatusChanged: (status) => _changeStatus(asset, status),
                        onQualityCheck: () => _runQualityCheck(asset),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadVideo,
        tooltip: 'Upload Video',
        child: const Icon(Icons.upload),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final VideoAsset asset;
  final VoidCallback onTap;
  final void Function(VideoStatus) onStatusChanged;
  final VoidCallback onQualityCheck;

  const _VideoTile({
    required this.asset,
    required this.onTap,
    required this.onStatusChanged,
    required this.onQualityCheck,
  });

  @override
  Widget build(BuildContext context) {
    final canApprove = asset.status == VideoStatus.qualityChecked ||
        asset.status == VideoStatus.approved;
    final canPost = asset.status == VideoStatus.approved;
    final canCheck = asset.status == VideoStatus.uploaded ||
        asset.status == VideoStatus.qualityChecked;

    return ListTile(
      leading: const Icon(Icons.video_library, color: AppColors.primary),
      title: Text(asset.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${asset.contentId} • ${asset.status.label} • v${asset.version}',
        style: AppText.hint.copyWith(fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        itemBuilder: (context) => [
          PopupMenuItem(value: 'preview', child: const Text('Preview')),
          if (canCheck)
            PopupMenuItem(value: 'quality', child: const Text('Run Quality Check')),
          if (canApprove)
            PopupMenuItem(value: 'approve', child: const Text('Approve')),
          if (canPost)
            PopupMenuItem(value: 'post', child: const Text('Mark Posted')),
        ],
        onSelected: (value) {
          switch (value) {
            case 'preview':
              onTap();
              break;
            case 'quality':
              onQualityCheck();
              break;
            case 'approve':
              onStatusChanged(VideoStatus.approved);
              break;
            case 'post':
              onStatusChanged(VideoStatus.posted);
              break;
          }
        },
      ),
    );
  }
}

class VideoPreviewDialog extends StatefulWidget {
  final VideoAsset asset;

  const VideoPreviewDialog({super.key, required this.asset});

  @override
  State<VideoPreviewDialog> createState() => _VideoPreviewDialogState();
}

class _VideoPreviewDialogState extends State<VideoPreviewDialog> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final file = await FileStorageManager.getVideoFile(widget.asset.fileName);
      if (file == null) {
        setState(() {
          _loading = false;
          _error = 'Video file not found in storage';
        });
        return;
      }
      _controller = VideoPlayerController.file(file)..initialize().then((_) {
        if (mounted) setState(() => _loading = false);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load video: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      title: Text(widget.asset.title),
      content: SizedBox(
        width: 320,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _controller != null && _controller!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                    : const Center(child: Text('No video preview available')),
      ),
      actions: [
        if (_controller != null && _controller!.value.isInitialized && !_loading && _error == null)
          IconButton(
            icon: Icon(_controller!.value.isPlaying
                ? Icons.pause
                : Icons.play_arrow),
            onPressed: () {
              if (_controller!.value.isPlaying) {
                _controller!.pause();
              } else {
                _controller!.play();
              }
            },
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
