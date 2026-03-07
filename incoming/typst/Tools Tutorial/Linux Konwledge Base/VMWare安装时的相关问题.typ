#import "@preview/arkheion:0.1.1": arkheion, arkheion-appendices
#import "@preview/mitex:0.2.6": *
#show: arkheion.with(
  title: "VMWare安装时的相关问题",
  authors: (
    (name: "Geoffrey Xu", email: "13149131068@163.com", affiliation: "Xidian University", orcid: "0009-0006-1640-1812"),
  ),
  // Insert your abstract after the colon, wrapped in brackets.
  // Example: `abstract: [This is my abstract...]`
  //abstract: lorem(55),
  //: ("First keyword", "Second keyword", "etc."),
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

= VMWare 联网问题

VMWare 安装虚拟机后，在使用桥接模式的情况下，即使与宿主机处于同一网段，也可能出现无法联网的情况。

解决方法：使用 NAT 模式，即将虚拟机的网络连接方式设置为 NAT 模式，即可解决此问题。

== 使用 NAT 模式的前提

打开 Windows 的任务管理器，在“服务”选项中开启“VMware NAT Service”和“VMWare DHCP Service”。

== 开启 NAT 模式

打开 VMWare，选择需要开启 NAT 模式的虚拟机，点击“编辑虚拟机设置”按钮，选择“网络适配器”选项卡，在“网络连接”选择中选择“NAT”模式。

== 配置虚拟机 VMnet8 的 NAT 模式

打开 VMWare 左上角的“编辑”，选择“虚拟网络编辑器”。可以看到有两个虚拟网卡，然后点击“更改设置”。

#image("images/image1.png")

此时可以看到三个虚拟网卡，如下图所示。

#image("images/PixPin_2025-12-21_15-30-21.png")

这三个虚拟网卡的作用分别是：

- VMnet0：用于桥接网络下的虚拟交换机
- VMnet1：用于Host-Only网络下的虚拟交换机
- VMnet8：用于NAT网络下的虚拟交换机

选择 VMnet8，勾选“NAT模式”、“将主机虚拟适配器连接到此网络”、“使用本地DHCP服务将IP地址分配给虚拟机”。

#image("images/PixPin_2025-12-21_15-33-38.png")

下面这一步非常重要：

我们需要根据我们主机中的 VMnet8 的 IP 地址来设置 VMWare 中 VMnet8 的子网IP 和子网掩码，要求是和主机处于同一网段。我们在主机中使用 `ipconfig` 查看 VMnet8 的 IP 地址，如下图所示。

#image("images/PixPin_2025-12-21_15-38-32.png")

`192.168.137.1` 是 VMnet8 的 IP 地址，我们需要将 VMWare 中 VMnet8 的子网IP设置为`192.168.137.0`，要和主机处于同一网段，子网掩码自然是和主机相同，为`255.255.255.0`。

然后点击“NAT设置”按钮，保持子网IP地址为`192.168.137.0`、子网掩码为`255.255.255.0`、网关IP为`192.168.137.2`，然后点击“确定”。

#image("images/PixPin_2025-12-21_15-34-57.png")

然后点击“DHCP设置”按钮，查看 IP 地址范围，这里保持默认即可，然后点击“确定”。

#image("images/PixPin_2025-12-21_15-43-56.png")

注意，后面需要在虚拟机中配置静态 IP 地址，这个静态 IP 地址需要在这里 DHCP 设置的 IP 地址范围内。

全都设置好后，点击“确定”按钮，关闭“虚拟网络编辑器”。

== 配置 Windows 主机的 WLAN 和 VMnet8

打开 Windows 的“控制面板”，选择“网络和 Internet”→“网络和共享中心”，然后点击“更改适配器设置”按钮。

在这里可以看到Host-only模式的 VMnet1 和 NAT模式 VMnet8，当前 Windows 主机连接的是校园网的 WLAN。

#image("images/PixPin_2025-12-21_15-47-36.png")

右键“WLAN”，点击“属性”，点击“共享”，勾选“允许其他网络用户连接”，选择“VMnet8”，然后点击“确定”。

#image("images/PixPin_2025-12-21_15-48-56.png")

然后双击“VMnet8”，点击“详细信息”，可以看到 IPV4 地址为 `192.168.137.1`，子网掩码为 `255.255.255.0`，这就是前面使用 `ipconfig` 命令查看到的 VMnet8 的 IP 地址和子网掩码。

再次强调，主机的 VMnet8 和虚拟机的 VMnet8 必须处于同一网段，并且子网掩码必须相同。

== 修改 Ubuntu 的配置文件

打开 Ubuntu 虚拟机，然后打开终端，进行配置文件的修改。

Ubuntu 的网络配置文件存储在 `/etc/netplan` 目录下，具体的文件名可能不同，我的配置文件为 `/etc/netplan/01-installer-config.yaml`，下面我们需要修改这个配置文件。

```bash
sudo nano /etc/netplan/01-installer-config.yaml

# 修改文件为以下内容:
network:
  ethernets:
    ens33:
      dhcp4: false # false 表示使用静态 IP 地址
      addresses:
        - 192.168.137.180/24 # 这里的 IP 地址要在前面配置的 DHCP 范围内
      routes:
        - to: default
          via: 192.168.137.2 # 网关地址，这里要和前面在NAT设置中配置的网关地址相同
      nameservers:
        addresses:
          - 8.8.8.8
          - 114.114.114.114
  version: 2

# 使上述修改生效
sudo netplan apply

# 测试 Windows 能否 ping 通 Ubuntu
ping 192.168.137.180

# 测试 Ubuntu 能否 ping 通 baidu.com
ping www.baidu.com

# 如果 ping 通，则说明配置成功。此时安装 net-tools 包，因为初始的 Ubuntu 是没有安装 net-tools 包的。
sudo apt install net-tools
```

= VMWare 代理

直接在 clash for windows 中开启 TUN 模式，即虚拟网卡模式即可。

如果这样无法解决，自行上网搜索解决方法。

= open-vm-tools 安装遇到的问题

新版本的 VMWare 无法在 VMWare 这个软件安装 open-vm-tools，需要我们在 Ubuntu 中下载open-vm-tools的安装包，然后进行安装。

安装包的链接在 VMWare 软件中点击“安装VMware Tools”按钮时会自动弹出来。

安装教程链接为：
#link("https://knowledge.broadcom.com/external/article/315313")[VMWare Tools 安装教程]

当我们根据教程进行安装时，会遇到一个问题，问题描述如下：

```bash
INPUT: [no]  default

Initializing...

Segmentation fault (core dumped)

Making sure services for VMware Tools are stopped.

Stopping VMware Tools services in the virtual machine:

  VMware User Agent (vmware-user):                                    done

  Unmounting HGFS shares:                                             done

  Guest filesystem driver:                                            done

The installation status of vmsync could not be determined.

Skippinginstallation.

The installation status of vmci could not be determined. Skippinginstallation.

The installation status of vsock could not be determined. Skippinginstallation.

The installation status of vmxnet3 could not be determined.

Skippinginstallation.
```

解决方法：

1. 先删除现有的 open-vm-tools：

```bash
cd vmware-tools-distrib/bin #vmware-tools-distrib目录是下载的安装包解压后的目录，根据官网的教程，我们会把它放在桌面上

sudo ./vmware-uninstall.pl #执行uninstall脚本，会删除open-vm-tools
```

2. 打开终端，执行以下命令：

```bash
sudo apt install open-vm-tools open-vm-tools-desktop
```
