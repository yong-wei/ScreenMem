# Repository Guidelines

## 协作基线

- 全程中文。先查仓库事实、开发计划、OpenSpec、脚本和验证结果，再给结论或修改。
- Shell 命令默认加 `rtk` 前缀；运行 Python 脚本使用 `python3`。
- 大型文档分批修改；一次性写入文档长度不要超过 500 行。
- 本仓库当前是 macOS App 新项目，功能规划真源是 `docs/macOS App 开发计划：Profile-aware Window State Restorer.md`。

## OpenSpec 工作流

- 本项目使用 OpenSpec 管理功能开发。开始实现前，先检查 `openspec/specs/` 与 `openspec/changes/`，避免与已归档能力或进行中变更冲突。
- 当任务已由 OpenSpec 接管时，以对应 change 的 `proposal.md`、`design.md`、`tasks.md` 和 spec delta 为计划真源。
- 新能力应拆成可独立执行、可独立验证的 change；不要把显示器识别、窗口访问、学习、恢复、UI 与硬化塞进一个大变更。
- 提案和归档默认使用 `openspec validate --changes --strict` 或 `openspec validate <change> --type change --strict` 验证。

## 项目边界

- MVP 是 Swift + SwiftUI + AppKit 的 macOS 菜单栏 App。
- App 只延续已存在普通窗口的位置和尺寸；不启动 App、不创建窗口、不恢复 Chrome 标签、不管理真正全屏窗口、不跨 Space 移动窗口、不做云同步。
- 自动学习只允许发生在用户主动创建过、且当前显示器集合精确匹配的 Profile 下。
- 显示器变化、稳定检测、恢复和保护期内禁止写入 Profile。

## 本地工具

- OpenWolf 用于本地上下文管理。若存在 `.wolf/OPENWOLF.md`，每次会话先阅读并遵守；生成代码前检查 `.wolf/cerebrum.md`，读取文件前优先看 `.wolf/anatomy.md`。
- `codegraph` 用于代码索引、符号定位、调用关系和影响面查询。
- `code-review-graph` 用于 review、执行流、测试缺口和跨文件风险分析。
- 本仓库使用 `.githooks/` 维护本地提交 hook；应执行 `git config core.hooksPath .githooks` 启用。

## 常用验证

- OpenWolf：`rtk openwolf status`、`rtk openwolf scan --check`。
- Codegraph：`rtk codegraph status .`。
- CRG：`rtk code-review-graph status --repo .`。
- OpenSpec：`rtk openspec validate --changes --strict`。
- 后续 Swift 项目落地后，应补充 `script/build_and_run.sh` 和测试命令。

