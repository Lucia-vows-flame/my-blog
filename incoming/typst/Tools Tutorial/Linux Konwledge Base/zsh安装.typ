#import "@preview/arkheion:0.1.1": arkheion, arkheion-appendices
#import "@preview/mitex:0.2.6": *
#show: arkheion.with(
  title: "zsh 安装",
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

#image("images/202401171435767.png")

传统的 `bash` 功能比较简陋，且不美观。本文基于 Ubuntu22.04 LTS 系统，安装`zsh`，并使用oh-my-zsh 对终端进行美化。Oh My Zsh 是基于 `zsh` 命令行的一个扩展工具集，提供了丰富的扩展功能。

= 环境配置

== 安装基本工具

安装基本工具

```bash
# 更新软件源
sudo apt update && sudo apt upgrade -y
# 安装zsh git curl
sudo apt install zsh git curl -y
```

设置默认终端为`zsh`（注意：不要使用`sudo`）。

```bash
chsh -s /bin/zsh
```

== 安装oh-my-zsh

官网：#link("http://ohmyz.sh/"). 安装方式任选一个即可。

/ curl: `sh -c "$(curl -fsSL https://install.ohmyz.sh/)"`
/ wget: `sh -c "$(wget -O- https://install.ohmyz.sh/)"`
/ fetch: `sh -c "$(fetch -o - https://install.ohmyz.sh/)"`
/ 国内curl镜像: `sh -c "$(curl -fsSL https://gitee.com/pocmon/ohmyzsh/raw/master/tools/install.sh)"`
/ 国内wget镜像: `sh -c "$(wget -O- https://gitee.com/pocmon/ohmyzsh/raw/master/tools/install.sh)"`

注意，网站的证书好像过期了，导致 `curl` 方法无法安装，建议使用 `wget`、`fetch` 或国内 `curl` 镜像等方法安装。

此外，这里使用 `curl, wget, fetch` 下载的是 `shell` 脚本，而 `shell` 脚本是需要执行的，因此前面的 `sh -c` 是必不可少的。

注意：同意使用 Oh-my-zsh 的配置模板覆盖已有的 `.zshrc` 。

#image("images/202401012224221.png")

== 从 `.bashrc` 中迁移配置（可选）

如果之前在使用 `bash` 时自定义了一些环境变量、别名等，那么在切换到 `zsh` 后，你需要手动迁移这些自定义配置。

```bash
# 查看bash配置文件，并手动复制自定义配置
cat ~/.bashrc
# 编辑zsh配置文件，并粘贴自定义配置
nvim ~/.zshrc
# 启动新的zsh配置
source ~/.zshrc
```

注意，这里不要把 `~/.bashrc` 的内容全部复制到 `~/.zshrc` ，这里有两个原因：

