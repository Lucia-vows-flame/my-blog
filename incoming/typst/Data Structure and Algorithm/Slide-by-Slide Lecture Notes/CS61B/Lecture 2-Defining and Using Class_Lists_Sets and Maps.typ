#import "@preview/arkheion:0.1.1": arkheion, arkheion-appendices
#show: arkheion.with(
  title: "Lecture 2 — Defining and Using Classes, Lists and Maps",
  authors: (
    (name: "Geoffrey Xu", email: "13149131068@163.com", affiliation: "Xidian University", orcid: "0009-0006-1640-1812"),
  ),
  // Insert your abstract after the colon, wrapped in brackets.
  // Example: `abstract: [This is my abstract...]`
  abstract: "Lecture 2 deepens the introduction to Java by organizing real programs into interacting classes. Through live coding in IntelliJ IDEA, we define methods and entry points, step through execution with the debugger, and motivate adding state to objects. The lecture transitions toward Java collections—Lists, Sets, and Maps—while discussing design trade‑offs, constructors, and static vs. instance members.",
  keywords: (
    "Java",
    "Classes",
    "Objects",
    "Constructors",
    "Static vs Instance",
    "IntelliJ IDEA",
    "Lists",
    "Sets",
    "Maps",
    "Collections",
    "Debugging",
  ),
  date: "October 23, 2025",
)
#set par(spacing: 1.5em) //设置段落间距
#set text(
  font: ("Merriweather", "Noto Serif CJK SC"),
  size: 12pt,
  lang: "zh",
) //设置正文字体, 中文使用 Noto Serif CJK SC, 英文使用 Merriweather
#show heading: set text(font: "New Computer Modern", weight: "bold") //设置标题字体,bold表示粗体
#set heading(numbering: "1.") //设置标题编号格式
#outline(depth: 4) //设置目录深度
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
#set image(height: 9cm)

= Slide 01

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0001.jpg",
  ),
  caption: [Lecture 2 Slide 01],
)

大家好，让我先调整一下麦克风。好，先做几个通知：我已经把教室秩序收回来了，抱歉各位。好的好的。我做了一份清单，如果你想跟踪最近发生的所有事情，可以用它；你不一定要用，但它在那儿。如果你想知道前五周所有的截止事项，我希望这能帮助你们组织安排。如果你和我一样，需要明确的截止日期来推进事情，那么这些就是你们的截止日期。作业 0A 今天截止。现在还是课刚开始，大家还在陆续进来。我想再提示一下：各位，我们把注意力收回到课堂。我知道大家有很多想聊的；我相信你们，我们可以专心听讲——就快好了，马上开始。关于作业 0A，你们可能注意到还有一些 Practice‑It 的链接没有完全删掉。我本来应该发现这个问题；学期开始之前我没仔细看，几乎就是在开学前我们才意识到我们把旧的内容留了进去。Practice‑It 这个网站已经下线了，就在学期开始前被永久关闭了，抱歉。如果因为需要做很多环境配置，导致你完成作业 0A 需要更多时间——以前我们用那个在线网站，所以你们不需要用 Git、IntelliJ IDEA 等这些工具——那就会给你们额外的时间。好的。

= Slide 02

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0002.jpg",
  ),
  caption: [Lecture 2 Slide 02],
)

再补充一点：如果你在看录播/网络课，我鼓励你在看视频时多按暂停，先想一想“我下一步会做什么”，这样通常比一直看下去学得更多。就是这样一个小提示。

= Slide 03

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0003.jpg",
  ),
  caption: [Lecture 2 Slide 03],
)

今天我们会更深入地学习 Java。我应该把幻灯片上的年份改一下——抱歉。这不是同一年的幻灯片，但月份是一样的；你就当它是今年的；除了个别地方，这些内容都是新更新的。

= Slide 04

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0004.jpg",
  ),
  caption: [Lecture 2 Slide 04],
)

