# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Communication Language

**IMPORTANT**: The user prefers to communicate in **Chinese (中文)**. Please use Chinese in all responses and interactions unless the user explicitly requests English.

## Project Overview

**Awareness App** (觉知系统) is a productivity and mindfulness application built with Flutter + Drift (SQLite), designed around the philosophy of "realism over perfection" and "protecting flow state." The app combines Pomodoro timer, thought capture, journaling, and OKR goal tracking.

**Key Architecture Principle**: Offline-first design with local SQLite database, designed for eventual cloud sync using UUID primary keys and sync tracking fields.

### Core Philosophy: Time ROI Analysis

Moving beyond simple time-tracking to "Time ROI" analysis based on OKR methodology:

- **Data Lineage:** Pomodoro (25m) → Task → Key Result (KR) → Objective (O)
- **Metric:** Not just "Duration", but "Effective Time" (`Duration * FocusScore`)
- **Schedule:** The active day window is fixed from **00:00 to 24:00** (24 hours)

**Architecture Rules:**
- **Strict Separation:** Pomodoros must be linked to a specific Objective via a Task. Unlinked time is "Junk Time"
- **Limit:** Objectives should be visualized by Color, avoiding text clutter on the main dashboard

## Build & Run Commands

### Frontend (Flutter App)

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
flutter pub get

# Run code generation (for Drift database)
flutter pub run build_runner build

# Run on Linux desktop
flutter run -d linux

# Run on Android
flutter run

# Build for Linux
../build_linux.sh

# Build Android APK
../build_apk.sh

# Clean build artifacts
flutter clean
```

### Database Management

```bash
# Set up mock database (copies awareness_v6.sqlite to app directory)
./setup_db.sh

# Import database manually
./import_db.sh

# Insert mock data
python3 insert_mock_data.py

# Verify data
python3 verify_data.py

# Clean bad data
python3 clean_bad_data.py
```

### Testing & Code Quality

```bash
cd frontend

# Run static analysis
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Run tests with verbose output
flutter test --reporter expanded
```

## High-Level Architecture

### Three-Layer Data Flow

The app follows a strict separation of concerns:

```
UI Layer (lib/ui/screens/)
    ↓
Logic Layer (lib/logic/)
    ↓
Data Layer (lib/data/)
    ↓
SQLite Database (Drift ORM)
```

### Global Singletons (main.dart)

Two critical global instances are initialized at app startup:
- `db`: AppDatabase instance (Drift)
- `focusSessionState`: FocusSessionState for managing active focus sessions

**Important**: These globals are used throughout the app. When working with database operations or focus sessions, always use the global `db` instance from `main.dart`.

### Database Schema (lib/data/database/tables.dart)

The app uses **Drift** (type-safe SQL for Dart) with the following domain model:

**OKR Domain**:
- `Objectives`: Top-level goals with calculated progress
- `KeyResults`: Measurable results with weighted progress tracking
- `KeyResultCheckIns`: Historical progress snapshots
- `Tasks`: Actionable items linked to KRs (or standalone)

**Awareness/Execution Domain**:
- `FocusSessions`: Pomodoro sessions with type ('work', 'short_break', 'long_break'), quality ratings, and review notes
- `Thoughts`: Quick captures during focus (types: 'distraction', 'idea', 'todo')

**System Domain**:
- `Tags` and `TaskTags`: Multi-dimensional categorization
- `AppSettings`: Key-value configuration (timer durations, etc.)

**All tables include sync tracking**: `createdAt`, `updatedAt`, `isSynced` for future cloud sync.

### Critical Database Methods (lib/data/database/database.dart)

**OKR Transaction Logic**:
- `addCheckIn()`: Atomic transaction that inserts check-in, updates KR current value, and recalculates Objective progress
- `_recalculateObjectiveProgress()`: Weighted progress calculation across all KRs
- `autoCompleteExpiredObjectives()`: Background job to transition expired active goals to completed

**Thought Management**:
- `getAllActiveThoughts()`: Unresolved thoughts ordered by creation time
- `getInboxThoughts()`: Todo-type thoughts (for the Sediment Tank)
- `insertThought()`: Add new thought
- `defuseThought()`: Mark thought as resolved

**App Settings**:
- `getTimerDurationSeconds()` / `setTimerDurationSeconds()`: Work session duration
- `getRestDurationSeconds()` / `setRestDurationSeconds()`: Short break duration
- `getLongRestDurationSeconds()` / `setLongRestDurationSeconds()`: Long break duration

## UI Structure

### Navigation (DashboardPage)

Bottom navigation with three branches:
1. **Focus Page** (FocusPage): Pomodoro timer with quick capture
2. **Journal Page** (JournalPage): Daily awareness container
3. **Goals Page** (OKRPage): OKR management

### Branch 2: JournalPage - "Daily Awareness Container"

Vertical three-layer structure representing temporal dimensions:

| Layer | Metaphor | Function | Interaction |
|-------|----------|----------|-------------|
| **Top** | Future/Intention (Launchpad) | Confirm today's main task | Click to expand, **Long press** to jump to FocusPage |
| **Middle** | Present/Reality (Mirror) | Review completed focus sessions | View timeline, batch rate sessions |
| **Bottom** | Past/Sediment | Process captured thoughts | Quick input, check to archive |

**Key Design**: The "long press" gesture on the Launchpad is the commitment action that transitions from intention to execution (jumping to Branch 1).

### Branch 1: FocusPage - Quick Capture Flow

**Purpose**: Minimize interruption during focus sessions by providing async thought offloading.

**Interaction**:
1. User clicks floating action button during timer
2. Minimal input overlay appears
3. User types → Enter
4. Overlay disappears immediately
5. Thought saved to database (no list shown, no timer interruption)

**Implementation**: See `QuickCaptureOverlay` component.

## Logic Layer

### FocusController (lib/logic/timer/focus_controller.dart)

State machine for Pomodoro cycles with extended states:

**States**:
- `idle`, `running`, `extending`: Work session states
- `restIdle`, `restRunning`, `restExtending`: Short break states
- `longRestIdle`, `longRestRunning`, `longRestExtending`: Long break states

**Key Properties**:
- `_currentSeconds`: Positive = remaining time, Negative = overtime
- `_targetSeconds`: Total duration for progress calculation
- Loads timer durations from database settings

**Cycle Logic**: Work → Short Break → Work → Short Break → Work → Short Break → Work → Long Break (repeat)

### FocusSessionState (lib/logic/focus_session_state.dart)

Manages the active focus session lifecycle:
- Tracks current session ID
- Links thoughts to sessions
- Handles session completion and review

## Code Generation

The project uses `build_runner` for Drift code generation. After modifying table definitions:

```bash
cd frontend
flutter pub run build_runner build --delete-conflicting-outputs

