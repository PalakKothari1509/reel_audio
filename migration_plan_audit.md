# MIGRATION PLAN: content_ideas.dart ? assets/data/content_ideas.json

**Status:** Audit Only - No Changes Made  
**Date:** 2026-11-02  
**Scope:** Migrate all built-in HookIdea records from Dart const list to JSON asset

## 1. INSPECT HOOKIDEA MODEL

### Class Definition (lib/content_ideas.dart:190-450)
HookIdea has 34 fields including id, category, title, cover, opening, problem, lesson, postFormat, strategy, caption, pinnedComment, forApp, usedOn, custom, archived, storyDetail, setting, sceneDetail, dialogue, mess, innerThought, endingBeat, defaultCast (List<String>), keepMoralOffScreen, quote, detail, punchline, readyPrompt, score, band, reviewedOn.

### Methods
- const HookIdea constructor
- copyWith
- toJson() / fromJson()
- asStoryText()

### Global Lists
- kDefaultHooks (117 ideas)
- kSafetyHooks
- kDefaultHooksWithRewrite (alias)
- kDay14PostIdeas (idea_93-116)

## 2. ALL REFERENCES
- 21 usages of kDefaultHooks across 9 files
- 209 usages of HookIdea across all lib/

## 3. DEPENDENCIES
- Const/runtime lists, serialization exists, user edits via HookStore, custom ideas supported

## 4. JSON SCHEMA PROPOSAL
All 34 fields preserved with defaults matching HookIdea

## 5. REPOSITORY DESIGN
Async loading from assets/data/content_ideas.json with caching and fallback to Dart

## 6. REQUIRED CHANGES
- pubspec.yaml add assets
- Create assets/data/content_ideas.json and lib/data/content_ideas_repository.dart
- Modify content_ideas.dart and 9 consuming files
- Preload at app start

## 7. RISKS & BACKWARD COMPATIBILITY
High risk due to synchronous API usage, need to maintain compatibility

**RECOMMENDATION:** Do not migrate yet without approval. Phased approach recommended.