今天我还会做一段现场编码，不过这次我会用 IntelliJ IDEA——这也是我们希望你们使用的工具。正如上次所说，在 Java 中每个函数都隶属于某个类；如果我们真的想运行一个类，就必须提供一个 main 方法。

= Slide 05

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0005.jpg",
  ),
  caption: [Lecture 2 Slide 05],
)

现在切到 IntelliJ IDEA，把字体调大一点，我们开始编程。首先从 Dog 类开始，在这个 Dog 类里写一个 makeNoise 方法。实际上，我要稍微挪一下位置——确保操作更符合人体工学。

我要写这个 makeNoise 方法，它要做的就是“汪汪叫（bark）”。现在如果我们只有这个方法然后尝试运行这个类，什么都不会发生——因为 Dog 类没有 main 方法，没有可执行的入口，所以这样不行。

= Slide 06

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0006.jpg",
  ),
  caption: [Lecture 2 Slide 06],
)

我可以加一个 main 方法，然后在里面调用 makeNoise，这样就能看到 'bark'——确实能打印出来。但我现在要展示的是：开始思考真实的 Java 程序是如何组织的——通常是多个类以某种方式协同工作。

= Slide 07

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0007.jpg",
  ),
  caption: [Lecture 2 Slide 07],
)

= Slide 08

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0008.jpg",
  ),
  caption: [Lecture 2 Slide 08],
)

所以我要把 makeNoise 的调用不放在 Dog 类里，而是放到 DogLauncher 里。这样做之后，你会看到 makeNoise 下面有红色波浪线，抱怨说它不知道 makeNoise 是什么——因为这个类里没有那个方法。所以我需要回到 Dog 类，让它来发出叫声；也就是在 DogLauncher 里调用 Dog 的 makeNoise。现在当我运行 DogLauncher.main 时，就会得到 'bark'。如果我进入 IntelliJ IDEA 的调试器——你们很快就会学到——我可以单步执行，看到当我点进这个方法时，第一行代码是调用 Dog.makeNoise。然后我再点进去，就跳到了 Dog 类，真正去执行 makeNoise。虽然这不算深入，但这是我们要从这里开始的。

= Slide 09

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0009.jpg",
  ),
  caption: [Lecture 2 Slide 09],
)

到目前为止有问题吗？

= Slide 10

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0010.jpg",
  ),
  caption: [Lecture 2 Slide 10],
)

现在，当我们编写 Java 程序——或者说任何程序——时，常常会试图再现现实世界的特征：我们会建立列表（List）、集合（set）、映射（Map）、客户、学生、狗等等。因此我这里准备了几个视频，想说明“狗并不都一样”。这是其中一只狗（音乐），听起来很悦耳。好，完整视频你们稍后可以自己看。还有的狗，我觉得，叫声更像另一种。重点是：我们希望构建的类能够表现出多样性。不是说——哦，我不——好，抱歉，网络问题；谢谢谢谢，我们刚刚在维持课堂秩序。好了，有问题吗？抱歉，Zoom。今天我不打算讨论“狗派 vs 猫派”。原则上我们可以为每一种狗写一个不同的 Dog 类——比如左边那只狗叫 Maya——但这在实际开发中并不好用。所以我们要利用这样一个事实：在 Java 里，类不仅可以包含方法，还可以包含数据。比如说……

= Slide 11

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0011.jpg",
  ),
  caption: [Lecture 2 Slide 11],
)

我们继续。抱歉，Zoom。今天我不打算讨论“狗派还是猫派”。原则上我们当然可以为每一种狗都写一个不同的 Dog 类，比如左边那只狗叫 Maya；但在实际开发中这么做并不好用。

= Slide 12

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0012.jpg",
  ),
  caption: [Lecture 2 Slide 12],
)

所以我们要利用这样一个事实：在 Java 里，类不仅可以（也不必仅仅）包含函数，它们还可以包含数据。比如：这个 Dog 类可以有一个 size（体型）变量。

