# Clip Prompts (Stage 2: On-demand generation)

**Status:** Implemented. This document describes the shipped code.

This file documents **how to generate** clip prompts, not the prompts themselves.
The actual prompts are generated on demand based on the Stage 1 base ideas in
`content_ideas.md`.

## Two-Stage Workflow

**Stage 1** (stored in `content_ideas.md`): Base ideas with beats, no timing.
A base idea describes the Setup, Problem, Escalation, Turn, Payoff, and an
optional Stretch Beat. It never has a fixed length.

**Stage 2** (generated on demand): You pick an idea + a length. The app
produces N self-contained 10-second prompts, one per Part. Each Part is a
standalone prompt with style, size, characters, camera, timed action, audio,
avoid rules, and a continuity line.

## Stage 2 Prompt Template

Every Part uses this exact format. Paste straight into Gemini.

```
Create a 10-second vertical 9:16 animated video clip.

STYLE: Soft 3D Pixar/Disney-style render, warm natural lighting, bright cozy colours.
Not flat 2D, not chibi, not watercolour.
SIZE: Vertical 9:16 (1080x1920). Keep characters centred, leave the bottom
20% clear for Instagram's overlay buttons.
CHARACTER LOCK: Use the attached reference images for exact face/hair/outfit matching.
Ria, Rio, Cuty

RULES:
- Ria and Rio NEVER wear glasses.
- Only the characters listed above may appear. No background characters,
  bystanders, extras or mascots.
- Outfits may change per scene but hair/eyes/face stay consistent.

SETTING: [described in Stage 1 base idea]
CAMERA: Fixed medium shot at child eye level. Keep characters centred, bottom 20% clear.

ACTION:
0-4s: [BEAT for this Part — 4 seconds]
4-8s: [BEAT for this Part — 4 seconds]
8-10s: [BEAT for this Part — 2 seconds]

AUDIO: Hinglish narration describing the action above, plus matching natural
sound effects. No background music.

AVOID: Distorted hands, changing outfits between clips, on-screen text, logos,
and any visual inconsistency with the reference images.
CONTINUITY: (Part 2+ only) The first frame must match the previous clip exactly —
same room, same lighting, same character positions and same outfits. Do not
restart the story; continue from where the previous clip ended.
```

**For every prompt:** attach your character reference images. For Part 2 and
beyond, also attach the previous Part's last frame so Gemini matches the pose,
position, and lighting exactly.

## Length → Parts Mapping

| Length | Parts | Beat distribution |
| --- | --- | --- |
| 20s | 2 | Part 1: Setup + Problem + Escalation. Part 2: Turn + Payoff |
| 30s | 3 | Part 1: Setup + Problem. Part 2: Escalation + Stretch Beat. Part 3: Turn + Payoff |
| 40s | 4 | Same as 30s, with a second escalation or longer reaction beat |
| 60s | 6 | The 30s structure spread across six parts. Adjacent parts share a beat at the cut point, so the turn and payoff each span two clips. |

## Ready Base Ideas (from content_ideas.md)

The 7 reels below are stored in Stage 1 format. Say the reel name and length
(e.g. "Jugaad Fail, Box Win, 30 seconds") and the app generates the Part prompts.

| ID | Reel | Best length |
| --- | --- | --- |
| R1 | Ria Ne Papa Ko Bulaya | 20s or 30s |
| R2 | Mujhe Nahi Aata | 20s or 30s |
| R3 | Kaunsa Dhakkan Fit Hoga | 20s (tight) |
| R4 | Jugaad Fail, Box Win | 30s (needs stretch beat) |
| R5 | Mumma Ne Kaha Haath Mat Lagana | 20s (tight) |
| R6 | Toddler Customer Care | 30s (needs stretch beat) |
| R7 | 2 Minute Ka Bath | 20s or 30s |

## Honest Notes

- **Not every idea stretches well.** R3 (lid challenge) and R5 (don't touch)
  are tight jokes. At 30s they risk dragging — keep them at 20s.
- **Longer chains drift more.** Each extra part is another chance for a face
  or outfit to change. For a 30s reel, check each Part's last frame before
  generating the next, and regenerate any Part that looks off.
- **The bath scene has a safety line.** Ria stays covered in bubbles and water,
  shoulders and above only. Keep that wording in every prompt, even if you edit
  the rest.