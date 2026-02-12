    鼠鬚管
    爲物雖微情不淺
    新詩醉墨時一揮
    別後寄我無辭遠

    　　　——歐陽修

今由　[中州韻輸入法引擎／Rime Input Method Engine](https://rime.im)
及其他開源技術強力驅動

【鼠鬚管 - YourMemory 版】
===
[![GitHub Repo](https://img.shields.io/badge/GitHub-YourMemory--Squirrel-blue?logo=github)](https://github.com/fisher-byte/squirrel-memory)

这是 [Rime Squirrel（鼠鬚管）](https://github.com/rime/squirrel) 的一个特殊修改版本，旨在实现**完全本地、安全**的输入记录功能。

核心特性
---

1.  **键入即存**：在输入法上屏（Commit）时，自动将转换后的文本记录到本地。
2.  **粘贴即存**：实时监听剪贴板，将粘贴内容自动持久化到本地。
3.  **指定即存**：通过快捷键 `Cmd + Shift + S` 快速捕获当前选中的文本（支持 Accessibility API 或剪贴板回退）。
4.  **100% 本地化**：所有数据均存储在本地，不经过任何网络上传，保护你的输入隐私。

数据存储
---

记录文件保存在 Rime 用户文件夹下的 `input_log/records.jsonl` 中。
你可以通过输入法菜单中的 **"YourMemory Records..."** 快速打开该文件夹。

项目文档
---

详细的设计文档和开发计划请参考 `docs/` 目录：
- [产品需求文档 (PRD)](docs/PRD-InputMethod-MVP.md)
- [开发计划 (DEV PLAN)](docs/DEV-PLAN-InputMethod-Mac.md)

贡献与安装
---

如果你想基于此版本进行开发或安装，请参考 [Rime Squirrel](https://github.com/rime/squirrel) 的原始构建指南，或者直接下载我们的 [Release 版本](https://github.com/fisher-byte/squirrel-memory/releases)。


式恕堂 版權所無

授權條款：[GPL v3](https://www.gnu.org/licenses/gpl-3.0.en.html)

項目主頁：[rime.im](https://rime.im)

您可能還需要 Rime 用於其他操作系統的發行版：

  * 【中州韻】（ibus-rime、fcitx-rime）用於 Linux
  * 【小狼毫】用於 Windows

安裝輸入法
---

本品適用於 macOS 13.0+

初次安裝，如果在部份應用程序中打不出字，請註銷並重新登錄。

使用輸入法
---

選取輸入法指示器菜單裏的【ㄓ】字樣圖標，開始用鼠鬚管寫字。
通過快捷鍵 `` Ctrl+` `` 或 `F4` 呼出方案選單、切換輸入方式。

定製輸入法
---

定製方法，請參考線上 [幫助文檔](https://rime.im/docs/)。

使用系統輸入法菜單：

  * 選中「在線文檔」可打開以上網址
  * 編輯用戶設定後，選擇「重新部署」以令修改生效

安裝輸入方案
---

使用 [/plum/](https://github.com/rime/plum) 配置管理器獲取更多輸入方案。

致謝
---

輸入方案設計：

  * 【朙月拼音】系列

    感謝 CC-CEDICT、Android 拼音、新酷音、opencc 等開源項目

程序設計：

  * 佛振
  * Linghua Zhang
  * Chongyu Zhu
  * 雪齋
  * faberii
  * Chun-wei Kuo
  * Junlu Cheng
  * Jak Wings
  * xiehuc

美術：

  * 圖標設計 佛振、梁海、雨過之後
  * 配色方案 Aben、Chongyu Zhu、skoj、Superoutman、佛振、梁海

本品引用了以下開源軟件：

  * Boost C++ Libraries  (Boost Software License)
  * capnproto (MIT License)
  * darts-clone  (New BSD License)
  * google-glog  (New BSD License)
  * Google Test  (New BSD License)
  * LevelDB  (New BSD License)
  * librime  (New BSD License)
  * OpenCC / 開放中文轉換  (Apache License 2.0)
  * plum / 東風破 (GNU Lesser General Public License 3.0)
  * Sparkle  (MIT License)
  * UTF8-CPP  (Boost Software License)
  * yaml-cpp  (MIT License)

感謝王公子捐贈開發用機。

問題與反饋
---

發現程序有 BUG，或建議，或感想，請反饋到 [Rime 代碼之家討論區](https://github.com/rime/home/discussions)

聯繫方式
---

技術交流，歡迎光臨 [Rime 代碼之家](https://github.com/rime/home)，
或致信 Rime 開發者 <rimeime@gmail.com>。

謝謝
