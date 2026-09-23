import 'package:flutter/material.dart';

import 'day14_posts.dart';
import 'plan_data.dart';
import 'reply_assistant.dart';
import 'theme.dart';

// ── Plan: hooks, schedule, results ────────────────────────────────────────────
//
// One screen for the decisions that happen before and after the reel: which story to
// tell, when to post it, and whether that time actually worked. Choosing a hook here
// hands it back to the story screen already laid out as the story form.

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});
  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plan'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSoft,
            isScrollable: true,
            tabs: [
              Tab(text: 'Hooks'), Tab(text: 'When to post'),
              Tab(text: 'Results'), Tab(text: 'Replies'),
            ],
          ),
        ),
        // Replies sits here as well as in the posting kit, so answering a comment on an
        // older reel does not mean finding its story first.
        body: const TabBarView(children: [
          _HooksTab(), _ScheduleTab(), _ResultsTab(), ReplyAssistant(),
        ]),
      ),
    );
  }
}

// ── Hooks ─────────────────────────────────────────────────────────────────────

class _HooksTab extends StatefulWidget {
  const _HooksTab();
  @override
  State<_HooksTab> createState() => _HooksTabState();
}

class _HooksTabState extends State<_HooksTab> {
  List<HookIdea> _hooks = [];
  bool _unusedOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await HookStore.load();
    if (mounted) setState(() => _hooks = all);
  }

  String _used(String iso) {
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final days = DateTime.now().difference(t).inDays;
    return days == 0 ? 'Used today' : days == 1 ? 'Used yesterday' : 'Used $days days ago';
  }

  Future<void> _edit(HookIdea? hook) async {
    final cover = TextEditingController(text: hook?.cover ?? '');
    final opening = TextEditingController(text: hook?.opening ?? '');
    final problem = TextEditingController(text: hook?.problem ?? '');
    final lesson = TextEditingController(text: hook?.lesson ?? '');
    var category = hook?.category ?? kHookCategories.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: Text(hook == null ? 'New hook' : 'Edit hook'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            initialValue: category,
            items: kHookCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setD(() => category = v ?? category),
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          Gap.s,
          TextField(controller: cover,
            decoration: const InputDecoration(labelText: 'Cover (2–4 words)')),
          Gap.s,
          TextField(controller: opening, maxLines: 2,
            decoration: const InputDecoration(labelText: 'First line said aloud')),
          Gap.s,
          TextField(controller: problem, maxLines: 2,
            decoration: const InputDecoration(labelText: 'The real problem')),
          Gap.s,
          TextField(controller: lesson, maxLines: 2,
            decoration: const InputDecoration(labelText: 'The lesson')),
        ])),
        actions: [
          if (hook != null && hook.custom)
            TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      )),
    );
    if (saved == null) return;

    final list = List.of(_hooks);
    if (saved == false && hook != null) {
      list.removeWhere((h) => h.id == hook.id);
    } else if (cover.text.trim().isNotEmpty) {
      final updated = HookIdea(
        id: hook?.id ?? 'c${DateTime.now().millisecondsSinceEpoch}',
        category: category,
        cover: cover.text.trim(),
        opening: opening.text.trim(),
        problem: problem.text.trim(),
        lesson: lesson.text.trim(),
        forApp: hook?.forApp ?? true,
        usedOn: hook?.usedOn ?? '',
        custom: hook?.custom ?? true,
      );
      final i = list.indexWhere((h) => h.id == updated.id);
      if (i >= 0) { list[i] = updated; } else { list.add(updated); }
    }
    await HookStore.save(list);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _hooks.where((h) => !_unusedOnly || h.usedOn.isEmpty).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add hook'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Row(children: [
            Expanded(child: Text('${shown.length} hooks', style: AppText.hint)),
            // Unused first by default: the point of keeping a list is not telling the
            // same story twice in a month.
            FilterChip(
              label: const Text('Not used yet'),
              selected: _unusedOnly,
              onSelected: (v) => setState(() => _unusedOnly = v),
            ),
          ]),
          Gap.s,
          for (final category in kHookCategories) ...[
            if (shown.any((h) => h.category == category)) ...[
              Gap.s,
              SectionTitle(category),
              ...shown.where((h) => h.category == category).map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(h.cover, style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text))),
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _edit(h)),
                    ]),
                    Text('“${h.opening}”', style: AppText.body),
                    Gap.xs,
                    Text(h.problem, style: AppText.small),
                    Text('Lesson: ${h.lesson}', style: AppText.small),
                    Gap.s,
                    Row(children: [
                      if (h.usedOn.isNotEmpty)
                        Text(_used(h.usedOn), style: const TextStyle(
                          fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (h.forApp)
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(context, h),
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Use this story'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                        )
                      else
                        const Text('Film this one yourself', style: AppText.small),
                    ]),
                  ]),
                ),
              )),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Schedule ──────────────────────────────────────────────────────────────────