= Slide 13

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0013.jpg",
  ),
  caption: [Lecture 2 Slide 13],
)


= Slide 14

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0014.jpg",
  ),
  caption: [Lecture 2 Slide 14],
)


= Slide 15

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0015.jpg",
  ),
  caption: [Lecture 2 Slide 15],
)


我切到 Dog 类，在这里加上属性。界面有点抽风——我就把锅甩给 Zoom 吧，哈哈。哦，原来是程序还在运行着。好，现在我写 `public int`，变量名我用 `weightInPounds`（以磅为单位的体重）。

这个字段就是狗的体重，是每只狗都拥有的属性。现在回到 DogLauncher（实际上是 Dog 里），我要修改 `makeNoise` 方法：如果 `weightInPounds` 大于 20（随便取的阈值），就发出低沉洪亮的“Arro”；如果 `weightInPounds` 小于 10，就更像是“bark（汪）”；否则就是“yip（尖叫）”。像我们看到的另一只小狗那样——“yip yip yip yip”。基于 `weightInPounds` 这个属性，不同的狗会有不同行为。这就是思路。注意，`weightInPounds` 现在被标红并报错：提示是“非静态字段 weightInPounds 不能从静态上下文引用（non-static field ... cannot be referenced from a static context）”。我稍后会详细解释；先用一个权宜之计：把 `static` 这个词删掉。

一旦去掉 `static`，这个函数就变成了实例方法，我就能访问 `weightInPounds`。

= Slide 16

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0016.jpg",
  ),
  caption: [Lecture 2 Slide 16],
)

= Slide 17

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0017.jpg",
  ),
  caption: [Lecture 2 Slide 17],
)

接着在 `DogLauncher` 里调整代码：比如 `Dog maya = new Dog(); maya.weightInPounds = 30; maya.makeNoise();` 我稍后会再带大家过一遍。运行后我们得到对应的叫声。如果把体重改到 9 磅，会得到“bark”；（嗯，这不太符合我刚才的预期）如果设成大于 10，又会是“yip yip yip”。总之，我们现在构建了一个“类作为模板”的结构：它是所有可能存在的狗对象的蓝图；比如都需要有 `weightInPounds`。为了与讲义保持一致，我把它改名成 `size`。

IntelliJ IDEA 的重命名（Rename）很聪明，不像纯文本编辑器——我在这里把名字改成 `size`，它会在所有引用处同步更新。好，到这里我们就有了：`size`、`weightInPounds` 这些不同命名的想法。

= Slide 18

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0018.jpg",
  ),
  caption: [Lecture 2 Slide 18],
)

设定 `weightInPounds=51`，然后运行 `makeNoise()`，得到 "woooooof"。

= Slide 19

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0019.jpg",
  ),
  caption: [Lecture 2 Slide 19],
)

还有一件事要做：DogLauncher 的写法有点别扭。用“先出生一个 Maya，然后再去设定 size”的写法不太自然。我们希望能在“出生”的同时就指定它的体型，比如：创建 Maya 的那一刻就说 `size = 9`。因此回到 Dog 类，新增一个“构造函数（Constructor）”：`public Dog(int s) { size = s; }`。当然你也可以写成 `size = s * 5` 或 `s + 3`（虽然很怪），但这里我们就直接 `size = s`。现在当我创建狗并调用 `makeNoise` 时，流程更顺畅，不再有那种“先生成一个飘在空中的虚无之狗再设定 size”的尴尬语法。

= Slide 20

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0020.jpg",
  ),
  caption: [Lecture 2 Slide 20],
)

= Slide 21

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0021.jpg",
  ),
  caption: [Lecture 2 Slide 21],
)

到目前为止应该和 61A 的内容有些似曾相识；等价的 61A 示例看起来也是这样——有“构造函数（Constructor，在 Python 中是 `__init__`）/初始化”这一环节。

