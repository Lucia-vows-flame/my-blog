#import "@preview/arkheion:0.1.1": arkheion, arkheion-appendices
#import "@preview/mitex:0.2.6": *
#show: arkheion.with(
  title: "Git 常见问题整理",
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

= Git 设置

我们的所有配置都会体现在 `gitconfig` 文件中。

```bash
# 帮助文档
git help <verb>
git <verb> --help
man git-<verb>
git help config

# 检查你的配置
git config --list

# 配置 username 和 email
git config --global user.name "John Doe"
git config --global user.email johndoe@example.com

# 配置Git使用的编辑器
$ git config --global core.editor neovim
```

= 使用 SSH 密钥进行 GitHub 推送

+ 生成 SSH key

  ```bash
  ssh-keygen -t ed25519 -C "your_email@example.com"
  ```

  这里的 `-t` 表示要生成的密钥类型，这里生成的类型为 `ed25519`，是一种椭圆曲线算法，比传统的 RSA 更加安全、密钥更短，并且速度更快。

+ 将 SSH key 添加到 GitHub 中

  ```bash
  cat ~/.ssh/id_ed25519.pub
  ```

  将输出的内容复制到 GitHub $->$ Settings $->$ SSH and GPG keys $->$ New SSH key，自己起一个 Title 密钥类型，选择默认的 `Authentication key` 即可，然后点击“Add SSH key”即可。

+ 修改远程仓库为 SSH 地址

  在本地仓库中输入
  ```bash
  git remote set-url origin git@github.com:username/reponame.git
  # 注意，此前我们已经建立好来远程存储库，这里是修改远程存储库为 SSH
  # 我们的工作流程是先在 GitHub 新建仓库，然后把仓库 clone 到本地，此时会自动添加远程存储库，然后我们需要按照本小节将 http 修改为 ssh
  ```

  将上面的 `username` 和 `reponame` 分别替换为你的用户名和仓库名称。

+ 测试连接

  ```bash
  ssh -T git@github.com
  ```

  如果显示：

  ```bash
  Hi username! You've successfully authenticated, but GitHub does not provide shell access.
  ```

  那么就说明 SSH 的配置正确，可以进行正常的 git 操作了，这里的 `username` 显示为你的 GitHub 用户名。

+ 推送

  ```bash
  git push origin main
  # git push -u origin main
  ```

  这时就会发现推送成功，不需要再输入密码或者 token 了。

  注意，这里的 `-u` 是 `--set-upstream`，将本地的 `main` 分支与远程仓库的 `origin/master` 关联起来，以后只需要写 `git push` 或者 `git pull` 即可。

= Git 使用流程

+ 在 GitHub 上创建项目
+ 使用 `git clone` 把项目克隆到本地
+ 编辑项目
+ 使用 `git add` 把更改添加到暂存区，可以添加某个文件，也可以添加整个目录
+ 使用 `git commit -m` 将暂存区的更改提交
+ 使用 `git push origin main` 将本地更改推送到远程 `main` 分支
  - 如果你在 GitHub 上修改了项目，或者你在别的地方修改了项目并推送到了远程仓库，又或者别人修改了项目并推送到远程仓库，那么此时你的远程仓库和本地仓库不匹配，会报错，如下图所示，此时需要先使用 `git pull origin main`，然后再 `git push origin main`。
  #image("images/PixPin_2025-12-24_20-29-36.png")

= 出现错误 `error:src refspec master does not match any`

原因分析：引起该错误的原因是目录中没有文件，空目录是不能提交上去的。

解决办法：添加新文件提交即可，例如添加一个 `README.md`。

```bash
touch README.md

git add README.md
# git add ./README.md
git commit -m "first commit"
git push origin main
```

= 输入 ` git remote add origin git@github.com:github账户名/项目名.git` 报错 `fatal: remote origin already exists.`

解决方法：

```bash
1.先输入 git remote rm origin
    2.再输入 git remote add origin git@github.com:github账户名/项目名.git 就不会报错了！
    3.如果输入 git remote rm origin 还是报错的话，error: Could not remove config section'remote.origin'. 我们需要修改gitconfig文件的内容
4.找到你的github的安装路径
5.找到一个名为gitconfig的文件，打开它把里面的[remote "origin"]那一行删掉就好了！
```

= 使用 `git push origin main` 报错 `error:failed to push som refs to ......`

这就是我们前面所说的，如果你在 GitHub 上修改了项目，或者你在别的地方修改了项目并推送到了远程仓库，又或者别人修改了项目并推送到远程仓库，那么此时你的远程仓库和本地仓库不匹配，会报错，此时需要：

```bash
git pull origin main # 先把远程服务器github上面的文件拉下来
git push origin main
# 如果出现报错: fatal:Couldn't find remote ref master 或者 fatal: 'origin' does not appear to be a git repository 以及 fatal: Could not read from remote repository, 则需要重新输入 git remote add origingit@github.com:github账户名/项目名.git
```

= `fatal: unable to connect to eagain.net`

使用 `git clone` 命令从 `eagain.net` 克隆 `gitosis.git` 源码出错，解决方法如下：

```bash
git clone git://github.com/res0nat0r/gitosis.git
```

