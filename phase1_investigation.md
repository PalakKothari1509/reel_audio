PHASE 1 INVESTIGATION REPORT
============================

Source: lib/content_ideas.dart
Total HookIdea instances in file: 117 (all unique IDs, no duplicates)
- Inside buildDefaultHooks() list (indent 4 spaces): 109 instances (lines 362-6915)
- Top-level HookIdea declarations (indent 0): 8 instances at lines 3777, 3951, 4129, 4188, 4362, 4592, 4649, 4762

IDs of top-level instances:
- idea_60 (line ~3778)
- idea_63 (line ~3952)  
- idea_66 (line ~4130)
- idea_67 (line ~4189)
- idea_70 (line ~4363)
- idea_74 (line ~4593)
- idea_75 (line ~4650)
- idea_77 (line ~4763)

Count discrepancy explanation:
- Earlier confusion: 109 in buildDefaultHooks() + 8 separate = 117 total
- All 8 separate top-level instances are NOT inside buildDefaultHooks() list
- They exist as separate top-level declarations in content_ideas.dart
- kDefaultHooks = buildDefaultHooks() only contains the 109 from the list
- The 8 separate instances are NOT in kDefaultHooks

So total built-in records = 109 (from kDefaultHooks) + 8 (separate top-level) = 117

To export all 117:
1. Export all 109 from kDefaultHooks via toJson()
2. Also need to export the 8 separate top-level HookIdea instances via their toJson()
3. But the 8 are declared as top-level variables/instances? Let us look up how they're declared.

Looking at line ~3777: just "HookIdea(" at column 0 - not assigned to a variable name visible. They might be declared as top-level finals or just instances. Need to check the actual pattern.
