# ScreenMem MVP Manual QA Matrix

Run this matrix before treating the MVP as release-ready. Record the date, hardware, macOS version, and Accessibility permission state with each run.

## Matrix

| Case | Setup | Expected Result | Current Run |
| --- | --- | --- | --- |
| MacBook-only | Built-in display only, Accessibility granted | Exact profile can be created, learned, restored, and reported | Not run in this change |
| Dual external displays | MacBook plus two external displays | Exact profile restores known ordinary windows to the learned displays | Blocked: no dual external hardware verified in this session |
| Sidecar without profile | Known profile plus temporary Sidecar display | Partial restore uses known displays and does not learn | Blocked: no Sidecar device verified in this session |
| Sidecar with profile | User-created Sidecar profile | Exact Sidecar profile can learn and restore | Blocked: no Sidecar device verified in this session |
| Closed windows | Learned app window is closed before restore | App is not launched and missing window is reported/skipped | Not run in this change |
| Chrome multi-window | Multiple Chrome windows open | App-local ordinals distinguish windows | Not run in this change |
| Minimized windows | Learned window is minimized during inventory | Minimized/unsupported state is not restored unsafely and is reported | Not run in this change |
| Fullscreen windows | A true fullscreen window exists | Fullscreen-like window is skipped and reported | Not run in this change |

## Automated Coverage

`rtk swift run ScreenMemShellChecks` covers pure logic for display matching, coordinate transforms, profile store writes, window matching, restoration guards, partial fallback, late windows, pause state, report rows, and menu status.

`rtk bash script/build_and_run.sh --smoke-test` verifies the local app target builds and the app smoke path exits successfully.