有人提问：能不能直接写 `Dog.makeNoise`？如果我尝试那样做（屏幕刚刚卡了一下），你会看到——这样是行不通的。错误信息会说：“实例方法不能从静态上下文引用（non‑static method cannot be referenced in a static context）”。直观地讲，你是在对“狗的理念/抽象（类本身）”说“请你叫一声”，但此时并没有“具体的那只狗”，所以它没法叫。这个事实就体现在方法不是 `static` 上：实例方法需要具体实例。如果它是 `static`，它会是附加到类本身的东西。如果我把方法改成 `static`，又会有别的问题：此时访问不到 `size`，因为仍然没有具体的那只狗。

按我所知，Java 也不允许同时存在同名的“静态”和“非静态”方法重载（和上节里按参数类型重载不同）。

= Slide 22

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0022.jpg",
  ),
  caption: [Lecture 2 Slide 22],
)

= Slide 23

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0023.jpg",
  ),
  caption: [Lecture 2 Slide 23],
)

做些术语澄清：上面的 `weightInPounds`/`size` 是“实例变量（instance variable）”，你可以有很多个属性（实例变量），比如“腿的数量”“舌头数量”等。我们还定义了“构造函数（Constructor）”，它不是方法，而是用来“实例化（instantiate）类”的东西。另外是非静态方法（或称为实例方法（instance method））：如果一个方法需要使用实例变量或需要一个实例来调用（invoke）它，就不应该标记为 `static`，而是要在具体对象上调用它（例如“`Maya.makeNoise()`”）。

= Slide 24

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0024.jpg",
  ),
  caption: [Lecture 2 Slide 24],
)

类不仅能有方法，还能有数据；我们为 Dog 加了 `size`，并且可以据此“实例化”为具体对象，实例在 Java 中被称为对象。所有 Dog 实例共同遵循同一份“蓝图（blueprint）”，具有完全一致的一组属性。这和一些语言（比如 MATLAB）不同，后者可能允许每个对象拥有各自不同的一组实例变量；而在 Java 中同一类型的对象必须严格遵循同一蓝图。换句话说，你不能给某一只 Dog 临时加一个新的实例变量；比如我想写“`name = Frank`”，这是语法错误。

= Slide 25

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0025.jpg",
  ),
  caption: [Lecture 2 Slide 25],
)

还有一组常见术语：
- “声明（declaration）”：比如写 `Dog smallDog;`，表示留出一个可以放狗的“位置/变量”。
- “实例化（instantiation）”：`new Dog(20)` 是把一只新狗“创造出来”。
- “赋值（assignment）”：把这只狗“放到”某个变量里。
可以把三件事写在同一行，也可以分开写。如果你实例化了一只“匿名狗”但没有把它存放到任何变量里，它会被垃圾回收（听上去有点可怕）：对象被创建出来后立刻被销毁，因为我们没有保存引用。点号`.` 表示“访问成员”：比如 `hugeDog.makeNoise()`/`hugeDog.size` 都是在访问 hugeDog 这个对象的成员。

问答：Java 里没有“析构函数”，回收由垃圾回收器处理——这也是我们这门课选 Java 而不是 C++ 的原因之一（避免手动内存管理）。上面第三行之所以能工作，是因为我们之前已经声明过变量；如果没有声明，是不行的。

问答：按照我们写的构造函数（Constructor），构造时就会给 size 赋值。当然，你也可以在之后直接访问并修改 `weightInPounds/size`。

与 Python 不同，Java 在创建对象时需要显式写出 `new`。几乎每次你要“造一只新狗”，都要写 `new`（少数语法糖例外），Java 是冗长的。如果不写 `new`，编译器会迷惑并报语法错误；例如直接写 `Dog 20` 是不行的。前面的例子也说明：我们在构造后可以直接访问并修改字段（比如体重/体型），作业0会让你多练习这一类操作。

= Slide 26

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0026.jpg",
  ),
  caption: [Lecture 2 Slide 26],
)