+ `~/.zshrc` 里有一些配置是 `oh-my-zsh` 自己生成的，如果直接复制过来会导致冲突。
+ `~/.bashrc` 里有一些配置是仅适用于 `bash` 的，如果直接复制过来会导致报错。例如：

  ```bash
  /home/sephiroth/.zshrc:17: command not found: shopt
  /home/sephiroth/.zshrc:25: command not found: shopt
  /home/sephiroth/.zshrc:112: command not found: shopt
  /usr/share/bash-completion/bash_completion:45: command not found: shopt
  /usr/share/bash-completion/bash_completion:53: command not found: complete
  /usr/share/bash-completion/bash_completion:56: command not found: complete
  /usr/share/bash-completion/bash_completion:59: command not found: complete
  /usr/share/bash-completion/bash_completion:62: command not found: complete
  /usr/share/bash-completion/bash_completion:65: command not found: complete
  /usr/share/bash-completion/bash_completion:68: command not found: complete
  /usr/share/bash-completion/bash_completion:71: command not found: complete
  /usr/share/bash-completion/bash_completion:74: command not found: complete
  /usr/share/bash-completion/bash_completion:77: command not found: complete
  /usr/share/bash-completion/bash_completion:80: command not found: complete
  /usr/share/bash-completion/bash_completion:1590: parse error near `|'
  ```

因此，我们使用 `cat` 命令查看 `~/.bashrc` 的内容，手动复制需要的配置，然后粘贴到 `~/.zshrc` 文件中。

`root` 用户在执行 `sudo su` 命令后，再运行上述代码查看、手动复制、粘贴自定义配置。

= 配置主题

== 自定义主题

使用博主自用的主题：

```bash
sudo wget -O $ZSH_CUSTOM/themes/haoomz.zsh-theme https://cdn.haoyep.com/gh/leegical/Blog_img/zsh/haoomz.zsh-theme
```

编辑 `~/.zshrc` 文件，将 `ZSH_THEME` 设为 `haoomz` 。当然你也可以设置为其他主题，例如 `lukerandall`、`robbyrussell`。

```bash
nvim ~/.zshrc
ZSH_THEME="haoomz"
source ~/.zshrc
```

#image("images/202401012235958.png")

效果如下：

#image("images/202401012238625.png")

== 推荐主题

你可以在#link("https://github.com/ohmyzsh/ohmyzsh/wiki/Themes")[内置主题样式截图]中查看所有 `zsh` 内置的主题样式和对应的主题名。这些内置主题已经放在 `~/.oh-my-zsh/themes` 目录下，不需要再下载。

```bash
cd ~/.oh-my-zsh/themes && ls
```

#image("images/202401012242407.png")

=== powerlevel10k

根据 "#link("https://github.com/ohmyzsh/ohmyzsh/issues/9248")[What's the best theme for Oh My Zsh?]" 中的排名，以及自定义化、美观程度，强烈建议使用 powerlevel10k 主题。

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
# 中国用户可以使用gitee.com 上的官方镜像加速下载
git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

在 `~/.zshrc` 设置 `ZSH_THEME="powerlevel10k/powerlevel10k"` 。接下来，终端会自动引导你配置 powerlevel10k 。

= 安装插件

oh-my-zsh 已经内置了 `git` 插件，内置插件可以在 `~/.oh-my-zsh/plugins` 中查看，下面介绍一下我常用的插件，更多插件可以在 #link("https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins")[awesome-zsh-plugins] 里查看。

== 插件推荐

=== zsh-autosuggestions

#link("https://github.com/zsh-users/zsh-autosuggestions")[zsh-autosuggestions] 是一个命令提示插件，当你输入命令时，会自动推测你可能需要输入的命令，按下右键 `→` 可以快速采用建议。效果如下：

#image("images/202401012250028.png")

安装方式：把插件下载到本地的 `~/.oh-my-zsh/custom/plugins` 目录。

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# 中国用户可以使用下面任意一个加速下载
# 加速1
git clone https://github.moeyy.xyz/https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# 加速2
git clone https://gh.xmly.dev/https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# 加速3
git clone https://gh.api.99988866.xyz/https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

=== zsh-syntax-highlighting

#link("https://github.com/zsh-users/zsh-syntax-highlighting")[zsh-syntax-highlighting] 是一个命令语法校验插件，在输入命令的过程中，若指令不合法，指令显示为红色，若指令合法，显示为绿色。

安装方式：把插件下载到本地的 `~/.oh-my-zsh/custom/plugins` 目录。

```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 中国用户可以使用下面任意一个加速下载
# 加速1
git clone https://github.moeyy.xyz/https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# 加速2
git clone https://gh.xmly.dev/https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
# 加速3
git clone https://gh.api.99988866.xyz/https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

=== z

oh-my-zsh 内置插件，不需要下载。

`z` 是一个文件夹快捷跳转插件，对于曾经跳转过的目录，只需要输入 `z 文件夹名` 即可快速跳转，而不需要输入完整的长串路径，提高切换文件夹的效率。效果如下：

#image("images/202401012254065.png")

=== extract

oh-my-zsh 内置插件，不需要下载。

`extract` 是一个功能强大的解压插件，不必根据压缩文件的后缀名来记忆压缩软件，所有类型的文件解压一个命令 `x` 全搞定，再也不需要记 `tar` `zip` 等各种命令了。效果如下：

