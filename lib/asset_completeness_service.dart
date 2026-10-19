import 'content_ideas.dart';
import 'prompt_vault.dart';
import 'quality_check_center.dart';
import 'video_library.dart';
import 'video_library_store.dart';

class AssetCompleteness {
  final String contentId;
  final String title;
  final bool hasScript;
  final bool hasVideoPrompt;
  final bool hasVideoAsset;
  final bool hasQualityReport;
  final bool isReadyToPost;

  AssetCompleteness({
    required this.contentId,
    required this.title,
    required this.hasScript,
    required this.hasVideoPrompt,
    required this.hasVideoAsset,
    required this.hasQualityReport,
  })  : isReadyToPost =
            (hasScript || hasVideoPrompt) && hasVideoAsset && hasQualityReport;

  AssetCompleteness copyWith({
    bool? hasScript,
    bool? hasVideoPrompt,
    bool? hasVideoAsset,
    bool? hasQualityReport,
  }) {
    final updated = AssetCompleteness(
      contentId: contentId,
      title: title,
      hasScript: hasScript ?? this.hasScript,
      hasVideoPrompt: hasVideoPrompt ?? this.hasVideoPrompt,
      hasVideoAsset: hasVideoAsset ?? this.hasVideoAsset,
      hasQualityReport: hasQualityReport ?? this.hasQualityReport,
    );
    return updated;
  }
}

class AssetCompletenessService {
  /// Returns completeness status for a single content item.
  static Future<AssetCompleteness> checkContentId(String contentId) async {
    final prompts = await PromptVault.getByContentId(contentId);
    final hasScript =
        prompts.any((p) => p.type == PromptType.script && p.status != PromptStatus.archived);
    final hasVideoPrompt =
        prompts.any((p) => p.type == PromptType.video && p.status != PromptStatus.archived);

    final videos = await VideoLibrary.getByContentId(contentId);
    final hasVideoAsset =
        videos.any((v) => v.status != VideoStatus.archived && v.fileName.isNotEmpty);

    final reports = await QualityCheckCenter.getByContentId(contentId);
    final hasQualityReport = reports.isNotEmpty;

    return AssetCompleteness(
      contentId: contentId,
      title: contentId,
      hasScript: hasScript,
      hasVideoPrompt: hasVideoPrompt,
      hasVideoAsset: hasVideoAsset,
      hasQualityReport: hasQualityReport,
    );
  }

  /// Returns completeness status for all known built-in and quick ideas.
  static Future<List<AssetCompleteness>> checkAll() async {
    final allPrompts = await PromptVault.getAll();
    final allVideos = await VideoLibrary.getAll();
    final allReports = await QualityCheckCenter.getAll();

    final promptByContent = <String, List<SavedPrompt>>{};
    for (final p in allPrompts) {
      if (p.status == PromptStatus.archived) continue;
      promptByContent.putIfAbsent(p.contentId, () => []).add(p);
    }

    final videosByContent = <String, List<VideoAsset>>{};
    for (final v in allVideos) {
      if (v.status == VideoStatus.archived) continue;
      videosByContent.putIfAbsent(v.contentId, () => []).add(v);
    }

    final reportsByContent = <String, List<QualityReport2>>{};
    for (final r in allReports) {
      reportsByContent.putIfAbsent(r.contentId, () => []).add(r);
    }

    final results = <AssetCompleteness>[];

    for (final idea in kDefaultHooks) {
      if (!idea.forApp) continue;
      results.add(_checkFromPreloaded(
        contentId: idea.id,
        title: idea.cover,
        prompts: promptByContent[idea.id],
        videos: videosByContent[idea.id],
        reports: reportsByContent[idea.id],
      ));
    }

    for (final idea in kDay14Posts) {
      results.add(_checkFromPreloaded(
        contentId: idea.id,
        title: idea.title,
        prompts: promptByContent[idea.id],
        videos: videosByContent[idea.id],
        reports: reportsByContent[idea.id],
      ));
    }

    for (final contentId in promptByContent.keys) {
      if (results.any((r) => r.contentId == contentId)) continue;
      final title = promptByContent[contentId]!.first.title;
      results.add(_checkFromPreloaded(
        contentId: contentId,
        title: title,
        prompts: promptByContent[contentId],
        videos: videosByContent[contentId],
        reports: reportsByContent[contentId],
      ));
    }

    return results;
  }

  static AssetCompleteness _checkFromPreloaded({
    required String contentId,
    required String title,
    List<SavedPrompt>? prompts,
    List<VideoAsset>? videos,
    List<QualityReport2>? reports,
  }) {
    prompts ??= [];
    videos ??= [];
    reports ??= [];

    final hasScript = prompts
        .any((p) => p.type == PromptType.script && p.status != PromptStatus.archived);
    final hasVideoPrompt = prompts
        .any((p) => p.type == PromptType.video && p.status != PromptStatus.archived);
    final hasVideoAsset =
        videos.any((v) => v.status != VideoStatus.archived && v.fileName.isNotEmpty);
    final hasQualityReport = reports.isNotEmpty;

    return AssetCompleteness(
      contentId: contentId,
      title: title,
      hasScript: hasScript,
      hasVideoPrompt: hasVideoPrompt,
      hasVideoAsset: hasVideoAsset,
      hasQualityReport: hasQualityReport,
    );
  }

  /// Returns only the items that are not yet ready to post.
  static Future<List<AssetCompleteness>> getMissing() async {
    final all = await checkAll();
    return all.where((a) => !a.isReadyToPost).toList();
  }
}
