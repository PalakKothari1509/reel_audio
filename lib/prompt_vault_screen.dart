import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'prompt_vault.dart';
import 'theme.dart';

class PromptVaultScreen extends StatefulWidget {
  const PromptVaultScreen({super.key});

  @override
  State<PromptVaultScreen> createState() => _PromptVaultScreenState();
}

class _PromptVaultScreenState extends State<PromptVaultScreen> {
  List<SavedPrompt> _prompts = const [];
  bool _loading = true;
  PromptType? _typeFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await PromptVault.getAll();
    if (!mounted) return;
    setState(() {
      _prompts = all;
      _loading = false;
    });
  }

  List<SavedPrompt> get _visible {
    var filtered = _prompts;
    if (_typeFilter != null) {
      filtered = filtered.where((p) => p.type == _typeFilter!).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.promptText.toLowerCase().contains(q) ||
              p.contentId.toLowerCase().contains(q))
          .toList();
    }
    return filtered;
  }

  void _copyPrompt(SavedPrompt prompt) {
    Clipboard.setData(ClipboardData(text: prompt.promptText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${prompt.title} — copied to clipboard')),
    );
  }

  void _deletePrompt(SavedPrompt prompt) async {
    await PromptVault.delete(prompt.id);
    if (!mounted) return;
    setState(() {
      _prompts.removeWhere((p) => p.id == prompt.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${prompt.title} — deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Vault'),
        actions: [
          if (_typeFilter != null)
            IconButton(
              tooltip: 'Clear filter',
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () => setState(() => _typeFilter = null),
            ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
        bottom: AppBar(
          toolbarHeight: kMinInteractiveDimension,
          title: TextField(
            decoration: InputDecoration(
              hintText: 'Search prompts...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _visible.isEmpty
              ? const Center(
                  child: Text('No saved prompts. Generate content to populate the vault.'),
                )
              : ListView.separated(
                  itemCount: _visible.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = _visible[i];
                    return Dismissible(
                      key: Key(p.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: AppColors.danger,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const Icon(Icons.delete, color: Colors.white70),
                      ),
                      onDismissed: (_) => _deletePrompt(p),
                      child: ListTile(
                        leading: Icon(
                          switch (p.type) {
                            PromptType.script => Icons.description_outlined,
                            PromptType.video => Icons.smart_display_outlined,
                            PromptType.sceneImage => Icons.image_outlined,
                            PromptType.caption => Icons.format_quote_outlined,
                            PromptType.story => Icons.lightbulb_outline,
                            _ => Icons.miscellaneous_services_outlined,
                          },
                          color: AppColors.primary,
                        ),
                        title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${p.type.name} • v${p.version} • ${p.contentId}',
                          style: AppText.hint.copyWith(fontSize: 12),
                        ),
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'copy',
                              child: const Text('Copy Prompt'),
                              onTap: () => _copyPrompt(p),
                            ),
                            PopupMenuItem(
                              value: 'version',
                              child: Text('Version ${p.version}'),
                              onTap: () {},
                            ),
                          ],
                        ),
                        onTap: () => _showPromptDetail(p),
                      ),
                    );
                  },
                ),
      floatingActionButton: _buildFilterFab(),
    );
  }

  Widget _buildFilterFab() {
    if (_typeFilter != null) return _buildActiveFilterFab();
    return FloatingActionButton(
      onPressed: _showFilterSheet,
      tooltip: 'Filter',
      child: const Icon(Icons.filter_list),
    );
  }

  Widget _buildActiveFilterFab() {
    return FloatingActionButton(
      onPressed: _showFilterSheet,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      child: const Icon(Icons.filter_alt),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textFaint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Filter by type', style: AppText.section),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(null, 'All'),
                ...PromptType.values.map((t) => _filterChip(t, t.name)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(PromptType? type, String label) {
    final selected = _typeFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _typeFilter = type),
    );
  }

  void _showPromptDetail(SavedPrompt prompt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(prompt.title, style: AppText.screenTitle),
                Text('v${prompt.version}', style: AppText.hint),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${prompt.type.name} • ${prompt.status.name} • ${prompt.contentId}',
              style: AppText.hint.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  prompt.promptText,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _copyPrompt(prompt),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
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