#image("images/202401012259966.png")

=== web-search

oh-my-zsh 内置插件，不需要下载。

`web-search` 是一个命令行搜索插件，可以在命令行使用 `google` 、 `baidu` 、 `bing` 等命令让我们在命令行中使用浏览器进行搜索。效果如下：

#image("images/202401012302476.png")

== 启用插件

最最重要的就是：启用所有插件。

修改 `~/.zshrc` 文件，找到 `plugins=(git)` 这一行，修改为：

```bash
plugins=(git zsh-autosuggestions zsh-syntax-highlighting z extract web-search)
```

#image("images/202401012304774.png")

#titled-block(title: [Tips])[
  部分插件需要参考插件介绍进行安装。
]

修改完成后，保存文件，并执行 `source ~/.zshrc` 使配置生效，就可以开始体验插件。

= Tips

== `root` 用户

当你配置好登陆用户的 `zsh` 后，如果使用`sudo su`命令进入`root`用户的终端，发现还是默认的`bash`。建议在`root`用户的终端下，也安装`on my zsh`，设置与普通用户不同的主题以便区分，插件可以使用一样的。 `root`用户的`~/.zshrc`配置，仅供参考：

```bash
ZSH_THEME="ys"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting z extract web-search)
# 或
plugins=(git colored-man-pages colorize cp man command-not-found sudo suse ubuntu archlinux zsh-navigation-tools z extract history-substring-search python zsh-autosuggestions zsh-syntax-highlighting)
```

== 配置本地代理

如果你配置了本地代理，并希望终端的 git 等命令使用代理，那么可以在`~/.zshrc`中添加：

```bash
# 为 curl wget git 等设置代理
proxy () {
  export ALL_PROXY="socks5://127.0.0.1:1089"
  export all_proxy="socks5://127.0.0.1:1089"
}

# 取消代理
unproxy () {
  unset ALL_PROXY
  unset all_proxy
}
```

#titled-block(title: [提示])[
  这里假设本地代理的端口是 `1089`。
]

#image("images/202401012307093.png")

以后在使用 `git` 等命令之前，只需要在终端中输入 `proxy` 命令，即可使用本地代理。

=== WSL 配置本地代理

```bash
host_ip=$(cat /etc/resolv.conf |grep "nameserver" |cut -f 2 -d " ")
# 为 curl wget git npm apt 等设置代理
proxy () {
  export ALL_PROXY="http://$host_ip:10811"
  export all_proxy="http://$host_ip:10811"
# echo -e "Acquire::http::Proxy \"http://$host_ip:10811\";" | sudo tee -a /etc/apt/apt.conf > /dev/null
# echo -e "Acquire::https::Proxy \"http://$host_ip:10811\";" | sudo tee -a /etc/apt/apt.conf > /dev/null
}

# 取消代理
unproxy () {
  unset ALL_PROXY
  unset all_proxy
# sudo sed -i -e '/Acquire::http::Proxy/d' /etc/apt/apt.conf
# sudo sed -i -e '/Acquire::https::Proxy/d' /etc/apt/apt.conf
}
```

#titled-block(title: [注意])[
  这里假设宿主机局域网 http 代理的端口是 `10811`。
]

== 卸载 Oh-My-Zsh

```bash
# 终端输入
uninstall_oh_my_zsh
Are you sure you want to remove Oh My Zsh? [y/N]  Y

# 终端提示信息
Removing ~/.oh-my-zsh
Looking for original zsh config...
Found ~/.zshrc.pre-oh-my-zsh -- Restoring to ~/.zshrc
Found ~/.zshrc -- Renaming to ~/.zshrc.omz-uninstalled-20170820200007
Your original zsh config was restored. Please restart your session.
Thanks for trying out Oh My Zsh. It's been uninstalled.
```

== 手动更新 Oh-My-Zsh

On My Zsh 的自动更新提示误触关掉了解决办法，手动更新的方法如下：

```bash
upgrade_oh_my_zsh
```
