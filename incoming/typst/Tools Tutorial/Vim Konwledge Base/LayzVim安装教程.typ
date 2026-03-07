#import "@preview/arkheion:0.1.1": arkheion, arkheion-appendices
#import "@preview/mitex:0.2.6": *
#show: arkheion.with(
  title: "LayzVim安装教程",
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

= Neovim 安装

首先，我们需要知道，在 Ubuntu 中，`sudo apt install` 无法安装最新版的 Neovim。

`sudo apt install` 这个命令从Ubuntu的官方APT仓库中安装软件包。然而，这种方法在安装某些软件时，尤其是像Neovim这样快速迭代的软件时，可能无法获取到最新版本。这主要有以下几个原因：

+ 软件包更新策略

  Ubuntu的软件仓库遵循稳定性和兼容性优先的策略。这意味着，仓库中的软件包通常在Ubuntu版本发布时被锁定，并且在该版本的生命周期内只接受安全更新和关键修复。这种策略有助于确保系统的稳定性，但也意味着最新的软件版本可能不会立即出现在APT仓库中。

+ 审核和打包过程

  新版本的软件包需要经过打包、测试和审核过程才能被包含进Ubuntu的APT仓库。这个过程可能会耗费一定的时间，尤其是对于那些更新频繁的软件来说。因此，即使软件的新版本已经发布，用户也可能需要等待一段时间才能通过APT安装。

+ 发布周期

  Ubuntu的发行版通常每六个月发布一次，而某些软件，如Neovim，可能在这期间发布了多个新版本。如果你使用的是Ubuntu的LTS（长期支持）版本，这种情况更为明显，因为LTS版本更注重稳定性而不是最新性。

那么，如何在Ubuntu中安装最新版的Neovim呢？我们下面进行介绍。

首先，需要卸载旧版本的Neovim：

```bash
sudo apt remove neovim
```

然后，我们安装最新版本的 Neovim：

```bash
# 由于APT仓库中的Neovim版本可能不是最新的，我们建议通过下载官方GitHub仓库中的压缩包来进行安装。以下步骤将指导你完成安装最新版本Neovim的过程：

# 1. 访问Neovim的GitHub仓库，找到最新版本的发布页面

# 2. 选择适合你系统的最新版本压缩包的下载链接，例如，对于64位Linux系统，我们可以使用如下命令下载最新版本的Neovim v0.9.5：
wget https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-linux64.tar.gz
# 也可以使用 curl 命令下载：
curl -LO https://github.com/neovim/neovim/releases/download/v0.9.5/nvim-linux64.tar.gz

# 3. 下载完成后，我们将压缩包解压到指定目录，我们建议解压到 ~/opt 目录下，没有就创建一个，但这要求你将该目录添加到你的PATH环境变量中，或者你也可以创建一个符号链接到 /usr/bin 目录或其他已在PATH环境变量中的目录下：
tar -zxvf nvim-linux64.tar.gz -C ~/opt

# 4. 创建符号链接
cd /usr/bin
sudo ln -s ~/opt/nvim-linux64/bin/nvim nvim # 使用 sudo 才能修改 /usr/bin 目录
# 这里的含义是，在 /usr/bin 目录下创建一个名为 nvim 的符号链接，指向 ~/opt/nvim-linux64/bin/nvim 目录。

# 5. 清理压缩包文件
rm -rf nvim-linux64.tar.gz
```

注意，你也可以把软件安装在根目录的 `/opt` 目录下，根目录本身就有 `/opt` 目录，但是不推荐，因为这样所有的用户都可以访问到你的软件，这可能会造成安全问题。并且我尝试了在根目录的 `/opt` 目录下安装Neovim，发现添加环境变量后还是启动不了。

= LazyVim 安装

LazyVim 的安装建立参考官方的安装教程。

官网安装要求：#link("https://www.lazyvim.org/")[安装要求]
官网安装教程：#link("https://www.lazyvim.org/installation")[安装教程]

== 前期准备

首先我们要安装 Nerd Fonts，我们去 Nerd Fonts 官网上下载一些 fonts 包，下载完成后，解压 `.zip` 安装包到 `~/.local/share/fonts` 目录下，然后使用 `fc-cache -fv` 命令刷新字体。

== 安装 LazyVim

参考官网的安装教程进行安装，然后安装自己的配置问价进行配置即可。
