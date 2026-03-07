#import "@preview/arkheion:0.1.1": arkheion, arkheion-appendices
#import "@preview/mitex:0.2.6": *
#show: arkheion.with(
  title: "Codex下载与使用",
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

= 安装 Node.js 和 nvm

使用 `curl` 下载安装 nvm：
```bash
# install nvm in WSL
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
# 使配置文件立即生效
source ~/.bashrc
```

安装 Node.js：
```bash
# 安装 Node.js 22 版本
nvm install 22
# 使用 Node.js 22 版本
nvm use 22
```

检查安装是否成功：
```bash
node -v
npm -v
```

= 安装 Codex CLI

```bash
# 安装 Codex CLI
npm install -g @openai/codex

# 启动 Codex CLI
codex
```

API的配置参考各家 API Provider 提供的教程。

#text(fill: red)[此外，Codex 的相关配置阅读 Codex 的官方文档。]
