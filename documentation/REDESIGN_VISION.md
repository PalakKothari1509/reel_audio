# Application Redesign Vision

**Status**: Proposal — pending architecture audit of existing `reel_audio` codebase

**Author**: Content Studio redesign plan

**Date**: October 12, 2026

---

## 1. Vision Statement

The Reel Audio application has evolved from a simple Reel maker into a content-planning, idea-management, Reel-generation, and Instagram-performance system for **Fun Learning With Palak**.

The problem is no longer missing features — it is that all existing capabilities need to work together as **one simple, connected workflow**.

**Core goal**: Help Palak move ideas through a complete, connected journey:

```
IDEA → CONTENT LIBRARY → PLAN → GENERATE → REVIEW → PUBLISH → MEASURE → IMPROVE
```

Everything must be connected. No re-entering the same idea between screens.

---

## 2. First Major Change: Fix the Idea Vault and Content Library Relationship

### Problem

The current documentation describes two separate data stores:
- `ContentLibrary` (via `ContentLibrary.add()`)
- `ContentAuditStore` (via "Export to Audit")

This separation causes ideas to exist in multiple places without a clear single source of truth.

### Recommended Architecture

```
                   CONTENT STUDIO
                         |
                         v
                  CANONICAL LIBRARY
                  content_library.json
                         |
              +----------+----------+
              |                     |
              v                     v
           IDEA VAULT          ALL CONTENT
              |                     |
              +----------+----------+
                         |
              +----------+----------+
              |          |          |
              v          v          v
            PLAN      GENERATE    ARCHIVE
                         |
                         v
                  CONTENT PACKAGE
                         |
                         v
                   PUBLISH MANUALLY
                         |
                         v
                  RECORD PERFORMANCE
```

### What Should Happen When You Add an Idea

**Input example:**
- Title: *Rio Doesn't Want to Brush*
- Problem: *Rio refuses to brush his teeth.*
- Characters: Rio and Mumma
- Learning goal: *Make the brushing routine easier to approach.*
- Format: Story Reel

**When you tap Save Idea:**
1. Validate required fields.
2. Check for possible duplicates.
3. Create a unique idea ID.
4. Save to the canonical Content Library.
5. Make immediately visible in Idea Vault and All Content.
6. Preserve title, description, classification, and character information.
7. Make available in the Reel generator.
8. Show success message.

**No second step called "Export to Content Library" should be needed.**

### Idea Status States

| Status        | Meaning                                                     |
| ------------- | ----------------------------------------------------------- |
| Idea          | Captured, not yet developed                                |
| In Progress   | Being developed                                             |
| Needs Review  | Requires a decision or correction                          |
| Ready         | Approved for production                                     |
| Produced      | Content package created                                     |
| Published     | Posted to Instagram                                         |
| Archived      | Retained for reference but not in the active queue         |

> **Important**: Saving an idea should not automatically pass the Quality Gate or mark it ready to publish. Saving and approving are two different operations.

### Edit and Archive Behavior

- **Editing** updates the canonical record, not a new copy. Preserve the same idea ID.
- **Archiving** removes from active queue without deleting history.
- **Deleting** requires confirmation and should not destroy related published-performance records.

### Key Recommendation

**Idea Vault and All Content should be two views of the same underlying library — not two separate collections.**

---

## 3. Second Major Change: Redesign Navigation

### Current State

Seven top-level destinations:
1. Content Library
2. Generate Reel
3. Experiment Log
4. Quality Gate
5. Duplication Check
6. Performance Dashboard
7. Settings

### Problem

Logically organised by technical components, not by daily workflow.

### Proposed Navigation

| Navigation    | Purpose                                                          |
| ------------- | ---------------------------------------------------------------- |
| **Home**      | See what needs attention; continue work                         |
| **Idea Vault**| Capture, browse, organise, and develop ideas                    |
| **Create**    | Generate and edit content packages                              |
| **My Content**| Track production, published content, and performance          |
| **Insights**  | Understand results; identify what to try next                   |
| **Settings**  | Manage brand, characters, AI configuration, and preferences     |

### Supporting Tools (contextual, not top-level)

| Tool              | Where it appears                                           |
| ----------------- | ---------------------------------------------------------- |
| Duplication Check | Add Idea and Edit Idea flows                               |
| Quality Gate      | Content approval process                                   |
| Experiment Log    | Related published content and Insights                     |
| Performance data  | Content item detail screen and Insights                    |

---

## 4. Redesigned Home Screen

### Purpose

Answer one question: **What should I do next?**

