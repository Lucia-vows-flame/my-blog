#import "@preview/arkheion:0.1.1": arkheion, arkheion-appendices
#import "@preview/mitex:0.2.6": *
#show: arkheion.with(
  title: "Linux环境变量配置指南",
  authors: (
    (name: "Geoffrey Xu", email: "13149131068@163.com", affiliation: "Xidian University", orcid: "0009-0006-1640-1812"),
  ),
  // Insert your abstract after the colon, wrapped in brackets.
  // Example: `abstract: [This is my abstract...]`
  //abstract: lorem(55),
  //keywords: ("First keyword", "Second keyword", "etc."),
  date: "October 3, 2025",
)

#set par(spacing: 1.5em)

#set text(
  font: ("Times New Roman", "Noto Serif SC"),
  size: 12pt,
  lang: "zh",
) //设置正文字体, Times New Roman 是英文使用的字体, Noto Serif SC 是中文使用的字体.

#show heading: set text(font: "New Computer Modern", weight: "bold") //设置标题字体,bold表示粗体

#set heading(numbering: "1.") //设置标题编号格式

#outline(depth: 4) //设置目录深度

// 注释掉 arkheion 模版中的这部分代码
#show heading: it => {
  // H1 and H2
  if it.level == 1 {
    pad(
      bottom: 10pt,
      it,
    )
  } else if it.level == 2 {
    pad(
      bottom: 8pt,
      it,
    )
  } else if it.level >= 3 {
    pad(
      bottom: 6pt,
      it,
    )
  } else {
    it
  }
}

#let titled-block(title: [], body, ..kwargs) = {
  stack(
    dir: ttb,
    spacing: 5pt,
    text(
      size: .9em,
      fill: rgb("#3140e4"),
      sym.triangle.small.stroked.r + sym.space + title,
    ),
    block(
      inset: 10pt,
      width: 100%,
      stroke: 2pt + rgb("#3140e4").lighten(50%),
      ..kwargs.named(),
      body,
    ),
  )
}

#show raw.where(block: true): it => block(
  fill: luma(245),
  inset: 10pt,
  radius: 4pt,
  width: 100%,
  stroke: (left: 3pt + rgb("#3498db")),
  it,
)

#show raw.where(block: false): box.with(
  fill: luma(240),
  inset: (x: 3pt, y: 0pt),
  outset: (y: 3pt),
  radius: 2pt,
)

在 Linux 系统管理与开发环境中，环境变量扮演着至关重要的角色，其中最为核心的便是 `PATH` 变量。本章将详细阐述环境变量的工作原理、配置语法的底层逻辑、优先级规则以及持久化设置的最佳实践，帮助用户避免常见的配置陷阱。

= 核心概念：PATH 的“通讯录”机制

Linux 系统在接收到用户输入的命令（如 `ls`、`python` 或 `conda`）时，并不会自动扫描整个硬盘。相反，它依赖于一个名为 `PATH` 的环境变量。可以将 `PATH` 想象成系统的“通讯录”，其中记录了一系列目录路径。当用户输入命令时，系统会按照这份通讯录中记录的目录顺序，依次查找是否存在对应的执行程序。

如果一个程序的安装路径没有被记录在 `PATH` 中，系统将无法直接识别该命令，用户必须输入完整的绝对路径才能运行它。因此，配置环境变量的本质，就是将新安装软件的路径（如 `/home/user/miniconda3/bin`）登记到这份通讯录中。

= 基础语法与追加逻辑

配置环境变量的核心命令是 `export`。然而，在修改 `PATH` 变量时，必须遵循“追加”而非“覆盖”的原则。Linux 使用冒号（`:`）作为路径之间的分隔符，而美元符号（`$`）用于引用变量当前的值。

一个正确的配置指令应当包含新路径、分隔符以及原有的变量值。例如，指令 `export PATH=/new/path:$PATH` 的含义是将 `/new/path` 与系统原有的 `$PATH` 内容拼接起来，并重新赋值给 `PATH` 变量。

新手最容易犯的致命错误是忽略了 `$PATH`，直接执行 `export PATH=/new/path`。这种操作相当于撕毁了旧的通讯录，只保留了新的一行记录。其后果是灾难性的：系统将丢失对 `ls`、`cp`、`vi` 等基础命令的索引，导致除新程序外，整个终端几乎瘫痪。因此，保留 `$PATH` 是维护系统正常运转的底线。

= 优先级原则：前置与后置的选择

系统在解析 `PATH` 变量时，严格遵循“从左至右”的搜索顺序，且一旦找到匹配的程序便立即停止搜索。这一机制决定了新路径在变量中的位置（在左侧还是右侧）将直接影响命令的执行优先级。

当需要使用新安装的软件替换系统自带版本时，应采用“前置写法”。例如，安装 Miniconda 后，用户希望输入 `python` 时调用的是 Conda 环境中的 Python 3.9，而非系统自带的 Python 2.7。此时应将新路径置于 `$PATH` 的左侧，写作 `export PATH=/miniconda/bin:$PATH`。这样系统会优先在新路径中检索，实现版本的“覆盖”。

反之，如果仅仅是为了添加一个补充工具，且不希望干扰系统原有命令，则可采用“后置写法”，即 `export PATH=$PATH:/new/path`。但在大多数开发环境配置（如 Java JDK、Node.js、Anaconda）中，前置写法是更为通用的选择，以确保用户能够使用最新安装的工具版本。

= 配置的持久化：配置文件

直接在终端执行的 `export` 命令仅在当前窗口临时生效，一旦关闭终端，配置即刻丢失。为了实现配置的永久生效，必须将命令写入 Shell 的配置文件中。

对于绝大多数 Linux 用户（Bash Shell），该配置文件位于用户主目录下的 `.bashrc` 文件（即 `~/.bashrc`）；而对于 Zsh 用户，则对应 `~/.zshrc` 文件。配置过程通常涉及使用文本编辑器（如 nano 或 vim）打开该文件，并将 `export` 语句追加至文件的末尾。

文件修改完成后，变更并不会立即反映在当前终端中。用户需要执行 `source ~/.bashrc` 命令来重新加载配置文件，或者重启终端窗口，方能使新的环境变量生效。

= 引用规范与防坑指南

在编写配置语句时，处理空格与引号的方式体现了配置的健壮性。虽然在路径不包含空格的情况下，不加引号的写法也能被系统识别，但为了防止路径中潜在的空格导致参数解析错误，最佳实践是始终使用双引号包裹整个赋值内容。

推荐的标准写法为：`export PATH="/my/path:$PATH"`。双引号允许 Shell 解析其中的变量（即 `$PATH` 会被展开为实际路径），同时保护路径中的空格不被误读为分隔符。

必须严厉禁止使用单引号，如 `export PATH='/my/path:$PATH'`。单引号具有“所见即所得”的特性，它会阻止变量的展开，导致系统将 `$PATH` 视为普通的文本字符串。这不仅会导致配置失败，还会因路径失效而破坏系统的命令索引功能。因此，坚持使用双引号是保障配置安全的关键细节。
