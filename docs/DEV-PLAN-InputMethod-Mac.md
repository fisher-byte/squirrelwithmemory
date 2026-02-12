# 开发计划：本地输入记录器（Mac 验证 · 基于 Rime/Squirrel 改造）

**基于文档**：[PRD-InputMethod-MVP.md](./PRD-InputMethod-MVP.md)  
**目标**：在 macOS 上先验证三功能，改造 Rime 体系（鼠须管 Squirrel）；实现顺序为**功能1 → 功能2 → 功能3**（可接受仅先完成功能1即做首轮验证）。

---

## 一、范围与优先级

| 阶段 | 功能 | 说明 | 验收标准（AC） |
|------|------|------|----------------|
| **P0** | **功能1：键入即存** | 改造 Squirrel，在每次 Rime 提交上屏时把 `commit.text` 写入本地 | 使用鼠须管输入并上屏后，本地存储中能看到对应文本；不改变原有输入与上屏行为 |
| **P1** | **功能2：粘贴即存** | 剪贴板内容变化时，将新内容追加写入本地存储 | 任意应用内执行粘贴后，本地存储中有一条对应记录；粘贴到目标应用的行为不变 |
| **P2** | **功能3：指定即存** | 全局快捷键（如 Cmd+Shift+S）将当前选中或剪贴板内容保存到本地 | 选中文本后按快捷键，内容写入本地并可选 Toast 确认；不抢焦点 |

**首轮验证**：完成 P0（功能1）后即可在 Mac 上做一次端到端验证（安装自建 Squirrel、输入、检查本地文件）。

---

## 二、环境与仓库准备

### 2.1 需要下载的 GitHub 项目