### Structure

#### Welcome Section
```
Good morning, Palak! ❤️
Let's create something meaningful for little learners.

Quick actions:    [+ Add Idea]  [Create a Reel]  [View My Content]
```

#### Your Content Pipeline
| Section                      | Example |
| ---------------------------- | ------: |
| New ideas                    |      12 |
| Ideas in progress            |       5 |
| Ready to create              |       4 |
| Packages created             |       3 |
| Published, awaiting metrics  |       6 |

Each card is clickable and opens the relevant filtered list.

#### Continue Where You Left Off
```
Rio Doesn't Want to Brush
Status: In Progress
Last updated: [date]
Next step: Continue story generation
[Continue Creating]
```

#### Content Reminders
Show only when underlying data supports it:
- Published Reels missing performance data
- Ideas awaiting approval
- Content packages not yet reviewed
- Formats with fewer than 5 tests
- Possible duplicate ideas awaiting a decision

### What to Avoid

Do not fill the Home screen with every chart, filter, tool, or configuration option. One or two taps to start the next task.

---

## 5. Third Major Change: Unify Reel Generation

### Problem

Standard Reel and Trial Reel appear as separate formats, but the generation process may already share the same pipeline.

### Recommendation

**One core generation service** with different output and experiment configurations.

```
Selected Idea
     |
     v
Shared Content Generator
     |
     v
Content Package
     |
     +-------------------+
     |                   |
     v                   v
Standard Reel       Trial Reel Test
     |                   |
     +---------+---------+
               |
               v
      Same Content History
               |
               v
        Performance Log
```

### Proposed Create Workflow

1. **Select idea** — from canonical library (or + New Idea without leaving)
2. **Choose output** — Story Reel, Standard Reel, Trial Reel preparation, other supported formats
3. **Configure** — duration, characters, language, tone
4. **Generate Content Package**

### What Differs Between Formats

| Property             | Standard Reel          | Trial Reel                          |
| -------------------- | ---------------------- | ----------------------------------- |
| Story generation     | Shared service         | Shared service                      |
| Narration generation | Shared service         | Shared service                      |
| Scene prompts        | Shared service         | Shared service                      |
| Caption              | Generated for content  | Generated for content               |
| Publishing intent    | Regular publication    | Test distribution                   |
| Experiment tracking  | Optional or recommended| Required for planned test           |
| Results tracking     | Performance record     | Performance record linked to test   |

> **Note**: A Trial Reel is not automatically a better-performing Reel. Instagram distribution depends on factors beyond content-generation code.

### Implementation Approach

1. Keep one core generation service.
2. Add a lightweight output or experiment configuration.
3. When content is published in different ways, record the relationship between experiments.

---

## 6. Fourth Major Change: Editable and Iterative Generation

### Problem

Current documentation describes a read-only preview of the generated `ContentPackageV2`.

### Recommended Generation Experience

#### Step 1: Choose an idea
Pick from the canonical library, or tap **+ New Idea**.

#### Step 2: Choose what to create
- Story Reel
- Standard Reel
- Trial Reel preparation
- Other supported formats

Only offer formats the application can actually produce.

#### Step 3: Set the creative direction
Defaults from brand profile:
- Audience: Parents of children aged 1–4
- Language: Hinglish
- Style: Soft pastel illustrations
- Tone: Warm, playful, relatable
- Characters: Selected for the story
- Duration: Supported presets

#### Step 4: Generate
The application generates the first version.

#### Step 5: Review and refine
Let the user edit individual sections:
- Hook
- Story beats
- Scene descriptions
- Narration
- On-screen text
- Ending
- Caption
- Hashtags
- CTA

#### Step 6: Regenerate selectively
If the hook is disliked, regenerate only the hook.

If the ending is weak, regenerate only the ending.

Do not force complete regeneration to fix one sentence. Preserve approved sections; show which fields changed.

#### Step 7: Approve and save
Save the approved version as a content package linked to the original idea.

---

## 7. Fifth Major Change: Connect Content, Publishing, and Performance

### Workflow

```
IDEA → IN PROGRESS → READY → CONTENT PACKAGE CREATED → REVIEWED → PUBLISHED ON INSTAGRAM → METRICS RECORDED → LEARNINGS CAPTURED
```

The app should not mark a Reel as published merely because its content package was generated.

Publishing status should be updated manually (unless an actual Instagram publishing integration is implemented and verified).

### Content Item Detail Page

When opening an idea, show:

#### Overview
- Original idea
- Parent problem
- Learning goal
- Characters
- Classification