class _ScheduleTab extends StatefulWidget {
  const _ScheduleTab();
  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  List<PostSlot> _slots = [];

  @override
  void initState() {
    super.initState();
    ScheduleStore.load().then((s) { if (mounted) setState(() => _slots = s); });
  }

  Future<void> _pick(int index, bool first) async {
    final slot = _slots[index];
    final parts = (first ? slot.first : slot.backup).split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 13,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0),
    );
    if (picked == null) return;
    final t = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      _slots[index] = PostSlot(slot.weekday, first ? t : slot.first,
        first ? slot.backup : t, slot.focus);
    });
    await ScheduleStore.save(_slots);
  }

  @override
  Widget build(BuildContext context) {
    if (_slots.isEmpty) return const Center(child: CircularProgressIndicator());
    final today = DateTime.now().weekday;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          colour: AppColors.primarySoft,
          borderColour: AppColors.primary,
          child: Row(children: [
            const Icon(Icons.schedule, color: AppColors.primary),
            Gap.wS,
            Expanded(child: Text('Next: ${nextPostingTime(_slots)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text))),
          ]),
        ),
        Gap.m,
        const Text('A starting guess built around a parent\'s day — after school and '
            'lunch, and after bedtime. Tap a time to change it. After a few weeks, '
            'Results shows what actually works for your followers.',
          style: AppText.hint),
        Gap.m,
        ...List.generate(_slots.length, (i) {
          final s = _slots[i];
          final isToday = s.weekday == today;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              colour: isToday ? AppColors.accentSoft : null,
              borderColour: isToday ? AppColors.accent : null,
              child: Row(children: [
                SizedBox(width: 92, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(kDayNames[s.weekday - 1], style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.text)),
                  if (isToday) const Text('Today', style: TextStyle(
                    fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w700)),
                ])),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 6, children: [
                    ActionChip(label: Text(formatClock(s.first)),
                      onPressed: () => _pick(i, true)),
                    ActionChip(label: Text('or ${formatClock(s.backup)}'),
                      onPressed: () => _pick(i, false)),
                  ]),
                  Text(s.focus, style: AppText.small),
                ])),
              ]),
            ),
          );
        }),
      ],
    );
  }
}

// ── Results ───────────────────────────────────────────────────────────────────

class _ResultsTab extends StatefulWidget {
  const _ResultsTab();
  @override
  State<_ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<_ResultsTab> {
  List<PostRecord> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PostLogStore.load();
    if (mounted) setState(() { _posts = p; _loading = false; });
  }