| 序号 | 仓库 | 用途 | 克隆方式 |
|------|------|------|----------|
| 1 | [rime/squirrel](https://github.com/rime/squirrel) | macOS 输入法前端（改造主仓库） | `git clone --recursive https://github.com/rime/squirrel.git` |
| 2 | [rime/librime](https://github.com/rime/librime) | 输入法引擎（squirrel 子模块，一般 clone --recursive 已包含） | 已在 squirrel 的 `librime` 子模块中 |
| 3 | [rime/plum](https://github.com/rime/plum) | 东风破配置管理（squirrel 子模块，可选） | 已在 squirrel 的 `plum` 子模块中 |

**建议**：只克隆 **squirrel** 并带子模块即可；librime 会在 squirrel 的 `librime/` 目录下。

### 2.2 本机环境要求（Mac）

- **系统**：macOS 13.0+（与 Squirrel 要求一致）
- **Xcode**：14.0 及以上（App Store 安装）
- **CMake**：`brew install cmake`
- **Boost**：二选一  
  - 使用官方脚本（通用二进制）：`export BUILD_UNIVERSAL=1` 后执行 `bash librime/install-boost.sh`，并设置 `BOOST_ROOT`  
  - 或 `brew install boost`（简单，但构建出的 app 依赖本机 Homebrew，不便分发）

### 2.3 克隆与初次构建（建议在项目外单独目录做改造）

```bash
# 1. 克隆（建议 fork 后克隆自己的 fork，便于提交与回滚）
git clone --recursive https://github.com/rime/squirrel.git
cd squirrel

# 2. 若子模块未拉全
git submodule update --init --recursive

# 3. 可选：使用官方脚本安装预编译 librime，跳过自编 Boost/librime（加快首次构建）
bash ./action-install.sh

# 4. 若未用 action-install.sh，需自建 Boost 并设置 BOOST_ROOT，例如：
# export BUILD_UNIVERSAL=1
# bash librime/install-boost.sh
# export BOOST_ROOT="$(pwd)/librime/deps/boost-1.84.0"

# 5. 构建 Squirrel.app（按需加 ARCHS / BUILD_UNIVERSAL）
make

# 6. 产物位置（示例）：squirrel/build/Squirrel.app 或 bin 目录（以实际 Makefile 输出为准）
```

构建成功后，可先按官方文档安装到本机并切到鼠须管输入法，确认未改代码前行为正常，再开始改代码。

---

## 三、阶段一：功能1（键入即存）

### 3.1 目标

在 Rime “提交上屏”时，把本次提交的文本（`commit.text`）追加写入本地存储，且不改变任何原有输入与上屏逻辑。

### 3.2 技术要点（来自 PRD 附录 B）

- **librime API**：`get_commit(session_id, RimeCommit* commit)`，`commit.text` 即本次上屏内容；用后需 `free_commit`。
- **改造点**：在 Squirrel 中“每次取到 commit 并交给系统上屏”的那段逻辑之后，增加一步：若 `commit.text` 非空，则追加写入本地文件或 SQLite。

### 3.3 实现步骤

| 步骤 | 任务 | 说明 |
|------|------|------|
| 1 | 在 squirrel 源码中定位“上屏/commit”逻辑 | 在仓库内搜索 `get_commit`、`RimeCommit`、`commit`（注意排除不相关命名）。重点文件：`sources/SquirrelInputController.swift`、`sources/SquirrelView.swift`、与 C 桥接的 `sources/BridgingFunctions.swift` 或通过 Bridging Header 调用的 C API 封装。 |
| 2 | 确定写入时机与线程 | 在“已取得 commit 且 text 非空、且已交给系统上屏”之后同步或异步写入；避免阻塞 UI/输入线程，可异步写文件。 |
| 3 | 定义本地存储格式与路径 | **路径**：如 `~/Library/Application Support/Rime/input_log/` 或项目自定义目录（需在文档中写明）。**格式**：首版可用纯文本按行追加（每行一条 commit + 时间戳）或 JSONL；后续可改为 SQLite。 |
| 4 | 实现写入模块 | 新增 Swift 模块/类：接收字符串，追加写入到上述路径；注意文件句柄或 NSFileHandle 的线程安全与错误处理。 |
| 5 | 在 commit 处理处挂接 | 在步骤 1 定位到的分支中，调用该写入模块，传入 `String(cString: commit.text)`（或等价方式），并保证 `free_commit` 仍被调用。 |
| 6 | 验收 | 部署自建 Squirrel，切换为鼠须管，在任意应用输入并上屏若干次；检查本地文件中是否按条出现对应内容，且输入法行为与未改前一致。 |

### 3.4 交付物

- 代码：在 Squirrel 仓库内、最少改动的“提交即存”补丁（含新增写入逻辑与一处挂接）。
- 文档：在项目 `docs/` 中说明存储路径、格式、如何关闭（若做开关）。

### 3.5 风险与回退

- **风险**：误改上屏逻辑导致输入异常。  
- **缓解**：只增不改原有上屏代码；仅在上屏成功后追加写盘。  
- **回退**：保留原 Squirrel 的 git 分支，改造在单独分支进行，可随时切回原版构建。

---

## 四、阶段二：功能2（粘贴即存）

### 4.1 目标

系统剪贴板内容发生变化时（例如用户执行了粘贴或复制），将当前剪贴板文本内容追加写入本地存储，且不改变粘贴到目标应用的结果。

### 4.2 技术要点

- **监听对象**：`NSPasteboard.general` 的变更（或轮询 changeCount）；在 macOS 上无“仅粘贴”的官方事件，通常用“剪贴板变化”近似“有一次粘贴/复制行为”。
- **实现位置**：可在 Squirrel 内作为常驻能力（输入法进程本身常驻），在 `SquirrelApplicationDelegate` 或单独模块中注册剪贴板监听；或后续拆成独立小应用（本计划优先在 Squirrel 内实现以简化部署）。

### 4.3 实现步骤

| 步骤 | 任务 | 说明 |
|------|------|------|
| 1 | 注册剪贴板监听 | 使用 `NSPasteboard.general`，在应用启动/激活时添加 `NSPasteboard.didChangeNotification` 或定时轮询 `changeCount`，避免重复处理同一次变更。 |
| 2 | 取剪贴板字符串 | 若 `NSPasteboard.general.string(forType: .string)` 有值，则视为一条新内容。 |
| 3 | 写入本地存储 | 与功能1共用同一存储格式与路径，或单独表/文件区分“来源：键入 / 粘贴”；首版可统一格式并加字段 `source: "paste"`。 |
| 4 | 去重与节流 | 同一段文本在短时间内的重复复制只记一条（可选）；写盘做简单节流，避免高频写入。 |
| 5 | 验收 | 在任意应用内复制/粘贴几次，检查本地存储中是否有对应记录，且粘贴到应用内的内容与未安装时一致。 |

### 4.4 交付物

- 代码：剪贴板监听 + 写入本地存储（与功能1共用写入模块与路径配置）。
- 文档：说明“粘贴即存”依赖剪贴板变化，与功能1的存储关系。

---

## 五、阶段三：功能3（指定即存）

### 5.1 目标

用户通过全局快捷键（如 Cmd+Shift+S）或菜单栏入口，将“当前选中内容”或“当前剪贴板内容”保存到本地，并可选简短 Toast 确认；不抢夺焦点、不阻塞输入。

### 5.2 技术要点

- **全局快捷键**：macOS 上需在应用内注册全局热键（如 `addGlobalMonitorForEvents` 或第三方库），并申请辅助功能权限（若需要）。
- **获取选中内容**：  
  - **简化版**：快捷键触发时先模拟 Cmd+C，再读剪贴板，将剪贴板内容写入本地（用户需已选中文本）。  
  - **完整版**：通过可访问性 API（AX）获取当前焦点应用的选中文本，再写入本地。  
- **不抢焦点**：触发后不激活 Squirrel 窗口、不弹模态框；仅可选 Toast 或状态栏提示。

### 5.3 实现步骤

| 步骤 | 任务 | 说明 |
|------|------|------|
| 1 | 注册全局快捷键 | 在 Squirrel 启动时注册 Cmd+Shift+S（或可配置）；确保输入法在后台也能收到。 |
| 2 | 实现“保存当前内容”逻辑 | 简化版：发送 Cmd+C，短暂延迟后读 `NSPasteboard.general.string`，非空则写入本地并带来源 `source: "designate"`。 |
| 3 | 可选 Toast/反馈 | 写入成功后触发一次轻量提示（如状态栏菜单项闪烁或系统通知），不弹窗。 |
| 4 | 权限与文档 | 若使用 AX 取选中，需在文档中说明需开启辅助功能权限；简化版“先复制再保存”仅需剪贴板访问。 |
| 5 | 验收 | 在浏览器/编辑器中选中一段文字，按 Cmd+Shift+S，检查本地是否多一条记录，且当前应用焦点与输入未被打断。 |

### 5.4 交付物

- 代码：全局快捷键 + 读剪贴板/选中 + 写入本地 + 可选反馈。
- 文档：快捷键说明、可选“指定即存”的权限说明。

---

## 六、存储与权限统一约定

### 6.1 本地存储

- **根目录**：`~/Library/Application Support/Rime/` 下新建子目录，例如 `input_log/`，或项目自定义名（如 `YourMemory/`），在 PRD/代码中统一。
- **格式**：首版建议 **JSONL**（每行一个 JSON），便于扩展与排查，例如：  
  `{"ts": 1707123456, "source": "commit|paste|designate", "text": "..."}`  
  或纯文本 + 时间戳行（更简单）。
- **策略**：仅追加、不上传；可选单文件大小/条数上限与轮转（后续迭代）。

### 6.2 权限

- **输入法**：系统输入法权限（安装 Squirrel 时已涉及）。
- **剪贴板**：无额外权限声明，使用系统 API 读剪贴板。
- **全局快捷键**：若用事件监听，可能需辅助功能权限，在文档中写明。
- **网络**：不申请、不访问，满足 PRD“完全本地”。

---

## 七、项目进行方式与检查点

### 7.1 推荐仓库与分支策略

- **主开发仓库**：建议 fork [rime/squirrel](https://github.com/rime/squirrel) 到个人/团队账号，例如 `your-org/squirrel`。
- **分支**：  
  - `main` 或 `master`：与上游同步或作为发布基线。  
  - `feature/input-log-commit`：功能1。  
  - `feature/input-log-paste`：功能2。  
  - `feature/input-log-designate`：功能3。  
  每阶段合并到主分支后再进入下一阶段。

### 7.2 检查点（与 PRD 验收对应）

| 检查点 | 阶段 | 验收内容 |
|--------|------|----------|
| CP1 | P0 功能1 | 自建 Squirrel 能构建、安装；使用鼠须管输入并上屏后，指定目录下出现对应记录；输入体验无变化。 |
| CP2 | P1 功能2 | 复制/粘贴后，本地存储中有新记录；粘贴到应用的内容正确。 |
| CP3 | P2 功能3 | Cmd+Shift+S 后当前选中或剪贴板内容被写入本地；无焦点抢夺。 |
| CP4 | 整体 | 不申请网络权限、不上传数据；存储路径与格式在文档中写明。 |

### 7.3 建议时间线（参考）

| 阶段 | 内容 | 建议天数 |
|------|------|----------|
| 环境与构建 | 克隆、依赖、首次 make、能安装并正常输入 | 0.5～1 |
| P0 功能1 | 定位 commit、实现写入、挂接、自测 | 2～3 |
| P1 功能2 | 剪贴板监听、写入、去重/节流、自测 | 1～2 |
| P2 功能3 | 全局快捷键、读选中/剪贴板、写入、反馈、自测 | 1～2 |
| 联调与文档 | 存储格式统一、权限说明、README 更新 | 0.5～1 |

**合计约 5～9 个工作日**，可按“先完成功能1即做首轮验证”压缩到约 3～4 天。

---

## 八、需求追溯（与 PRD 对应）

| PRD 条目 | 本计划对应 |
|----------|------------|
| 功能1 键入即存（Epic 3 / Story 3.1 方案 B） | 阶段一：Squirrel 改造，get_commit → 写本地 |
| 功能2 粘贴即存（Epic 1 / Story 1.1） | 阶段二：剪贴板监听 → 写本地 |
| 功能3 指定即存（Epic 2 / Story 2.1、2.2） | 阶段三：全局快捷键 + 选中/剪贴板 → 写本地 |
| 完全本地、无上传 | 存储与权限统一约定；不申请网络 |
| 正常打字、不抢焦点 | 仅追加写盘、不改上屏逻辑；功能3 不弹窗不激活窗口 |

---

## 九、后续可选（不做入本期）

- 存储加密、条数/大小上限与轮转。
- 设置界面：存储路径、开关（键入/粘贴/指定 分别开关）。
- Windows（小狼毫 Weasel）的同类改造。
- 独立“记录查看/导出”小工具。

---

*本开发计划依据 PRD-InputMethod-MVP.md 与 product-manager / 开发实践 skills 拆解，用于在 Mac 上基于 Rime/Squirrel 实现功能1、2、3 并完成首轮验证。*