来看看“对象数组”。要创建一个“能放两只狗的数组”，先用 `new` 创建“两个位置的数组”，再分别用 `new Dog(...)` 实例化并放入左（0）、右（1）两个位置；随后你就可以对某一只特定的狗调用 `makeNoise()`。注意：数组在创建时大小固定——这也是 Java 性能的一部分基础。

在 Java 中创建数组会在作业0中讲解。

= Slide 27

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0027.jpg",
  ),
  caption: [Lecture 2 Slide 27],
)

回到“静态成员 vs 非静态成员”。静态方法（static）通过“类名”调用；实例方法通过“具体对象”调用。静态方法不能访问“我的实例变量”，因为此时并没有那个“我”。静态的含义可以理解为不变的（unchanging）、永久的（permanent）。

= Slide 28

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0028.jpg",
  ),
  caption: [Lecture 2 Slide 28],
)

为什么还需要静态方法？静态方法看起来好像不够灵活？

= Slide 29

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0029.jpg",
  ),
  caption: [Lecture 2 Slide 29],
)

一个自然的例子是 `Math`：调用 `Math.round(5.6)` 时，我们无需也不应先创建一个 `Math` 对象。静态方法表达的是“与具体实例无关的能力”。

一个类中可以同时存在静态与非静态方法（实例方法）。我们在 `Dog` 里添加一个静态方法 `maxDog(Dog a, Dog b)`：比较两只狗，返回更大者。调用时应使用类名：`Dog.maxDog(Maya, HugeGreg)`；随后再对返回的那只狗调用 `makeNoise()`。

= Slide 30

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0030.jpg",
  ),
  caption: [Lecture 2 Slide 30],
)

= Slide 31

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0031.jpg",
  ),
  caption: [Lecture 2 Slide 31],
)

= Slide 32

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0032.jpg",
  ),
  caption: [Lecture 2 Slide 32],
)

这是我们创建的 `maxDog` 静态方法。

有人问：能否用“实例名”去调用静态方法？语法上可以，但风格上不推荐（IDE 会给出“通过实例访问静态成员”的警告）。又问：静态方法如何访问 Maya 与 HugeGreg 的字段？答案是：它并不是访问“某个隐含的 this”，而是把“具体实例”作为参数传入，比较它们的 `size`。

= Slide 33

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0033.jpg",
  ),
  caption: [Lecture 2 Slide 33],
)

= Slide 34

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0034.jpg",
  ),
  caption: [Lecture 2 Slide 34],
)

我们也可以写一个非静态版本的 `maxDog`：用 `this.size/this.weight` 与 `other.size/other.weight` 比较，大者返回 `this`，否则返回 `other`。在 Java 中，`this` 可以省略（如果省略会被推断为“自己”，即 `this`），但为了可读性常常保留。两种写法（静态/非静态）都可以；调试器里你会看到非静态版本是如何被“具体那只狗”调用进入的。

使用静态方法还是非静态方法，取决于你的选择。

= Slide 35

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0035.jpg",
  ),
  caption: [Lecture 2 Slide 35],
)

= Slide 36

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0036.jpg",
  ),
  caption: [Lecture 2 Slide 36],
)

静态字段（`static` 字段）表示“所有实例共享的属性”。例如可以为所有狗设定一个公共的叫声音色字符串。从技术上讲，你可以在代码的任何地方改变这个静态字段，但强烈不建议你改变静态字段，请避免在程序中修改它（在需要常量时，请用 `static final`，`static` 表示“整个类共享的通用属性”，`final` 表示“永远不会改变，即不可更改”。二者含义不同。）。永远不要改变静态字段的值，永远不要有可变的静态字段，这非常危险，原因会在后续项目中详细说明。

= Slide 37

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0037.jpg",
  ),
  caption: [Lecture 2 Slide 37],
)

所以，一个类可以有这些静态和非静态成员的混合。我们已经看到了如何拥有静态和非静态方法。我们可以有静态变量和非静态变量。在大多数情况下，几乎永远不要使用静态变量，只有偶尔一些情况需要这样做。此外，使用实例来访问静态成员（static member）在语法上是合理的，但我建议不要这样做。当然，使用类来访问非静态成员（non-static member）在语法上就是错误的。

