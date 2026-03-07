#import "@preview/arkheion:0.1.1": arkheion, arkheion-appendices
#import "@preview/mitex:0.2.6": *
#show: arkheion.with(
  title: "SSH相关问题",
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

= 开启 SSH 服务

按照以下步骤开启 SSH 服务。

+ 更新软件源和系统包

  ```bash
  sudo apt update
  sudo apt upgrade
  ```

+ 安装 OpenSSH 服务器

  ```bash
  sudo apt install openssh-server
  ```

+ 检查 SSH 服务状态

  ```bash
  sudo systemctl status ssh
  ```

  如果服务状态为 inactive (dead)，则说明 SSH 服务未开启，可以执行以下命令开启：

  ```bash
  sudo systemctl start ssh
  ```

+ 设置 SSH 开机自启

  ```bash
  sudo systemctl enable ssh
  ```

+ 配置防火墙（如果有的话）

  ```bash
  sudo ufw allow ssh
  ```

+ 测试 SSH 连接

  ```bash
  ssh your_username@your_server_ip
  ```

= 远程连接 SSH 时出现的问题

我们在远程连接 SSH 时，需要指定端口号，而 SSH 默认端口号为 22。我们使用下面这个命令来查看 SSH 服务的端口号：

```bash
netstat -tulpn
```

问题在于，有时会出现端口号没有开启的问题。

此时我们就需要开启 SSH 服务的端口号。开启端口号的通过修改 SSH 服务的配置文件来实现。

+ 找到 SSH 服务的配置文件
  - 客户端配置文件：`/etc/ssh/ssh_config`
  - 服务端配置文件：`/etc/ssh/sshd_config`

+ 修改服务端配置文件

  常见配置：

  ```bash
  Port 22 # 端口

  ListenAddress # 监听的IP

  Protocol 2 # SSH版本选择

  HostKey /etc/ssh/ssh_host_rsa__key # 私钥保存位置

  ServerKeyBits # 1024

  ServerFacility AUTH # 日志记录ssh登陆情况

  # KeyRegenerationInterval 1h # 重新生成服务器密钥的周期

  # ServerKeyBits 1024 # 服务器密钥的长度

  LogLevel INFO # 记录sshd日志消息的级别

  # PermitRootLogin yes # 是否允许root远程ssh登录

  # RSAAuthentication yes # 设置是否开启ras密钥登录方式

  # PubkeyAuthentication yes # 设置是否开启公钥验登录方式

  # AuthorizedKeysFile .ssh/authorized_keys # 设置公钥验证文件的路径

  # PermitEmptyPasswords no # 设置是否允许空密码的账号登录

  X11Forwarding yes # 设置是否允许X11转发

  GSSAPIAuthentication yes # GSSAPI认证开启
  ```

  默认端口号修改：

  ```bash
  # Port 22        					#这行加 # 号注释掉
  Port 2222      						#添加这一行
  ```

  监听 IP 地址：

  ```bash
  ListenAddress
  ```

  监听的 IP，允许某些特定的 IP 才可以 SSH 登录进来。

  采用 SSH 协议的版本：

  ```bash
  Protocol 2
  ```

  默认采用 SSH 2 协议，如果客户端不支持 SSH 2 协议，则无法连接。

  私钥配置：

  ```bash
  HostKey /etc/ssh/ssh_host_rsa__key
  # Hostkeys for protocol version 2
  HostKey /etc/ssh/ssh_host_rsa_key
  HostKey /etc/ssh/ssh_host_dsa_key
  ```

  版本 v2 的私钥保存路径。

  加密位：

  ```bash
  ServerKeyBits 1024
  ```

  钥匙串的加密位数，默认采用 1024 位加密。

  日志等级：

  ```bash
  ServerFacility AUTH & LogLevel INFO
  ```

  需要记录日志，并设定日志等级为 INFO，建议不用修改。

  GGSSAPI 认证：

  ```bash
  GSSAPIAuthentication yes
  ```

  GGSSAPI 认证默认已开启，经过 DNS 进行认证，尝试将主机 IP 和域名进行解析。若管理主机无对外域名，建议管理主机上在客户端的配置文件将此认证关闭。

+ 服务器端安全配置选项

  ```bash
  PermitRootLogin yes         # 允许root远程ssh登录
  PubkeyAuthentication yes    # 允许使用公钥验证登录
  AuthorizedKeysFile .ssh/authorized_keys # 公钥的保存路径
  PasswarddAuthentication yes # 允许使用密码验证登录
  PermitEmptyPasswords no     # 不允许空密码登录
  ```

  注意：如果开启公钥验证，可以关闭允许root登陆、关闭允许使用密码验证登陆，此时将采用公钥验证登陆，无需输入密码。建议采用此更安全的方式，直接使用私钥和公钥匹配的公钥验证方式。

+ SSH 其他管理

  ```bash
  [root@imxhy]# yum -y install policycoreutils-python

  [root@imxhy]# semanage port -a -t ssh_port_t -p tcp 2222

  [root@imxhy]# semanage port -l | grep ssh #查看SELinux设置

  [root@imxhy]# firewall-cmd --permanent --add-port=2222/tcp

  [root@imxhy]# systemctl restart firewalld.service

  [root@imxhy]# systemctl restart sshd.service
  ```

如果修改了 SSH 服务的配置文件，并且已经重启了 SSH 服务，单还是没有 22 端口号，那么问题可能出在 Socket 上，Socket 可能会导致你后输入的端口参数被“忽略”，从而看起来像是被“重定向”到了主连接的端口上。到底是不是 Socket 导致的，我们可以通过查看你 `sudo systemctl status ssh` 的输出来判断。