  Future<void> _enter(PostRecord post) async {
    String bucketValue = post.bucket;
    final fields = {
      'Views': TextEditingController(text: post.views == 0 ? '' : '${post.views}'),
      'Likes': TextEditingController(text: post.likes == 0 ? '' : '${post.likes}'),
      'Comments': TextEditingController(text: post.comments == 0 ? '' : '${post.comments}'),
      'Saves': TextEditingController(text: post.saves == 0 ? '' : '${post.saves}'),
      'Shares': TextEditingController(text: post.shares == 0 ? '' : '${post.shares}'),
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('From Instagram, about two days after posting — the first hour says '
              'little on its own.', style: AppText.small),
          Gap.s,
          ...fields.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(controller: e.value, keyboardType: TextInputType.number,
             decoration: InputDecoration(labelText: e.key, isDense: true)),
          )),
          Gap.s,
          DropdownButtonFormField<String>(
            value: bucketValue.isEmpty ? null : bucketValue,
            hint: const Text('Content bucket (optional)'),
            items: [
              const DropdownMenuItem(value: '', child: Text('None')),
              ...kContentBuckets.map((b) => DropdownMenuItem(
                  value: b.id,
                  child: Row(children: [
                    Container(width: 12, height: 12,
                      decoration: BoxDecoration(color: b.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(b.shortLabel),
                  ]),
              )),
            ],
            onChanged: (v) => bucketValue = v ?? '',
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    int n(String k) => int.tryParse(fields[k]!.text.trim()) ?? 0;
    final updated = post.copyWith(views: n('Views'), likes: n('Likes'),
      comments: n('Comments'), saves: n('Saves'), shares: n('Shares'),
      bucket: bucketValue);
    await PostLogStore.save(_posts.map((p) => p.id == post.id ? updated : p).toList());
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final byTime = resultsByTime(_posts);
    final byBucket = resultsByBucket(_posts);
    final withResults = _posts.where((p) => p.hasResults).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Best time so far'),
        if (withResults < 6)
          AppCard(child: Text(
            withResults == 0
                ? 'No results yet. After posting a reel, tap "I posted it" on the reel '
                  'screen, then come back in two days and add its numbers here.'
                : '$withResults of 6 posts with numbers. Fewer than that and one lucky '
                  'post decides everything, so there is no "best time" to show yet.',
            style: AppText.hint))
        else
          AppCard(child: Column(children: [
            for (final b in byTime)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.bucket, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${b.posts} posts', style: AppText.small),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${b.avgViews.round()} views', style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Text('${b.avgSaves.toStringAsFixed(1)} saves · '
                        '${b.avgComments.toStringAsFixed(1)} comments', style: AppText.small),
                  ]),
                ]),
              ),
          ])),
        if (byBucket.isNotEmpty) ...[
          Gap.l,
          const SectionTitle('Best content bucket'),
          AppCard(child: Column(children: [
            for (final b in byBucket)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  CircleAvatar(radius: 8, backgroundColor: bucketById(b.bucket)?.color ?? AppColors.textFaint),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(bucketLabel(b.bucket), style: const TextStyle(
                      fontWeight: FontWeight.w700)),
                    Text('${b.posts} posts', style: AppText.small),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${b.avgViews.round()} views', style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Text('${b.totalSaves} saves · ${b.totalComments} comments',
                      style: AppText.small),
                  ]),
                ]),
              ),
          ])),
        ],
        Gap.l,
        SectionTitle('Posted', trailing: '${_posts.length}'),
        if (_posts.isEmpty)
          const Text('Nothing logged yet.', style: AppText.hint),
        ..._posts.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _enter(p),
            child: AppCard(child: Row(children: [
              if (p.bucket.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: bucketById(p.bucket)?.color ?? AppColors.textFaint,
                    child: Text(bucketLabel(p.bucket)[0],
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${kDayNames[p.postedAt.weekday - 1]} '
                    '${formatClock('${p.postedAt.hour}:${p.postedAt.minute.toString().padLeft(2, '0')}')}',
                  style: AppText.small),
              ])),
              Text(p.hasResults ? '${p.views} views' : 'Add numbers',
                style: TextStyle(fontWeight: FontWeight.w700,
                  color: p.hasResults ? AppColors.text : AppColors.accent)),
            ])),
          ),
        )),
      ],
    );
  }
}
