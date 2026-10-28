import 'package:flutter/material.dart';

import 'content_studio_service.dart';
import 'prompts.dart';
import 'story_ideas.dart';
import 'theme.dart';

/// The screen that sits between entering an idea and generating content from it.
///
/// Shows the story quality check (10 criteria, score, band), the shareability
/// analysis (who shares, to whom, why), and the five hook choices. The user
/// must pick a hook and explicitly approve before the generation request is sent.
class IdeaReviewScreen extends StatefulWidget {
  final IdeaEvaluation evaluation;
  final String originalIdea;
  final bool isRegenerating;
  final bool isGenerating;
  final String status;
  final void Function(HookChoice? hook) onApprove;
  final VoidCallback onRegenerate;
  final VoidCallback onBack;
  final VoidCallback? onEditIdea;

  const IdeaReviewScreen({
    super.key,
    required this.evaluation,
    required this.originalIdea,
    required this.onApprove,
    required this.onRegenerate,
    required this.onBack,
    this.onEditIdea,
    this.isRegenerating = false,
    this.isGenerating = false,
    this.status = '',
  });

  @override
  State<IdeaReviewScreen> createState() => _IdeaReviewScreenState();
}

class _IdeaReviewScreenState extends State<IdeaReviewScreen> {
  late HookChoice? _selectedHook;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _selectedHook = widget.evaluation.check.hooks.isNotEmpty
        ? widget.evaluation.check.hooks.first
        : null;
  }

  void _setHook(HookChoice? hook) {
    setState(() => _selectedHook = hook);
  }

  void _generate() {
    widget.onApprove(_selectedHook);
  }

  Color _bandColor(String band) => switch (band) {
        'Ready' => AppColors.primary,
        'Improve' => AppColors.warning,
        _ => AppColors.danger,
      };

  String _bandNote(String band) => switch (band) {
        'Ready' => 'Good to make today.',
        'Improve' => 'Fix the points below before making pictures.',
        _ => 'Not worth the pictures yet — rework the story first.',
      };

  @override
  Widget build(BuildContext context) {
    final check = widget.evaluation.check;
    final share = widget.evaluation.shareability;
    final band = check.band;
    final bandColor = _bandColor(band);
    final canGenerate = _agreed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Your Idea'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Score header ──────────────────────────────────────────────
            _ScoreHeader(
              score: check.effectiveScore,
              band: band,
              bandColor: bandColor,
              bandNote: _bandNote(band),
              verdict: check.verdict,
            ),
            Gap.l,

            // ── Ten check rows ────────────────────────────────────────────
            const Text('Quality Check', style: AppText.section),
            Gap.s,
            ...check.rows.map((r) => _CheckRow(row: r)),
            if (check.rows.isEmpty) ...[
              ...check.good.map((g) => _GoodItem(text: g)),
            ],
            Gap.l,

            // ── Good / Missing ────────────────────────────────────────────
            if (check.good.isNotEmpty || check.missing.isNotEmpty)
              _GoodMissingCard(good: check.good, missing: check.missing),
            if (check.good.isNotEmpty || check.missing.isNotEmpty) Gap.l,

            // ── Shareability ──────────────────────────────────────────────
            const Text('Shareability', style: AppText.section),
            Gap.s,
            _ShareabilityCard(shareability: share),
            Gap.l,

            // ── Hook picker ───────────────────────────────────────────────
            const Text('Pick a Cover Hook', style: AppText.section),
            Gap.s,
            Text(
              'This is drawn big on the first frame — the thumbnail most '
              'people see. Pick the one that best matches the story.',
              style: AppText.hint,
            ),
            Gap.s,
            _HookPicker(
              hooks: check.hooks,
              selected: _selectedHook,
              onChanged: _setHook,
            ),
            Gap.l,

            // ── Approval gate ─────────────────────────────────────────────
            _ApprovalGate(
              agreed: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              onRegenerate: widget.onRegenerate,
              onEditIdea: widget.onEditIdea,
              isRegenerating: widget.isRegenerating,
              isGenerating: widget.isGenerating,
              status: widget.status,
              canGenerate: canGenerate,
              onGenerate: _generate,
              band: band,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Score header ─────────────────────────────────────────────────────────────

class _ScoreHeader extends StatelessWidget {
  final int score;
  final String band;
  final Color bandColor;
  final String bandNote;
  final String verdict;

  const _ScoreHeader({
    required this.score,
    required this.band,
    required this.bandColor,
    required this.bandNote,
    required this.verdict,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      colour: AppColors.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$score/10',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: bandColor,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bandColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  band,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: bandColor,
                  ),
                ),
              ),
            ],
          ),
          Gap.xs,
          Text(bandNote,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: bandColor)),
          if (verdict.isNotEmpty) ...[
            Gap.xs,
            Text(verdict, style: AppText.hint),
          ],
        ],
      ),
    );
  }
}

// ── Check row ──────────────────────────────────────────────────────────────────