#### Creative
- Storyboard
- Narration
- Scenes
- Caption
- Hashtags
- Visual prompts

#### History
- Generated versions
- Approved version
- Publication records
- Related experiments

#### Performance
- Reach
- Non-follower reach
- Plays
- Watch time
- Shares
- Saves
- Profile visits
- Attributed follows (if available)

#### Learning
- What performed better
- What needs testing again
- What to change next

---

## 8. Sixth Major Change: Improve the Insights Screen

### Problem

The user observes that standard Reel and Trial Reel generation appear similar, but the difference appears in Instagram views.

This should not be solved by making the generator more complicated.

### Recommended Insights Dashboard

#### A. Performance Overview
- Total content published (selected period)
- Reach
- Non-follower reach
- Median views or reach per comparable post
- Shares and saves
- Follows attributed to content

#### B. Performance by Format
Compare standard Reels, Trial Reels, and other formats **only when enough comparable data exists**.

#### C. Performance by Creative Approach
Track:
- Hook type
- Story type
- Character used
- Topic
- Duration
- CTA type
- Content pillar

The app should help investigate whether relatable routine stories perform differently from guessing games — but should not assume the answer before evidence exists.

#### D. Five-Test Tracker
The existing strategy requires testing a format at least five times before strong judgment.

Display:
> **Relatable Toddler Stories — 3 of 5 tests recorded**
> Next action: Create another story using the same format with a different scenario or hook.

#### E. Missing-Metrics Reminders
If a Reel was published but no metrics recorded, show a reminder.

Prevents misleading data in the Insights dashboard.

#### F. Recommendations
Once data is sufficient, suggest:
- Repeat a successful creative pattern
- Test a different hook
- Try a shorter version
- Revisit an idea with a different character
- Gather more data before concluding

These are suggestions, not guarantees of reach.

---

## 9. Seventh Major Change: Make the Idea Vault Useful

### Layout

```
[ Search ideas... ]            [ + Add Idea ]

Filters: All | New | In Progress | Needs Review | Ready | Archived

Additional: Pillar | Topic | Character | Format | Learning Goal | Status
```

### Example Idea Card

```
Rio Doesn't Want to Brush
Everyday routine · Story Reel

Characters: Rio, Mumma
Goal: Make a daily routine easier to approach
Status: Idea

[Open] [Edit] [Create] [More]
```

Cards should not display every internal classification field. Details belong on the full detail page.

### Add Idea — Two Levels

**Quick Add**
- Idea title or description
- Optional reference image
- Save

**Full Details**
- Parent problem
- Learning goal
- Characters
- Pillar
- Suggested format
- Hook
- Notes

The app can help fill in missing classifications later.

### Duplicate Warning

When an idea is saved, compare against the existing library.

If similar:
> We found a potentially similar idea.

Options:
- Open existing idea
- Save as a new variation
- Continue with the new idea

Never silently discard an idea just because it resembles an existing one.

---

## 10. Eighth Major Change: Simplify the Quality Gate

### Problem

The Quality Gate is useful but can feel like an obstacle.

### Proposed Design

Display three groups:

#### Ready
Content has passed required checks.

#### Needs Attention
Suggestions with fixes:
- A clearer hook
- More readable text
- A missing CTA
- A weak or unclear takeaway
- Possible duplication

#### Needs Your Decision
The app cannot determine something reliably and needs approval.

### Finding Format

Each finding shows:
- **What the problem is**
- **Why it matters**
- **A suggested fix**
- **Action buttons**

Example:
> **Hook is too general**
> Suggested improvement: Start with Rio's specific problem instead of a generic introduction.
> [Edit Hook] [Keep Anyway]

Manual overrides should be recorded but should not falsely indicate all checks passed.

---

## 11. Ninth Major Change: Build a Proper Brand Profile

### Content

#### Brand Identity
- Brand name and handle
- Tagline
- Audience
- Language preferences
- Brand tone

#### Characters
- Ria's description and reference images
- Rio's description and reference images
- Cuty's description and reference images
- Family characters (when needed)
- Character consistency rules

#### Visual Identity
- Colour palette
- Illustration style
- Typography preferences
- Watermark and footer
- Aspect ratios for different outputs

#### Content Rules
- Completed and retired themes
- Preferred content pillars
- Caption preferences
- Hashtag count
- Prohibited claims
- Age-appropriateness checks

#### Generation Preferences
- Default duration
- Default language
- Preferred voice
- Available generation tools
- API configuration

**One brand profile, reused everywhere.**