# For continuous watch mode during development
flutter pub run build_runner watch --delete-conflicting-outputs
```

Generated file: `lib/data/database/database.g.dart`

## Platform-Specific Notes

### Database Location

The app uses `path_provider` to store the database:
- **Linux**: `~/.local/share/com.example.awareness_app/awareness_v6.sqlite`
- **Android**: Application documents directory

The `setup_db.sh` script copies mock data to the Linux location. For Android, use `insert_to_existing_db.py` after first run.

### Build Scripts

Both `build_linux.sh` and `build_apk.sh` include:
- Environment validation
- Dependency installation
- Clean build
- Release mode compilation
- Output location information

## Design Philosophy Reminders

### "Realism Over Perfection"
The system records actual behavior (including distractions and interruptions) rather than forcing ideal states. Low-performance feedback still affirms honesty: "You faced reality."

### "Protect the Flow"
All interactions during focus sessions are designed for minimal disruption:
- Quick capture uses ephemeral overlays
- No lists or history shown during focus
- Timers continue uninterrupted
- Batch processing happens in review phase (Mirror)

## UI/UX Guidelines

**Aesthetic Direction:** "Refined Modern", avoiding generic "AI Slop" or default Material looks.

### Color Palette (Semantic)

- **Objective A (Creation/Flow):** Amber/Gold (`0xFFF6AD55`) - e.g., Writing, Coding
- **Objective B (Deep Work):** Deep Purple/Indigo (`0xFF9F7AEA`) - e.g., Reading Source Code
- **Objective C (Growth/Health):** Teal/Ocean Blue (`0xFF4FD1C5`) - e.g., Meditation, Exercise
- **Backgrounds:** Subtle off-white/grey (`0xFFEDEEF0`) with inner shadows for depth (neomorphic touch)

### Visual Rules (Negative Constraints)

- **NO** flat, solid high-saturation colors without texture or gradients
- **NO** system default fonts for key numbers. Use distinct typography
- **NO** clutter. Use "Color Coding" over text labels for high-level views
- **Motion:** Animations should be subtle and physics-based (e.g., damping), not linear

### Key Components Specs

#### 1. RefinedChronosDial (The Day View)

- **Type:** Radial/Circular Visualization
- **Range:** Maps 00:00 (Top/Start) to 24:00 (End). Total 24 hours
- **Visuals:**
  - A track with inner shadow (recessed look)
  - Colored arcs representing sessions, with gradients for gloss/texture
  - A "Now" cursor (glowing dot) indicating current time
- **Interaction:** Central text shows current time; labels are minimal

#### 2. DailyFocusTimeline (The Review View)

- **Type:** Horizontal Stacked Bar / Timeline
- **Logic:** Linear representation of the day
- **Gaps:** Empty space clearly indicates "Idle Time"
- **Interaction:** Tap color block to see details (Tooltip)

## Important Conventions

1. **UUID Primary Keys**: All entities use UUID v4 for offline-first sync compatibility
2. **Nullable Foreign Keys**: Tasks can exist without KRs, sessions without tasks (flexibility for ad-hoc work)
3. **Sync Fields Pattern**: Every mutable table has `updatedAt` and `isSynced` for eventual consistency
4. **Transaction Safety**: Use database transactions for multi-step operations (see `addCheckIn()` example)
5. **Chinese UI Text**: The app UI is in Chinese - maintain this for user-facing strings

## Flutter Code Quality Guidelines

### Null Safety & Immutability
- Never use the bang operator (`!`) unless 100% certain the value is not null. Prefer `?` and `??`
- Prefer immutable state. Use `final` for variables that do not change
- Use `async`/`await` instead of `.then()` callback chains

### Performance Optimization
- **Always use `const` constructors** for widgets where possible - crucial for Flutter's rebuild optimization:
  - Bad: `Padding(padding: EdgeInsets.all(8.0), ...)`
  - Good: `Padding(padding: const EdgeInsets.all(8.0), ...)`
- **Widget Splitting**: Break complex UI into smaller StatelessWidgets, NOT helper functions (helper functions don't optimize redraws correctly)

### Type Safety
- Explicitly type return values and arguments
- Avoid `dynamic` unless absolutely necessary

### Color API (Flutter 3.22+)
- **禁用** `withOpacity()` → **使用** `withValues(alpha: 0.5)`

## Database Schema Version

Current version: **6** (defined in `database.dart`)

Major schema changes require version increments and migration logic. The current migration strategy recreates all tables on version changes (development mode).
