import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'browser_evaluation_result.dart';
import 'content_evaluation_service.dart';
import 'content_library_service.dart';
import 'content_studio_service.dart';
import 'theme.dart';

class EvaluationResultScreen extends StatefulWidget {
  final String ideaId;
  final String originalIdea;
  final ContentIdea? contentIdea;

  const EvaluationResultScreen({
    super.key,
    required this.ideaId,
    required this.originalIdea,
    this.contentIdea,
  });

  @override
  State<EvaluationResultScreen> createState() => _EvaluationResultScreenState();
}

class _EvaluationResultScreenState extends State<EvaluationResultScreen> {
  BrowserEvaluationResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvaluation();
  }

  Future<void> _loadEvaluation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ContentEvaluationService.evaluate(
        content: _buildContentPayload(widget.originalIdea),
        evaluationMode: 'offline',
      );

      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on EvaluationUnavailableException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Evaluation failed: ${e.toString()}';
      });
    }
  }

  Map<String, dynamic> _buildContentPayload(String idea) {
    return {
      'id': widget.contentIdea?.id ?? '',
      'category': widget.contentIdea?.category ?? '',
      'title': widget.contentIdea?.title ?? widget.originalIdea,
      'cover': widget.contentIdea?.caption ?? '',
      'opening': widget.contentIdea?.opening ?? widget.originalIdea,
      'problem': widget.contentIdea?.problem ?? '',
      'lesson': widget.contentIdea?.lesson ?? '',
      'storyDetail': widget.contentIdea?.storyDetail ?? widget.originalIdea,
      'endingBeat': widget.contentIdea?.storyDetail ?? '',
      'caption': widget.contentIdea?.caption ?? '',
      'pinnedComment': '',
      'dialogue': widget.contentIdea?.storyDetail ?? '',
      'defaultCast': widget.contentIdea?.characterIds ?? <String>[],
      'setting': widget.contentIdea?.storyDetail ?? '',
      'sceneDetail': widget.contentIdea?.storyDetail ?? '',
      'postFormat': widget.contentIdea?.format ?? 'Reel',
      'strategy': '',
      'mess': '',
      'innerThought': '',
      'keepMoralOffScreen': false,
      'quote': '',
      'detail': '',
      'punchline': '',
      'readyPrompt': '',
      'forApp': true,
      'custom': widget.contentIdea?.isCustom ?? true,
      'archived': false,
      'usedOn': '',
      'score': 0,
      'band': '',
      'reviewedOn': '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluation Result'),
        actions: [
          if (_result != null)
            IconButton(
              tooltip: 'Copy evaluation summary',
              icon: const Icon(Icons.copy),
              onPressed: _copySummary,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Evaluating idea with browser Content Rating Tool...'),
                ],
              ),
            )
          : _error != null
          ? _buildErrorState()
          : _result == null
          ? const Center(child: Text('No evaluation result'))
          : _buildResultContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Evaluation Unavailable',
              style: AppText.screenTitle.copyWith(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unknown error',
              style: AppText.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadEvaluation,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Evaluation'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Review'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent() {
    final result = _result!;
    final isReady = BrowserVerdict.isReady(result.verdict);
    final isBlocking = BrowserVerdict.isBlocking(result.verdict);

    final verdictColor = isReady
        ? AppColors.success
        : (isBlocking ? AppColors.danger : AppColors.warning);

    final List<Widget> children = <Widget>[];

    // Header
    children.add(
      Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Evaluation Result', style: AppText.screenTitle),
                const SizedBox(height: 4),
                Text(
                  'Browser Content Rating Tool - ${_formatDate(result.evaluatedAt)}',
                  style: AppText.hint,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: verdictColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: verdictColor),
            ),
            child: Text(
              result.verdict,
              style: AppText.body.copyWith(
                fontWeight: FontWeight.bold,
                color: verdictColor,
              ),
            ),
          ),
        ],
      ),
    );

    children.add(const SizedBox(height: 16));

    // Overall Score
    children.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Text('Overall Score', style: AppText.section),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    '${result.overallScore}',
                    style: AppText.screenTitle.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('/100', style: AppText.hint),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (result.scoreCapped)
                Text(
                  'Score was capped at 100',
                  style: AppText.hint.copyWith(color: AppColors.warning),
                ),
            ],
          ),
        ),
      ),
    );

    children.add(const SizedBox(height: 16));

    // Dimension Scores
    children.add(Text('Dimension Scores', style: AppText.section));
    children.add(const SizedBox(height: 8));
    for (final dim in result.dimensionScores) {
      children.add(_buildDimensionCard(dim));
    }

    children.add(const SizedBox(height: 24));

    // Findings
    if (result.criticalFindings.isNotEmpty) {
      children.add(
        _buildFindingsSection(
          'Critical Findings',
          result.criticalFindings,
          AppColors.danger,
          Icons.error,
        ),
      );
      children.add(const SizedBox(height: 16));
    }
    if (result.majorFindings.isNotEmpty) {
      children.add(
        _buildFindingsSection(
          'Major Findings',
          result.majorFindings,
          AppColors.warning,
          Icons.warning_amber_rounded,
        ),
      );
      children.add(const SizedBox(height: 16));
    }
    if (result.minorFindings.isNotEmpty) {
      children.add(
        _buildFindingsSection(
          'Minor Findings',
          result.minorFindings,
          AppColors.textSoft,
          Icons.info_outline,
        ),
      );
      children.add(const SizedBox(height: 16));
    }

    // Suggestions
    if (result.suggestions.isNotEmpty) {
      children.add(Text('Suggestions', style: AppText.section));
      children.add(const SizedBox(height: 8));
      for (final s in result.suggestions) {
        children.add(
          Card(
            child: ListTile(
              leading: Icon(Icons.lightbulb_outline, color: AppColors.accent),
              title: Text(s.title, style: AppText.body),
              subtitle: Text(
                'Original: "${s.original}"\nSuggested: "${s.suggested}"',
                style: AppText.small,
              ),
              isThreeLine: true,
            ),
          ),
        );
      }
      children.add(const SizedBox(height: 24));
    }

    // Evaluation Meta
    children.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Evaluation Details', style: AppText.section),
              const SizedBox(height: 8),
              _metaRow('Mode', result.evaluationMode),
              _metaRow('Evaluated At', _formatDate(result.evaluatedAt)),
              _metaRow('Version', result.evaluationVersion),
              _metaRow('Evaluation ID', result.evaluationId),
              if (result.contentHash.isNotEmpty)
                _metaRow('Content Hash', result.contentHash),
            ],
          ),
        ),
      ),
    );

    children.add(const SizedBox(height: 24));

    // Actions
    children.add(
      Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Review'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _copyFullReport,
              icon: const Icon(Icons.copy),
              label: const Text('Copy Full Report'),
            ),
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDimensionCard(DimensionScore dim) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    dim.name,
                    style: AppText.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (dim.score >= 7 ? AppColors.success : AppColors.warning)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${dim.score}/${dim.weight}',
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: dim.score >= 7
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Explanation: ${dim.explanation}', style: AppText.body),
            if (dim.whatWorks.isNotEmpty)
              Text(
                '[OK] What works: ${dim.whatWorks}',
                style: AppText.body.copyWith(color: AppColors.success),
              ),
            if (dim.needsImprovement.isNotEmpty)
              Text(
                '[WARN] Needs improvement: ${dim.needsImprovement}',
                style: AppText.body.copyWith(color: AppColors.warning),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindingsSection(
    String title,
    List<EvaluationFinding> findings,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: AppText.section.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ...findings.map(
          (f) => Card(
            color: color.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.circle, size: 10, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f.title,
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          f.severity.toUpperCase(),
                          style: AppText.small.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Explanation: ${f.explanation}', style: AppText.body),
                  if (f.evidence.isNotEmpty)
                    Text('Evidence: ${f.evidence}', style: AppText.hint),
                  if (f.suggestedFix.isNotEmpty)
                    Text(
                      'Suggested fix: ${f.suggestedFix}',
                      style: AppText.body.copyWith(color: AppColors.accent),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 120, child: Text(label, style: AppText.hint)),
          Expanded(child: Text(value, style: AppText.body)),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy - h:mm a').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  void _copySummary() {
    if (_result == null) return;
    final result = _result!;
    final buffer = StringBuffer();
    buffer.writeln('Evaluation Summary for ${widget.ideaId}');
    buffer.writeln('========================================');
    buffer.writeln('Verdict: ${result.verdict}');
    buffer.writeln('Overall Score: ${result.overallScore}/100');
    buffer.writeln('Mode: ${result.evaluationMode}');
    buffer.writeln('Evaluated: ${_formatDate(result.evaluatedAt)}');
    buffer.writeln('');
    buffer.writeln('Dimension Scores:');
    for (final dim in result.dimensionScores) {
      buffer.writeln(
        '  ${dim.name}: ${dim.score}/${dim.weight} -- ${dim.explanation}',
      );
    }
    if (result.criticalFindings.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Critical Findings:');
      for (final f in result.criticalFindings) {
        buffer.writeln('  - ${f.title} (${f.severity})');
      }
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Evaluation summary copied')));
  }

  void _copyFullReport() {
    _copySummary();
  }
}