= Slide 38

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0038.jpg",
  ),
  caption: [Lecture 2 Slide 38],
)

= Slide 39

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0039.jpg",
  ),
  caption: [Lecture 2 Slide 39],
)

= Slide 40

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0040.jpg",
  ),
  caption: [Lecture 2 Slide 40],
)

接下来切换到“列表（List）”。

= Slide 41

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0041.jpg",
  ),
  caption: [Lecture 2 Slide 41],
)

在编程语言里，列表是“有序的对象序列”，通常以方括号和逗号分隔表示；列表根据编程语言作者决定包含的操作，常见操作包括追加、按索引访问、按索引或按值删除等，这些都是不同列表和不同语言支持的功能。

= Slide 42

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0042.jpg",
  ),
  caption: [Lecture 2 Slide 42],
)

在 Python 中，列表的 `[]` 语法很直观。

= Slide 43

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0043.jpg",
  ),
  caption: [Lecture 2 Slide 43],
)

= Slide 44

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0044.jpg",
  ),
  caption: [Lecture 2 Slide 44],
)

= Slide 45

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0045.jpg",
  ),
  caption: [Lecture 2 Slide 45],
)

= Slide 46

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0046.jpg",
  ),
  caption: [Lecture 2 Slide 46],
)

而在 Java 里，我们要在 IntelliJ IDEA 中这样做：先声明变量类型 `List`，再用一个具体实现来实例化。直接写 `new List` 不行，因为 `List` 是一个抽象类型（接口/抽象概念），不能被直接实例化；需要选择具体实现，例如 `ArrayList`。注意，IDEA 会提示你导入 `java.util.List` 与 `java.util.ArrayList`，然后使用 `add` 添加元素。

= Slide 47

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0047.jpg",
  ),
  caption: [Lecture 2 Slide 47],
)

完成导入与实例化后，代码诸如：`List L = new ArrayList(); L.add("A"); L.add("B"); ...`；运行即可得到 `[A, B, C]`。与 Python 相比，Java 更为“啰嗦”，但并不复杂——关键是要理解“接口与实现分离”。

Java 真正有趣的事情是：Java 将“抽象数据类型（ADT）”与“该数据类型的具体实现”严格区分：以 List 为例，Java 中有许多不同的列表，它接口相同，但实现是 `ArrayList`、`LinkedList`、`Vector` 等。把代码中的实现从 `ArrayList` 换成 `LinkedList`，对外行为（如打印 A,B,C）不变，只是底层实现策略不同。

与 Python 不同（语法层面只有一种“核心列表”），在 Java 中你必须显式“选择哪一种 List 实现”。Python 的内建列表本质上也是“基于数组”的结构（我们约四讲后深入），但在 Java 里这一选择是显式且程序员可见的，所以 Java 更低级一些。

= Slide 48

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0048.jpg",
  ),
  caption: [Lecture 2 Slide 48],
)

= Slide 49

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0049.jpg",
  ),
  caption: [Lecture 2 Slide 49],
)

= Slide 50

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0050.jpg",
  ),
  caption: [Lecture 2 Slide 50],
)

= Slide 51

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0051.jpg",
  ),
  caption: [Lecture 2 Slide 51],
)

= Slide 52

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0052.jpg",
  ),
  caption: [Lecture 2 Slide 52],
)

编程语言中有一个术语--抽象数据类型。“抽象数据类型”意味着：不论底层实现如何，所有 List 都保证提供#text(fill: red)[一组通用操作]：`add`、`addAll`、`clear`、`contains`、`equals`、`get`、`hashCode`、`indexOf`、`isEmpty`、`iterator` 等。

= Slide 53

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0053.jpg",
  ),
  caption: [Lecture 2 Slide 53],
)

