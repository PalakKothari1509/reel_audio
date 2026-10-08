// Bridge between existing Project-based flow and the new ContentPackageV2 pipeline.
//
// The app's main.dart uses ProjectStore to persist stories. This bridge
// converts Project data to ContentPackageV2 so packages can be stored via
// the new PackageStore alongside the existing ProjectStore.
//
// This keeps the existing UI working while enabling the new pipeline
// to coexist.

import 'package:flutter/foundation.dart';

import 'content_axes.dart';
import 'content_package_v2.dart';
import 'content_quality_gate.dart';
import 'package_store.dart';
import 'projects.dart';

/// Converts a [Project] into a [ContentPackageV2] for storage in the new pipeline.
///
/// This is a one-way bridge: it extracts the data that exists in a Project
/// and maps it to the V2 fields. Some V2 fields (like classification) are
/// inferred from the Project's content.
class ProjectToPackageBridge {
  /// Converts a Project to a ContentPackageV2.
  ///
  /// The gate report is computed from the project's content, so the
  /// package carries the readiness verdict alongside it.
  static Future<ContentPackageV2> convertProject(Project project) async {
    final lines = project.script;

    // Build scenes from script lines
    final scenes = List.generate(lines.length, (i) {
      final parts = lines[i].split('|');
      final text = parts.length >= 2 ? parts[1] : parts[0];
      return Scene(
        index: i,
        title: 'Line ${i + 1}',
        description: text,
        visualPrompt: project.images.isNotEmpty
            ? (i < project.images.length ? project.images[i] : project.images[0])
            : '',
        narration: text,
        overlayText: null,
        durationSeconds: null,
      );
    });

    // Infer classification from project data
    final classification = ClassificationSnapshotV2(
      narrativeFormatName: _inferFormat(project),
      contentType: ContentType.reel,
      productionMethod: ProductionMethod.imageSlideshow,
      goal: ContentGoal.reach,
      status: IdeaStatus.scripted,
      axisStates: const {},
      capturedAt: project.savedAt,
    );

    // Evaluate gate
    final gateReport = QualityGate.evaluateIdea(
      ideaId: project.id,
      title: project.title,
      classification: ClassificationSnapshot(
        narrativeFormatName: classification.narrativeFormatName,
        contentType: classification.contentType,
        productionMethod: classification.productionMethod,
        goal: classification.goal,
        axisStates: classification.axisStates,
        status: classification.status,
      ),
      testCount: 5,
    );

    return ContentPackageV2(
      id: 'pkg_${project.id}',
      ideaId: project.id,
      createdAt: project.savedAt,
      updatedAt: project.savedAt,
      classification: classification,
      audience: 'Parents of 1-4 year olds',
      problem: '',
      lesson: '',
      hook: project.story,
      voiceMode: gateReport.voiceMode,
      cta: '',
      reachCandidacy: ReachCandidacy.unknown,
      productionCompatibility: gateReport.needsFilming
          ? ProductionCompatibility.needsFilming
          : ProductionCompatibility.yes,
      title: project.displayName,
      script: lines.join('\n'),
      narration: lines.join('\n'),
      dialogue: '',
      caption: '',
      hashtags: [],
      scenes: scenes,
      productionMethod: ProductionMethod.imageSlideshow,
      shotList: [],
      imagePrompts: project.images,
      gateReport: gateReport,
    );
  }

  static String? _inferFormat(Project project) {
    final title = project.title.toLowerCase();
    if (title.contains('challenge') || title.contains('hunt')) return 'problemFix';
    if (title.contains('routine')) return 'routine';
    if (title.contains('list')) return 'saveThisList';
    if (title.contains('tip')) return 'quickTip';
    if (title.contains('pov')) return 'pov';
    return 'problemFix';
  }

  /// Saves a Project as a ContentPackageV2 in the package store.
  ///
  /// Returns the package ID on success, or null on failure.
  static Future<String?> saveProjectAsPackage(
    Project project,
    PackageStore store,
  ) async {
    try {
      final pkg = await convertProject(project);
      await store.save(pkg);
      return pkg.id;
    } catch (e) {
      debugPrint('ProjectToPackageBridge: failed to save project ${project.id} as package — $e');
      return null;
    }
  }

  /// Loads the most recent ContentPackageV2 for a given project ID.
  static Future<ContentPackageV2?> loadPackageForProject(
    String projectId,
    PackageStore store,
  ) async {
    final queryId = 'pkg_$projectId';
    return await store.loadById(queryId);
  }
}
