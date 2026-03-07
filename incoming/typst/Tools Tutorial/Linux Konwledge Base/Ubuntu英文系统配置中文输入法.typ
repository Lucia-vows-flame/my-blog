#import "@preview/arkheion:0.1.1": arkheion, arkheion-appendices
#import "@preview/mitex:0.2.6": *
#show: arkheion.with(
  title: "Ubuntu英文系统配置中文输入法",
  authors: (
    (name: "Geoffrey Xu", email: "13149131068@163.com", affiliation: "Xidian University", orcid: "0009-0006-1640-1812"),
  ),
  // Insert your abstract after the colon, wrapped in brackets.
  // Example: `abstract: [This is my abstract...]`
  abstract: lorem(55),
  keywords: ("First keyword", "Second keyword", "etc."),
  date: "March 7, 2026",
)

#set par(spacing: 1.5em)

#set text(
  font: ("Merriweather", "Noto Serif CJK SC"),
  size: 12pt,
  lang: "zh",
) //设置正文字体, Merriweather 是英文使用的字体, Noto Serif CJK SC 是中文使用的字体.

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

在英文系统的 Ubuntu 中使用中文输入法有许多方法，如果你去网上搜索，会发现很多教程，比如使用 ibus，或者使用 fcitx。我们在这里讲三种方法，一种是使用 ibus，另一种是使用雾凇拼音，最后一种是直接使用语言包。

= Ubuntu系统的ibus

Linux中安装输入法首先需要安装输入法框架，常用的输入法框架有 ibus 和 fcitx，本文就 ibus (Intelligent Input Bus) 框架进行介绍。

+ 打开终端，输入以下命令安装 ibus 框架：

  ```bash
  sudo apt install ibus
  ```

+ 安装完毕后，输入以下命令切换为 ibus 框架：

  ```bash
  sudo im-config -s ibus
  ```

+ 由于 Ubuntu 使用的是 Gnome 桌面环境，所以需要安装相应的平台支持包，输入以下命令安装：

  ```bash
  sudo apt install ibus-gtk ibus-gtk3
  ```

+ 选择简体输入法，在终端输入：

  ```bash
  sudo apt install ibus-pinyin
  # sudo apt install ibus-libpinyin
  ```

+ 完成安装后，先重启系统，然后在系统设置中找到 `Keyboard` 选项，然后在 `Input Sources` 中选择中文输入法，如下图所示：

  #image("images/PixPin_2025-12-23_19-34-31.png")

= 雾凇拼音

使用雾凇拼音的前提是Rime输入法框架，Rime输入法框架是一个开源的输入法引擎，它可以让用户自定义输入法。

Rime的官方网站是：#link("https://rime.im/")[Rime官网]。在“下载”页面可以找到各个平台的安装方法。

+ 安装 Rime 输入法框架，这里我们要安装的是 ibus-rime，安装命令如下：

  ```bash
  sudo apt install ibus-rime
  ```

+ 雾凇拼音的安装方法参考：#link("https://github.com/iDvel/rime-ice")[雾凇拼音Github仓库]

= 使用语言包

使用语言包非常简单，只需要下载安装对应的语言包，然后在 `Keyboard` 中的 `Input Sources` 中选择即可。

+ 安装中文语言包

  ```bash
  sudo apt update
  sudo apt install language-pack-zh-hans
  ```

+ 在 `Keyboard` 中的 `Input Sources` 中选择中文输入法。

+ 完成安装后，重启系统。

注意，使用语言包可能会需要 ibus，如果没有 ibus，需要先安装。安装命令如下：

```bash
sudo apt update
sudo apt install ibus ibus-libpinyin
```

= Ubuntu系统的VSCode无法使用中文输入法

出现这种现象是因为使用了 Ubuntu 自带的 snap 软件商店下载安装的 VSCode，并不是微软的官方版本。

解决方法：卸载掉 snap 软件商店里的 VSCode，然后在微软官方下载 VSCode 的 `.deb` 包，然后进行安装。

安装方法有两种：

1. 使用命令行安装：

  ```bash
  sudo dpkg -i 安装包.deb
  ```

2. 图形化安装：

  双击安装包进行图形化安装。