为什么要有多种实现？

= Slide 54

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0054.jpg",
  ),
  caption: [Lecture 2 Slide 54],
)

答案之一是性能权，不同的列表在不同的操作上有不同的性能。例如 `LinkedList` 在删除表头时很快，而 `ArrayList` 删除表头很慢；如果你的用例频繁“删除表头”，那就选 `LinkedList`。有些实现还会额外提供如“栈”的 `push`/`pop` 操作（后面课程会讲）。注意，栈是用列表实现的。

= Slide 55

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0055.jpg",
  ),
  caption: [Lecture 2 Slide 55],
)

= Slide 56

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0056.jpg",
  ),
  caption: [Lecture 2 Slide 56],
)

= Slide 57

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0057.jpg",
  ),
  caption: [Lecture 2 Slide 57],
)

= Slide 58

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0058.jpg",
  ),
  caption: [Lecture 2 Slide 58],
)

在 Java 中，Python 的“`[i]` 取元素”对应 `get(i)`。如果此时我们没有指定元素类型（即所谓“原始类型 raw type”，IDE 会警告 `raw use of parameterized class List`），`get` 返回的是 `Object`，直接赋给 `String s = L.get(0)` 会报错。

= Slide 59

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0059.jpg",
  ),
  caption: [Lecture 2 Slide 59],
)

在 Java 4 时代，需要“强制类型转换（cast）”。自 2005 年起（Java 5 引入“泛型 Generics”），我们可以在左侧写 `<String>` 指定元素类型（此时，我的列表就只能包含字符串，这实际上是一件非常好的事情），并在右侧使用“菱形语法” `<>` 推断类型；这样代码“现代化”后，既无警告，也可安全赋值给 `String`。

如果不使用泛型，你技术上可以把不同类型（字符串、整数等）混放进同一个 List；也可以把元素类型声明为 `Object`。但使用泛型约束（如 `List<String>`）后，列表就只能包含字符串，不能在包含其他数据类型，这能让编译器在源头保证类型一致。
= Slide 60

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0060.jpg",
  ),
  caption: [Lecture 2 Slide 60],
)

= Slide 61

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0061.jpg",
  ),
  caption: [Lecture 2 Slide 61],
)

为什么泛型使列表不能包含多种数据类型是一件好事？

= Slide 62

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0062.jpg",
  ),
  caption: [Lecture 2 Slide 62],
)

泛型带来的“约束”是优势，类型单一使得：
- 可能更快（对象大小更可预测，优化更容易）；
- 更容易排序（混合类型难以比较）；
- 更少“以为拿到字符串却实际是整数”的错误；
- 程序更易于推理与维护。Java 倾向“用约束换可控复杂度”，使大型程序更可管理。

我的想法是，使用泛型进行约束意味着只是更少的自由。就像当你说它是一个字符串列表时，它就是一个字符串列表。这对我来说是一件大事，我在给自己设置约束，当我在思考什么使编程成为可能时，实际上是设置约束使编程成为可能。自由给你复杂性，就像允许自己使用静态变量或其他什么，而复杂性很难装进你的大脑，很难跟踪一个复杂的程序。所以 Java 有很多这种约束，它束缚并强迫你只能做某些事。

这是这门课的一个主题：给自己设置约束。

= Slide 63

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0063.jpg",
  ),
  caption: [Lecture 2 Slide 63],
)

让我们来看看数组（Arrays）。

= Slide 64

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0064.jpg",
  ),
  caption: [Lecture 2 Slide 64],
)

数组（Array）是 Java 提供的“更受限的列表”：
- 创建时必须指定固定大小，且大小不可变；
- 所有元素类型必须相同；
- 没有方法（无 `get`/`max`/`sort` 等），只有 `[]` 读写；
- Python 没有这种“固定界限”的同类内建类型。数组施加更严格的约束，但因此更高效。

= Slide 65

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0065.jpg",
  ),
  caption: [Lecture 2 Slide 65],
)

