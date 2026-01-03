## Project: Awareness System (觉知系统)
**Core Philosophy:** Moving beyond simple time-tracking to "Time ROI" analysis based on OKR methodology.
- **Data Lineage:** Pomodoro (25m) -> Task -> Key Result (KR) -> Objective (O).
- **Metric:** Not just "Duration", but "Effective Time" (`Duration * FocusScore`).
- **Schedule:** The active day window is fixed from **00:00 to 24:00** (24 hours).

**Architecture Rules:**
- **Strict Separation:** Pomodoros must be linked to a specific Objective via a Task. Unlinked time is "Junk Time".
- **Limit:** Objectives should be visualized by Color, avoiding text clutter on the main dashboard.

## UI/UX Guidelines
**Aesthetic Direction:** "Refined Modern", avoiding generic "AI Slop" or default Material looks.

**Color Palette (Semantic):**
- **Objective A (Creation/Flow):** Amber/Gold (`0xFFF6AD55`) - e.g., Writing, Coding.
- **Objective B (Deep Work):** Deep Purple/Indigo (`0xFF9F7AEA`) - e.g., Reading Source Code.
- **Objective C (Growth/Health):** Teal/Ocean Blue (`0xFF4FD1C5`) - e.g., Meditation, Exercise.
- **Backgrounds:** Subtle off-white/grey (`0xFFEDEEF0`) with inner shadows for depth (neomorphic touch).

**Visual Rules (Negative Constraints):**
- **NO** flat, solid high-saturation colors without texture or gradients.
- **NO** system default fonts for key numbers. Use distinct typography.
- **NO** clutter. Use "Color Coding" over text labels for high-level views.
- **Motion:** Animations should be subtle and physics-based (e.g., damping), not linear.

## Key Components Specs

### 1. RefinedChronosDial (The Day View)
- **Type:** Radial/Circular Visualization.
- **Range:** Maps 05:00 (Top/Start) to 23:00 (End). Total 18 hours.
- **Visuals:** - A track with inner shadow (recessed look).
  - Colored arcs representing sessions, with gradients for gloss/texture.
  - A "Now" cursor (glowing dot) indicating current time.
- **Interaction:** Central text shows current time; labels are minimal.

### 2. DailyFocusTimeline (The Review View)
- **Type:** Horizontal Stacked Bar / Timeline.
- **Logic:** Linear representation of the day.
- **Gaps:** Empty space clearly indicates "Idle Time".
- **Interaction:** Tap color block to see details (Tooltip).