---

## 12. Additional Improvements

### A. Content Reuse System
Identify opportunities to transform existing concepts into genuinely different formats:

| Existing Concept     | Possible New Formats                          |
| -------------------- | --------------------------------------------- |
| Shapes-learning post | Guessing Reel, parent-child activity, story    |

New creative executions, not duplicated uploads.

### B. Asset Library
Store and organise:
- Character reference images
- Existing post artwork
- Approved backgrounds
- Voiceover files
- Music references or licensed audio
- Generated scenes
- Final video exports

Each asset linked to relevant idea or content package.

### C. Production Checklist
Before marking content ready:

| Production Item        | Status   |
| ---------------------- | -------- |
| Story approved         | Complete |
| Narration generated    | Complete |
| Scene images ready     | Complete |
| On-screen text checked | Complete |
| Video assembled        | Pending  |
| Final review           | Pending  |

Distinguish generating a storyboard from rendering a finished video.

### D. Reliable Backup and Export
Backup/export workflow for:
- Content ideas
- Content packages
- Brand settings
- Experiment records
- Performance data
- Character descriptions and asset references

---

## 13. Redesign Roadmap

Do not implement all features simultaneously. Use phased approach:

| Phase | Focus | Deliverable |
| ----- | ----- | ----------- |
| **1** | Audit current architecture | Map existing stores, models, navigation, generation paths |
| **2** | Establish canonical Content Library | Every new idea saved to one source of truth |
| **3** | Redesign navigation and Home | Simpler, task-oriented interface |
| **4** | Rebuild Idea Vault | Search, filters, quick add, edit, duplicate detection |
| **5** | Unify content generation | One shared pipeline with experiment metadata |
| **6** | Improve content editing | Editable packages and selective regeneration |
| **7** | Connect My Content and publishing | One detail page per idea/package with publication records |
| **8** | Rebuild Insights | Comparable metrics, experiment history, five-test tracking |
| **9** | Consolidate brand settings | One reusable brand and character profile |
| **10** | Reliability and release | Persistence tests, migrations, backups, error handling |

### Phase 1 is Essential

Before redesigning screens, establish how the existing app actually behaves.

Inspect:
- Main navigation
- Home/dashboard screen
- Idea Vault implementation
- `ContentLibrary` and `ContentAuditStore`
- `ContentIdea` and `ContentAuditItem` models
- `IdeaStatus` definitions
- `StoryReelBuilder`
- Standard Reel and Trial Reel flows
- `ContentPackageV2`
- Package and experiment persistence
- Existing tests

Produce a map of what exists, overlaps, and needs changing.

> **Do not delete existing models or stores before confirming their responsibilities and persisted data.**

---

## 14. Implementation Approach

### Step 1 — Architecture Audit
Inspect existing source files. Produce a map of what exists, what overlaps, and what needs changing.

### Step 2 — Write the Target Design
Define:
- Canonical data model
- Navigation structure
- Screen responsibilities
- Status transitions
- Idea-to-package relationships
- Publication and experiment relationships

### Step 3 — Fix Data Flow First
Ensure Add Idea, Edit Idea, archive, search, and generation all work against the same canonical library. Add regression tests before redesigning UI.

### Step 4 — Redesign Screens
Implement new navigation and Home, Idea Vault, and Create workflow. Keep existing functionality available during migration.

### Step 5 — Unify Reel Generation
Verify whether current standard and Trial Reel flows use the same generator. Reuse core logic; add experiment metadata separately.

### Step 6 — Integrate Performance Tracking
Link performance to actual content and publication records. Do not rely on titles alone to connect records.

### Step 7 — Verify the Entire Workflow
Test this scenario end to end:
1. Add a new idea
2. Find it in All Content
3. Edit it
4. Generate a content package
5. Refine the hook and narration
6. Save and reopen the package
7. Mark it as published after publishing on Instagram
8. Record its performance
9. See the record in Insights
10. Reopen the original idea without losing history

---

## 15. Key Decisions Before Coding

### Decision 1: One Source of Truth
The Idea Vault and All Content must share the same canonical content records.

### Decision 2: One Generation Engine
Standard Reel and Trial Reel creation should share the generation pipeline wherever their content requirements are the same. Experiment and publishing details tracked separately.

### Decision 3: One Connected Workflow
Every screen should help move an idea toward production, publication, or learning from results.

### Fundamental Principle

**Redesign the workflow first, the data model second, and the visual interface third.**

This avoids building a beautiful application that still loses track of ideas or separates related information.
