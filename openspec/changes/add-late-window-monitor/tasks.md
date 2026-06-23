## 1. Monitor Lifecycle

- [x] 1.1 Add `LateWindowMonitor` with 60-second lifecycle.
- [x] 1.2 Feed unrecovered learned states from restore reports.
- [x] 1.3 Stop monitoring when the period expires or the profile changes.

## 2. Late Restore Rules

- [x] 2.1 Reuse window matching for newly appearing windows.
- [x] 2.2 Detect manual movement before late restore.
- [x] 2.3 Record late restored and skipped windows in restore report.
- [x] 2.4 Add tests for within-window, expired, and manual-move cases.
