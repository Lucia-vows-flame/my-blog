# Blog (GitHub Pages + Typst PDF/HTML)

这个仓库包含一个**纯静态**的 GitHub Pages 博客骨架，核心能力：

- 文章已是 HTML（由 Typst 编译生成）也能直接接入
- 文章也可以直接用 PDF（Typst 编译为单文件，最省心）
- 自动按分类统计数量，并提供分类页（按年份分组）
- 文章页保留侧边栏分类导航（通过 `iframe` 加载文章内容：HTML 或 PDF）

## 使用方式

1) 把站点放在 `docs/`（GitHub Pages 可直接从该目录发布）

2) 把文章内容准备好（推荐走自动化，见下面“发布文章”）

- HTML：`docs/articles/<slug>/index.html`
- PDF：`docs/articles/<slug>/doc.pdf`

3) 为每篇文章创建元数据：

- `docs/articles/<slug>/meta.json`（示例见 `docs/articles/hello-world/meta.json`）

## Typst 输出建议：使用 PDF（推荐）

如果你更希望“写作体验简单 + 版式稳定 + 多页自然”，PDF 是最省心的：Typst 直接编译出单个 `doc.pdf`，部署也简单。

在本仓库中：博客页会通过 `iframe` 加载 `meta.json` 里的 `path`，它可以指向 `.html` 或 `.pdf`。

如果你仍想用 HTML（更好的站内链接/锚点/SEO）：Typst 的 HTML 导出需要显式开启实验特性：
`typst compile --features html --format html ...`

4) 生成站点索引（分类/列表用）：

```bash
python3 scripts/build_posts_index.py
```

## 发布文章（推荐：自动化）

你可以把源文件/原始 PDF 放在 `incoming/`，再用脚本一键生成可发布的 `docs/**`。

### 1) 上传 Typst 或 PDF

- Typst 源文件：放到 `incoming/typst/`（可包含子目录）
- PDF 文件：放到 `incoming/pdfs/`

### 2) 填写清单 `incoming/manifest.csv`

清单是一行一篇文章，字段含义：

- `typ_file`: 可选，Typst 源文件路径（相对 `incoming/typst/`）
- `pdf_file`: 可选，PDF 文件路径（相对 `incoming/pdfs/`）
- `slug`: 必填，全站唯一（目录名 + 文章 id）
- `title`: 必填
- `date`: 必填（`YYYY-MM-DD`）
- `categories`: 必填（英文逗号分隔；支持多级分类，用 `/` 分隔层级，例如 `Computer Science/DSA/CS61B2025`）
- `excerpt`: 可选

> `typ_file` 与 `pdf_file` 二选一即可；若同时填写，默认优先用 `typ_file` 编译。
> 多级分类说明：在单个分类里用 `/` 分隔层级后，侧边栏会自动生成树状分类；点击任意层级会展示该层级及其子层级下的文章。

### 3) 一键生成并更新索引

```bash
python3 scripts/publish_posts.py
```

它会：

- （可选）`.typ` → `docs/articles/<slug>/doc.pdf`
- 写入 `docs/articles/<slug>/meta.json`
- 更新 `docs/data/posts.json`

### Typst 附件（图片等）放哪里？

强制规定：**所有 Typst 附件（图片等）必须放在 `incoming/typst/**/images/**` 下**（支持多级目录），并在 Typst 中用相对路径引用。

- 示例结构（一级分类）：`incoming/typst/Tools Tutorial/Tmux使用教程.typ`
- 图片放在：`incoming/typst/Tools Tutorial/images/tmux/tmux-cover.png`
- Typst 引用：`#image("images/tmux/tmux-cover.png")`

示例结构（多级分类）：`incoming/typst/Computer Science/DSA/CS61B2025/notes/lec01.typ`

- 图片放在：`incoming/typst/Computer Science/DSA/CS61B2025/images/fig1.png`
- Typst 引用：`#image("../images/fig1.png")`

脚本会自动把 Typst 的 `--root` 设为 `incoming/typst/`（当你的源文件位于该目录下）。

> 若用 GitHub Actions 自动编译 Typst：附件文件也需要一并提交到仓库，否则 CI 找不到图片就会编译失败。若不想提交附件，可以改为本地编译出 PDF 后只提交 `docs/**`。

## 元数据格式

每篇文章一个 `meta.json`，最少需要这些字段：

- `id`: 全站唯一（用于 `post.html#id=...`）
- `title`: 文章标题
- `date`: `YYYY-MM-DD`
- `categories`: 字符串数组（如 `["开发者手册"]`，可多分类；支持多级分类，用 `/` 分隔层级）
- `path`: 站点根目录下的相对路径（如 `articles/xxx/index.html`）

5) 本地预览（不要用 `file://` 直接打开，否则 `fetch` 会失败）：

```bash
python3 -m http.server 8000 --directory docs
```

然后访问 `http://localhost:8000/`。

## GitHub Pages 发布

### 发布步骤（项目站点，`/docs`）

1) 把仓库 push 到 GitHub 的默认分支（通常是 `main` 或 `master`），并确保 `docs/index.html` 存在

2) GitHub 仓库 → Settings → Pages

3) Build and deployment 里选择：

- Source: **Deploy from a branch**
- Branch: `main`（或你的默认分支）
- Folder: `/docs`
- Save

4) 等 1–5 分钟，在 Settings → Pages 会显示访问地址：`https://<username>.github.io/<repo>/`

5) 后续更新：只要默认分支有新提交，Pages 会自动重新部署

> 如果你启用了本文的 GitHub Actions 工作流并让它回推 `docs/**`，那么最终触发 Pages 的仍然是默认分支上的新提交。

> 已包含 `docs/.nojekyll`，避免 Jekyll 干预静态资源路径。

## GitHub Actions 设置（自动生成 `docs/` 可选）

本仓库包含工作流：`.github/workflows/publish-posts.yml`，它会在你 push `incoming/**` 或 `scripts/**` 后自动生成/更新 `docs/**`，并把变更 commit & push 回仓库。

需要在 GitHub 仓库 Settings 做这些设置：

1) Settings → Actions → General → **Workflow permissions**

- 选择 **Read and write permissions**，并点击页面底部 **Save**
  - 常见小坑：只改选项但忘记点 Save，设置不会生效，工作流会因为权限不足而失败

2) 如果默认分支（如 `main`）开启了 Branch protection（Settings → Branches）

- 需要允许 GitHub Actions（`github-actions[bot]`）能把生成的提交 push 回默认分支；否则工作流会在最后一步 push 失败
- 不想让 Actions 直接 push：可以在 GitHub Actions 手动触发工作流并把 `commit_and_push` 设为 `false`，改为本地运行 `python3 scripts/publish_posts.py` 后再自行提交