class _CheckRow extends StatelessWidget {
  final CheckRow row;
  const _CheckRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            row.pass ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: row.pass ? AppColors.primary : AppColors.danger,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: row.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (row.note.isNotEmpty)
                    TextSpan(
                      text: ' — ${row.note}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSoft,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Good / missing ─────────────────────────────────────────────────────────────

class _GoodMissingCard extends StatelessWidget {
  final List<String> good;
  final List<String> missing;

  const _GoodMissingCard({required this.good, required this.missing});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (good.isNotEmpty) ...[
            const Text('What works',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSoft)),
            Gap.xs,
            ...good.map((g) => _Bullet(text: g, color: AppColors.primary)),
          ],
          if (good.isNotEmpty && missing.isNotEmpty) Gap.s,
          if (missing.isNotEmpty) ...[
            const Text('Needs work',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSoft)),
            Gap.xs,
            ...missing.map((m) => _Bullet(text: m, color: AppColors.warning)),
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final Color color;
  const _Bullet({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ── Good item (fallback when rows are empty) ──────────────────────────────────

class _GoodItem extends StatelessWidget {
  final String text;
  const _GoodItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ── Shareability ───────────────────────────────────────────────────────────────

class _ShareabilityCard extends StatelessWidget {
  final ShareabilityAnalysis shareability;
  const _ShareabilityCard({required this.shareability});

  @override
  Widget build(BuildContext context) {
    final isHigh = shareability.isHighConfidence;
    final colour = isHigh ? AppColors.primary : AppColors.warning;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.share, size: 18, color: colour),
              const SizedBox(width: 6),
              Text('Share trigger',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSoft)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colour.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  shareability.confidence,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colour),
                ),
              ),
            ],
          ),
          Gap.xs,
          RichText(
            text: TextSpan(
              style: AppText.body,
              children: [
                const TextSpan(
                    text: 'Who sends it: ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: shareability.sender),
              ],
            ),
          ),
          Gap.xs,
          RichText(
            text: TextSpan(
              style: AppText.body,
              children: [
                const TextSpan(
                    text: 'To whom: ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: shareability.recipient),
              ],
            ),
          ),
          Gap.xs,
          RichText(
            text: TextSpan(
              style: AppText.body,
              children: [
                const TextSpan(
                    text: 'Why: ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: shareability.reason),
              ],
            ),
          ),
          if (shareability.note.isNotEmpty) ...[
            Gap.xs,
            RichText(
              text: TextSpan(
                style: AppText.hint,
                children: [
                  const TextSpan(
                      text: 'Tip: ',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSoft)),
                  TextSpan(text: shareability.note),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Hook picker ─────────────────────────────────────────────────────────────────

class _HookPicker extends StatelessWidget {
  final List<HookChoice> hooks;
  final HookChoice? selected;
  final void Function(HookChoice?) onChanged;

  const _HookPicker({
    required this.hooks,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (hooks.isEmpty) {
      return const Text('No hooks were generated.', style: AppText.hint);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: hooks.map((h) {
        final isSelected = selected == h;
        return GestureDetector(
          onTap: () => onChanged(h),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints:
                const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.text,
                    )),
                const SizedBox(height: 2),
                Text(h.type,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white70
                          : AppColors.textFaint,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Approval gate ─�─────────────────────────────────────────────────────────────

class _ApprovalGate extends StatelessWidget {
  final bool agreed;
  final void Function(bool?) onChanged;
  final VoidCallback onRegenerate;
  final VoidCallback? onEditIdea;
  final bool isRegenerating;
  final bool isGenerating;
  final String status;
  final bool canGenerate;
  final void Function() onGenerate;
  final String band;

  const _ApprovalGate({
    required this.agreed,
    required this.onChanged,
    required this.onRegenerate,
    this.onEditIdea,
    required this.isRegenerating,
    required this.isGenerating,
    required this.status,
    required this.canGenerate,
    required this.onGenerate,
    required this.band,
  });

  @override
  Widget build(BuildContext context) {
    final canProceed = band == 'Ready'
        ? agreed
        : band == 'Improve'
            ? agreed
            : false;

    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: agreed,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Text(
                'I have reviewed this idea and want to proceed',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
            ),
          ],
        ),
        Gap.s,
        if (band == 'Rewrite')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'This idea scored below 7. Consider editing it or regenerating.',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger),
            ),
          ),
        if (band == 'Improve' && onEditIdea != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Tap Improve Idea to edit and re-check before generating.',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning),
            ),
          ),
        if (status.isNotEmpty) ...[
          StatusBar(message: status),
          Gap.s,
        ],
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: 'Generate Content',
            icon: Icons.auto_awesome,
            loading: isGenerating,
            onPressed: (canProceed && !isGenerating) ? onGenerate : null,
          ),
        ),
        Gap.s,
        SecondaryButton(
          label: 'Regenerate Review',
          icon: Icons.refresh,
          onPressed: isRegenerating ? null : onRegenerate,
        ),
        if (band == 'Improve' && onEditIdea != null) ...[
          Gap.s,
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'Improve Idea',
              icon: Icons.edit,
              onPressed: isGenerating ? null : onEditIdea!,
            ),
          ),
        ],
      ],
    );
  }
}