为什么在 Java 中既有列表，又有数组？

你可以把数组想象成一个列表，但功能更少，更少的功能源自于上一页所说的那些限制。

= Slide 66

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0066.jpg",
  ),
  caption: [Lecture 2 Slide 66],
)

为何数组通常更快？你可以很容易地遍历一个数组，很快速地获取某个元素，因为布局规则简单、定位计算开销小、内存更紧凑（细节在 61C）。Java 的数组是“特等公民”（有专门语法），而 List 是“构建在其之上”的抽象。Java 追求性能；Python 则更注重优雅与简洁。

所以，在 Java 中，数组地性能更好，读写它们更快，数组使用更少的内存。后面的课程我们会使用数组构建我们自己的列表，那是你会理解 Python 数组使如何用 C 构建的，因为 Python 的编译器、解释器是用 C 构建的。



= Slide 67

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0067.jpg",
  ),
  caption: [Lecture 2 Slide 67],
)

你们认为为什么 Java 偏爱数组而不是列表？

= Slide 68

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0068.jpg",
  ),
  caption: [Lecture 2 Slide 68],
)

因为 Java 是一种为性能而构建的语言，而 Python 是为了美观而构建的，简单而优雅。所以，Java 把高性能的东西作为其一等对象。

进一步对比语言取舍：C 语言更追求极致性能，但抽象层次更低（更接近底层硬件）、代码更难写。你在 61A→61B→61C 的过渡中，会逐步从“优雅简洁”走向“面向性能与内存细节”的思维方式——掌控更强，也更容易“疼”。

关于 C++ vs Java：我不认为 C++ 比 Java 更“优雅”。Java 的一个优势是自动内存管理（垃圾回收），在本课中无需手动释放对象。C++ 学习曲线更陡，需要自行管理内存；我已近 15 年未写 C++。

= Slide 69

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0069.jpg",
  ),
  caption: [Lecture 2 Slide 69],
)

= Slide 70

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0070.jpg",
  ),
  caption: [Lecture 2 Slide 70],
)

引入 Map（映射）：它不是“列表”，而是“键—值对”的集合，且“键”唯一。Python 中叫 dictionary；理论计算机科学称其为关联数组（associative array）；某些课程中也叫 symbol table。

= Slide 71

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0071.jpg",
  ),
  caption: [Lecture 2 Slide 71],
)

= Slide 72

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0072.jpg",
  ),
  caption: [Lecture 2 Slide 72],
)

在 Java 中，先声明“从某类型到某类型”的 `Map<K,V>`（例如 `Map<String,String>`），再选择具体实现（如 `TreeMap`、`HashMap`，它们有各自的权衡）。语法不如 Python 优雅，但这是 Java 的标准用法。

示例：插入“meow→cat”“dog→woof”，再用 `get("cat")` 取回对应值。

练习题（Homework z0b）会让你动手实践。

我想强调的两个关键点是：
+Map 需要同时指定“键类型 K”和“值类型 V”。
+常见实现：`TreeMap` 与 `HashMap`（）。类比 Python：其核心容器底层往往使用“基于数组的列表（array list）”和“基于哈希的映射（hash map）”。

= Slide 73

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0073.jpg",
  ),
  caption: [Lecture 2 Slide 73],
)

= Slide 74

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0074.jpg",
  ),
  caption: [Lecture 2 Slide 74],
)

后续安排：接下来约五讲深入“链表与数组列表”的讲解；期中后学习“树映射与哈希映射”。作业 0b 已发布，和 0a 一样短，请尽快开始。

= Slide 75

#figure(
  image(
    "images/[61B-Sp25]-Lecture-2---Defining-and-Using-Classes/[61B Sp25] Lecture 2 - Defining and Using Classes_page-0075.jpg",
  ),
  caption: [Lecture 2 Slide 75],
)

查看清单链接以了解所有待办（Todo）。若想讨论 C++ vs Java，请下课后来前排交流。

