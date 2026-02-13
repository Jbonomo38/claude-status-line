# Changelog

All notable changes to Claude Status Line will be documented in this file.

## [2.0.0] - 2026-02-12

### Added
- **Conversation-level token tracking** - Automatically resets when running `/clear`
- **Automatic checkpoint system** - Requests checkpoints at 85% usage
- **Smart warnings** - Progressive alerts at 60%, 80%, 85%, 90%, 95%
- **Checkpoint status indicators** - Shows "Safe to /clear" after checkpoints
- **State persistence** - Tracks baselines across status line invocations
- **Checkpoint executor** - Manual and automatic checkpoint creation
- **Daemon control** - Optional background daemon for monitoring
- Setup script for easy installation

### Changed
- Token tracking now conversation-scoped instead of session-scoped
- Warning thresholds updated to 60/80/85/90/95%
- Status messages include checkpoint information
- Enhanced color coding with checkpoint context

### Features
- ✅ Detects `/clear` and resets counters automatically
- ⚠️ Visual warnings at configurable thresholds
- 💾 Automatic checkpoint requests at high usage
- 🟢 "Safe to /clear" indicators after checkpoints
- 📊 Conversation-level metrics

## [1.0.0] - 2026-02-10

### Added
- Initial release
- Real-time context window tracking
- Color-coded usage warnings (green/yellow/red)
- Detailed token metrics (input, output, cache)
- Model name display with smart abbreviations
- Number formatting (k/M suffixes)
- Pure bash implementation (no dependencies)

### Features
- Session-wide token tracking
- Current turn token breakdown
- Cache read token display
- Support for Claude 4.5/4.6 models
- Percentage-based usage display
