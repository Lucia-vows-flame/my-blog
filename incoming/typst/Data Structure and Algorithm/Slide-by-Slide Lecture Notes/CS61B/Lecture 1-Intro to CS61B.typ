// R3: Polished wording, unified terminology, light paragraph reflow
#import "@preview/arkheion:0.1.1": arkheion, arkheion-appendices
#show: arkheion.with(
  title: "Lecture 1 Intro to CS61B",
  authors: (
    (name: "Geoffrey Xu", email: "13149131068@163.com", affiliation: "Xidian University", orcid: "0009-0006-1640-1812"),
  ),
  // Insert your abstract after the colon, wrapped in brackets.
  // Example: `abstract: [This is my abstract...]`
  abstract: [
    This introductory lecture outlines the goals and structure of CS61B (Data Structures). We motivate algorithmic efficiency beyond basic programming, survey core data structures (lists, trees, hash tables, graphs) and fundamental algorithms (sorting and searching), and explain why Java is used as a vehicle rather than the focus. We also preview the tooling and workflow for large programs, including Git, IntelliJ IDEA, and JUnit, as well as collaboration expectations, academic integrity, and course logistics (labs, projects, discussions, office hours, grading, and slip days). The lecture sets expectations for writing code that runs efficiently and for developing reliable software quickly with good design practices and professional tools.
  ],
  keywords: (
    "Data Structures",
    "Algorithms",
    "Java",
    "Efficiency",
    "Asymptotic Analysis",
    "Sorting",
    "Recursion",
    "Trees",
    "Git",
    "IntelliJ IDEA",
    "JUnit",
    "Projects",
    "Pair Programming",
    "Academic Integrity",
    "Logistics",
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

#titled-block(title: [Terminology])[

  - Data Structures → 数据结构
  - Algorithms → 算法
  - Asymptotic Analysis → 渐进复杂度分析
  - Bytecode → 字节码
  - Class file → class 文件
  - Static typing / static type checking → 静态类型 / 静态类型检查
  - Integrated Development Environment (IDE) → 集成开发环境（IDE）
  - Office hours → 办公时间
  - Clobber policy → 覆盖规则（期末覆盖期中）
  - Pacing points → 参与加分（pacing points）
  - Rubber duck debugging → 橡皮鸭调试
  - Over-collaboration → 过度协作
  - Center for Student Conduct → 学生行为中心（Center for Student Conduct）
  - IntelliJ IDEA → IntelliJ IDEA
]

= Slide 01

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0001.jpg"),
  caption: [Lecture 1 Slide 01],
)

主持人：我现在应该可以把幻灯片放上去了。点讲座标题就能看到幻灯片——我刚刚拿到并已经上传，抱歉来得有点晚。本地测试过，一切正常。大家好！如果你旁边有空座位，请举手示意。另外提醒一下：消防部门对场地要求非常严格，如果我们违反消防安全规范，可能会被罚大约10万美元。

Host: I think I can get the slides up now—click the lecture title to see them. I just got the slides and pushed them, sorry for the delay. I tested locally and things look good. Hi everyone! If you have an empty seat next to you, please raise your hand. Also note: the fire marshal is strict; if we violate the fire safety code, we could be fined about \$100,000.

= Slide 02
#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0002.jpg"),
  caption: [Lecture 1 Slide 02],
)

坐在过道的同学请尽量找到座位，过道就坐不符合消防规定。如果你愿意自掏腰包付10万美元罚款那当然可以留下，否则请尽快入座。继续保持举手，方便他人找到空位。我们还在确认一些时间安排；Zoom 也已经开启，让线上同学入会。现在共享屏幕，用我的主屏就好。欢迎来到 CS61B！Zoom 的同学能听到我们吗？很好。

For those sitting in the aisle: that’s not allowed by the fire safety code, so please move to seats—unless you’re willing to pay the\$100,000 fine. Keep your hands up so others can find open seats. We’re still finalizing some scheduling; Zoom is on and we’re admitting attendees. Let’s also share the screen—use my home screen. Welcome to CS61B! Zoom chat, can you hear us? Excellent.


= Slide 03

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0003.jpg"),
  caption: [Lecture 1 Slide 03],
)

在开始前，先快速介绍一下这门课：很多人听说 61B 是“教 Java”的课，但 Java 只是我们在前几周用来引入新概念的载体，并非课程核心。61A 的目标是“怎么写出一个能跑的程序”；而 61B 更关注“如何高效地编码”。这包括两方面：一是让程序运行更快（通过选择合适的算法与数据结构）；二是让你更快地把程序写出来（通过良好的设计与专业工具）。

还记得 61A 里那个指数时间的递归 Fibonacci 吗？那样的实现连第 40 项都很吃力。本课将转向能算到十万位、甚至百万位的思路：我们将讨论更优的算法（例如不同的排序算法）。我们将讨论数据结构（在很多问题里都非常有用的“工具”）。

除编写运行快速的代码之外，我们也强调开发效率：如何在大约一小时内写出高质量代码，如何设计并搭建大型的程序，以及如何与伙伴协作。我们会使用很多业界常见的编程工具：Git、IntelliJ IDEA、JUnit 等。

我们假设你已经具备扎实的编程基础（例如修过 61A）：面向对象、递归、链表、树等。前几次作业会帮助你把 61A 的知识捡起来，让大家尽快在同一节奏上学习。

Before we get started, a quick overview of how this class works. You may have heard CS61B is a “Java course,” but Java is mainly a vehicle in the first few weeks to introduce new concepts; it is not the core. In 61A you learned how to write programs that work. In 61B we focus on coding efficiently—both writing programs that run faster (via the right algorithms and data structures) and writing programs faster (via good design and professional tooling).

Remember the exponential-time recursive Fibonacci from 61A that struggled past n≈40? Here we look at approaches that scale to the hundred-thousandth or even millionth position: choosing better algorithms (e.g., various sorting methods) and the right data structures—general-purpose tools that show up across many problems.

Beyond runtime efficiency, we emphasize development efficiency: writing meaningful code in about an hour, designing and building larger programs, and collaborating with partners. We will use a simplified version of an industry-style toolchain: Git, IntelliJ IDEA, and JUnit.

We assume a solid programming foundation (e.g., from 61A): object-oriented programming, recursion, lists, and trees. Early assignments refresh that background to get everyone up to speed.

= Slide 04

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0004.jpg"),
  caption: [Lecture 1 Slide 04],
)

接下来，我们会逐步覆盖“酷”的数据结构，并说明它们为何在面试与实际工程中如此重要。除此之外，我们常说 61B 是在伯克利你会修到的最重要的课程之一，因为它系统地训练“如何让程序更快、让开发更快”——这些能力既是后续课程的基础，也是工业界的日常。

除基础内容外，我们还会涉及很多“有趣的数学与分析”：例如渐进复杂度分析（asymptotic analysis）、动态数组扩容、2–3 树与红黑树（它们是被设计来保持平衡的特殊树结构）、图论，以及期末会提到的 P 与 NP 等主题（若你能解决，那可是百万美元难题）。更重要的是，我希望你在课程结束时，具备“独立构建想要的任何程序”的能力。

We’ll then cover a number of “cool” data structures and explain why they matter in interviews and real engineering. Beyond that, we often say CS61B is one of the most important courses you’ll take at Berkeley: it systematically trains you to make programs faster and development faster—skills foundational to later courses and everyday industry practice.

Beyond the basics, we will also cover “fun math and analysis,” including asymptotic analysis, dynamic array resizing, 2–3 trees and red-black trees (balanced tree structures), graph theory, and, at the end, topics like P vs NP (a million-dollar problem if you can solve it). Most importantly, by the time you leave this course, I want you to be able to build whatever program you want.

= Slide 05

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0005.jpg"),
  caption: [Lecture 1 Slide 05],
)

教师介绍（Josh）：我录制过不少 61B 的视频——你们可能会在课外资料里看到我。我自 2014 年起在伯克利任教；本科在德州大学奥斯汀分校，第一门计算机课其实是在伯克利读研时才上的。曾在普林斯顿任教并学习了如何讲授数据结构。去年在荷兰做学术休假。如今是我第 11 次教授 61B（与上次间隔两年）。我参与了课程设计（多数作业与项目）。学期初主要由我讲授，之后与 Justin 交替。

Instructor intro (Josh): I recorded many of the 61B videos you may see. I’ve been at Berkeley since 2014; I was an undergrad at UT Austin and didn’t take my first CS class until grad school here. I taught at Princeton (where I learned to teach data structures). I was on sabbatical in the Netherlands last year. This is my 11th time teaching 61B (after a two-year break). I designed much of the course, including most homeworks and projects. I’ll teach the early part, then Justin and I will switch off.

= Slide 06

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0006.jpg"),
  caption: [Lecture 1 Slide 06],
)

教师介绍（Justin）：自 2022 年起担任讲师，本硕都在伯克利（数学 + 计算机科学双学位，之后第五年硕士）。这学期是我第 5 次教授 61B。我的办公时间：周二、周四 12:00–13:30（Soda 329，将在 Slides 中补充）。现在做个小调查：你为何选择 61B？常见动机包括实习/面试需要、搭建项目、提升面向对象编程能力等。我们也会做大量分组项目，建议大家相互认识。

Instructor intro (Justin): I’ve been a lecturer since 2022; BA/BS (Math + CS) and a 5th-year Master’s at Berkeley. This is my 5th time teaching 61B. Office hours: Tue/Thu 12:00–1:30 (Soda 329; will add to the slides). Quick survey: Why are you taking 61B? Common reasons include internships, building projects, and improving OOP skills. We’ll do lots of group work, so please get to know each other.


= Slide 07

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0007.jpg"),
  caption: [Lecture 1 Slide 07],
)

年级与背景调查：新生/二年级/三年级/四年级/研究生等都有；专业覆盖 CS、数据科学、数学、物理等。编程经历也很分散：修过 61A / CS88、E7，使用过 Java/Python/C/C++/JavaScript 等。课堂上会鼓励与同学交流，后续部分环节将采用配对/小组合作。

Cohort survey: We have freshmen, sophomores, juniors, seniors, grads; majors include CS, Data Science, Math, Physics, etc. Programming backgrounds vary: 61A/CS88, E7, Java/Python/C/C++/JavaScript, and more. Please talk to each other; later parts of the course will involve partners or small groups.

= Slide 08

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0008.jpg"),
  caption: [Lecture 1 Slide 08],
)

现在，让我们继续看一些快速的后勤安排。

课程接下来会进入具体的课程政策、作业与项目、考试与评分、协作与学术诚信、助教与办公时间、以及开发环境设置等后勤安排。请在课程官网查看完整政策与日程，并按要求准备环境与工具链。

Now, let's go ahead and see some quick logistics.

Next, we’ll move into course policies, assignments and projects, exams and grading, collaboration and academic integrity, staff and office hours, and environment setup. Please refer to the course website for full policies and schedule, and prepare your environment and toolchain accordingly.

= Slide 09

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0009.jpg"),
  caption: [Lecture 1 Slide 09],
)

选课与平台加入：我们无法直接控制正式选课流程；如需入课许可，请联系所属专业的导师/顾问。我们会把同学手动加入课程平台（每天/隔天处理一次）。请不要发个人邮箱催促添加；若提交加课两三天后仍未加入，再发邮件至课程组邮箱（cs61b\@berkeley.edu）。

Enrollment/platform adds: We don’t directly control enrollment. Contact your major advisor for enrollment issues. We manually add students to course platforms (daily or so). Don’t email us personally; if it’s been more than two or three days since you joined and you’re still not added, email the course staff (cs61b\@berkeley.edu).


= Slide 10

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0010.jpg"),
  caption: [Lecture 1 Slide 10],
)

授课与学习方式：周一/三/五线下授课，同时通过 Zoom 直播。真正的学习主要发生在“做”中：项目、实验、作业会提供精心设计的问题，用于训练你自行解决问题的能力；课堂更多用于引导与总览。你不会从讲座中学到太多，因为你会通过自己动手做学到更多。

Lectures and learning modes: We meet Monday/Wednesday/Friday in person and also stream on Zoom. Most learning happens by doing: projects, labs, and homeworks present interesting, useful problems to train your problem-solving. Lectures provide introduction and framing. You won't be learning too much from the lectures you'll be learning a lot more through doing it yourself.

= Slide 11

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0011.jpg"),
  caption: [Lecture 1 Slide 11],
)

课程的三个阶段：Phase 1（起步期，节奏快）：工具链与基础（Java、Git、IntelliJ IDEA），个人独立完成；本周五就有作业截止。随后进行第一次期中考试。Phase 2（数据结构核心期）：仍以个人编码为主，主题更新较快。Phase 3（学期末/春假后）：算法与综合项目，课堂节奏放缓，留出更多时间做期末大项目（几乎无起始代码，配对完成）；在这个阶段，你们不会从讲座中学到那么多，你们更多是通过自己动手来学习。

Three phases: Phase 1 (fast ramp-up): tools and foundations (Java, Git, IntelliJ IDEA), solo work; homework due this Friday; then the first midterm. Phase 2 (core data structures): still mostly solo coding; topics move at a brisk pace. Phase 3 (post–spring break): algorithms and a comprehensive final project (almost no starter code), done in pairs; lecture pace slows to give you time to build. At this stage, you won't learn so much from lectures. You will learn more by doing it yourself.

= Slide 12

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0012.jpg"),
  caption: [Lecture 1 Slide 12],
)

评分构成：
- 低负担项：每周问卷、课程评估（应拿满）。
- 高负担项：作业、实验、项目（投入到位应接近满分）。
- 考试：难度较高，目标均分约 65%。

考试政策与“clobber”：若期末成绩高于期中，则用期末“覆盖”期中分数。若考试平均分低于 65%，我们会下调满分上限，使班级均分回到 65%（说明试题过难）。

参与加分（pacing points）：参加讨论/实验/讲座可获得少量额外加分；不参加不会被扣分。加分仅在 B− 及以下区间生效——如果你声称“自己更适合不来上课的学习方式”，那需要用足够高的成绩来证明。

阈值说明：B 到 B+ 的阈值设为“考试 65% 左右（约等于中位数）+ 其它部分 95%”。详情见课程网站的政策页。提问时间：有问题我们再继续。

Grading components:
- Low-effort points: weekly surveys and course evaluations (you should earn most/all).
- High-effort work: homeworks, labs, projects (near 100% if you put in the work).
- Exams: challenging; target average around 65%.

Exam policy and clobber: If your final exam score is higher, it will clobber (replace) your midterm scores. If the exam average is below 65%, we will reduce the maximum score so the class average is 65% (indicating an overly hard exam).

Pacing points (attendance EC): Small extra credit for attending discussion/lab/lecture; no penalty for non-attendance. These points only count up to a B−. If you claim you learn best without attending, you must demonstrate it by scoring high enough without those points.

Thresholds: The B-to-B+ threshold is set to around 65% on exams (near the median) and 95% on everything else. See the course policies page for full details. Any questions before we move on?


= Slide 13

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0013.jpg"),
  caption: [Lecture 1 Slide 13],
)

学术诚信（开场）：请不要作弊。去年我们大约有一百起学术不端，多数来自项目抄袭；有些与从公开仓库/生成式工具拷贝解法相关。接下来会解释常见动机与风险，以及本课的合作与使用政策。

Academic integrity (intro): Please don’t cheat. Last year we had around 100 cases, mostly project copying; some were related to copying solutions from public repos or using generative tools. Next we’ll discuss common motivations and risks, and this course’s collaboration and tool-use policies.

= Slide 14

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0014.jpg"),
  caption: [Lecture 1 Slide 14],
)

学术诚信（动机与过度协作）：常见的“作弊动机”包括三类——（1）无心之过（不了解/未遵守合作规则）；（2）以为通过作弊能理性地获得更高分（少见）；（3）到死线前情急之下的非理性行为（常见）。我们的核心理念是“最大化学习增量”。任何可能让他人在未真正掌握内容的情况下获得非零分的行为，均视为“过度协作”。请牢记：本课并非“Java 课”，Java 只是学习数据结构与算法设计的载体。向同学直接“给出解法思路”、只让对方自行写 Java 属于违规。

不允许的行为（部分）：不得参考/持有他人代码或网上代码；不得让 LLM（如 ChatGPT、GitHub Copilot 等）为你“设计算法/解法”（仅在语法层面的小帮助属灰色地带，使用需注明来源且务必谨慎）；不得与非项目伙伴合作到产出“相同解法”。允许的上限：仅限高层讨论（把问题拆成 2–3 个子问题），或“橡皮鸭调试”（把问题讲给一个“听众”以理清思路）。

#titled-block(title: [橡皮鸭调试])[
  你只需要对着小黄鸭说话，解释你的问题，你就会神奇地学会如何解决问题，因为你试图向别人解释它。

  橡皮鸭调试的效果总是出奇地好。
]

Academic integrity (motivation and over-collaboration): Common “cheating motivations” include (1) accidental violations (not knowing/ignoring rules), (2) a mistaken belief that cheating is rationally beneficial (rare), and (3) last-minute desperation (common). Our philosophy is to maximize learning. Any action that lets someone earn nonzero credit without learning is “over-collaboration.” Remember: this is not a “Java course”; Java is just a vehicle for data structures and algorithm design. Telling a friend the core solution and letting them “write the Java” is misconduct.

Prohibited (partial): Do not use a friend’s solution or online code. Do not have an LLM (e.g., ChatGPT, GitHub Copilot) design the algorithm for you (syntax-only nudges sit in a gray zone and require citation; be very careful). Do not work with non-partners in ways that yield the same underlying solution. Allowed ceiling: high-level discussion (decomposing into 2–3 subproblems) and “rubber duck debugging.”

= Slide 15

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0015.jpg"),
  caption: [Lecture 1 Slide 15],
)

后果与侦测：一旦判定作弊，相关作业将记 0 分，并上报“学生行为中心（Center for Student Conduct）”，后续可能有相应处分。我们使用健全的程序相似性检测，千人课堂也难以“蒙混过关”。重命名变量、微调行序、先抄再“改一改”等都无效。LLM 滥用在以往学期曾引发大规模案件，请勿以身试法。更重要的是：项目阶段不练手，考试（相对较难）会直接吃亏。

Consequences and detection: Cheating yields an automatic zero and referral to the Center for Student Conduct. We use robust program similarity checks; a thousand-student class doesn’t hide misconduct. Variable renaming, line shuffles, “copy-then-tweak,” etc., don’t work. LLM misuse has triggered large incident waves in prior terms—don’t do it. Practicing on projects is crucial for the (hard) exams.

= Slide 16

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0016.jpg"),
  caption: [Lecture 1 Slide 16],
)

避免“情急之下”的非理性作弊：请提前计划、提早开工、预留缓冲、接受“卡住—解卡”的自然过程；越临近死线，办公时段越拥挤。本学期因预算缩减，助教办公时段约为常规的 80%。若你落后了，请及时联系，我们会在“保证学习质量”的前提下尽可能提供支持。

Avoid last-minute desperation: Plan ahead, start early, budget buffer time, and plan for getting stuck and unstuck. Office hours get crowded near deadlines. TA hours are around 80% of usual this term. If you’re falling behind, let us know; we’ll support you as long as we can maintain learning outcomes.

= Slide 17

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0017.jpg"),
  caption: [Lecture 1 Slide 17],
)

延期与迟交：前 1–5 周时间更严格，但可通过 Beacon 申请延期；个别情形可追溯处理，最好提前申请以便规划。若情形超出标准延期范围，请与我们沟通；只要不影响你对核心内容的掌握，我们会尽量灵活，帮助你避免因焦虑而走向不当协作或作弊。

Lateness and extensions: Weeks 1–5 have stricter timing, but you may request extensions via Beacon. Some retroactive extensions are possible; request ahead when you can. If circumstances exceed standard policies, contact us; as long as learning stays on track, we’ll try to be flexible so you don’t resort to misconduct.

= Slide 18

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0018.jpg"),
  caption: [Lecture 1 Slide 18],
)

= Slide 19

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0019.jpg"),
  caption: [Lecture 1 Slide 19],
)

让我们开始写第一个 Java 程序：假设你熟悉 Python（或 E7/61A/Data 8），我们先并排对照 Python 与 Java 的“Hello, World”。部分链接稍后会补齐。我们先在文本编辑器里写两个小程序进行对比。

Let’s start with our first Java programs: Assuming most of you have seen Python (E7/61A/Data 8), let’s compare “Hello, World” in Python versus Java side by side. Some links will be made live shortly. We’ll write two small programs in a text editor and compare.

= Slide 20

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0020.jpg"),
  caption: [Lecture 1 Slide 20],
)

在 Java 中，裸写 print 会报错：“需要 class/interface/enum/record”。除非使用极新的特殊特性，Java 程序必须从“类(class)/接口(interface)/枚举(enum)”之一开始。我们创建 `public class HelloWorld`，随后还需提供入口 `main` 方法，否则会提示“未找到 main 方法”。

In Java, writing a bare print triggers an error: “class/interface/enum/record expected.” Unless using special new features, every Java program must begin with a class/interface/enum. We create `public class HelloWorld` and also need a `main` method; otherwise we get “main method not found.”

= Slide 21

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0021.jpg"),
  caption: [Lecture 1 Slide 21],
)

打印语句与“冗长”印象：使用 `System.out.println("Hello World")` 并以分号结尾。Java 相对冗长，因为 Java 代码需要以各种方式组织，有许多“规范/约束”，这种“规范/约束”有助于大型程序的组织与安全。有很多严格的规则是好的，对吧，我们不想要太多自由，至少在编写程序时是这样的。你可能注意到 Java 的运行时间看似更久，这不是因为 Java 运行慢，这是因为 Java 的启动开销；就算法执行而言，Java 往往比 Python 更快。

Printing and verbosity: Use `System.out.println("Hello World");` and end with a semicolon. Java is relatively verbose because Java code needs to be organized in various ways, and there are many "specifications/constraints" that help with the organization and security of large programs. It's good that there are a lot of strict rules, right, we don't want too much freedom, at least when it comes to writing programs. You may notice that Java seems to run longer, not because Java is slow, but because of Java's startup overhead; Java tends to be faster than Python in terms of algorithm execution.

= Slide 22

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0022.jpg"),
  caption: [Lecture 1 Slide 22],
)

结构观察：

+ Java 中“一切皆类”；
+ 代码块以花括号分隔；
+ Java 中的所有语句都以分号结尾，这样 Java 就知道一个语句在哪里开始，在哪里结束。显然 Java 与 Python 的自由脚本式不同，Java 要求显式的结构化组织。
+ Java 代码为了运行，必须放在 ```java public static``` 里面。

Structural observations:

+ All code in Java belongs to a class;
+ Code blocks are enclosed in curly braces;
+ All statements in Java end with a semicolon, which tells Java where a statement starts and ends. This is different from Python’s free-form scripting, where statements are free-form and can be interleaved with other code.
+ Java code must be placed inside ```java public static``` blocks to be executed.

= Slide 23

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0023.jpg"),
  caption: [Lecture 1 Slide 23],
)

第二个示例：Hello Numbers。

The second example: Hello Numbers.

= Slide 24

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0024.jpg"),
  caption: [Lecture 1 Slide 24],
)

Python 可直接写：

```python
x = 0;
while x < 10:
    print(x)
    x = x + 1
```

Java 需先定义类与 `main`，并在 `while (x < 10)` 等处使用括号与分号等语法细节（细节在 HW0 说明）：

```java
public class HelloNumbers {
    public static void main(String[] args) {
        int x = 0;
        while (x < 10) {
            System.out.println(x);
            x++;
        }
    }
}
```

Python can write:

```python
x = 0
while x < 10:
    print(x)
    x = x + 1
```

Java requires defining a class and `main` method, and using parentheses and semicolons in `while (x < 10)` (details in HW0).

```java
public class LargerDemo {
    public static int larger(int x, int y) {
        if (x > y) {
            return x;
        } else {
            return y;
        }
    }
    public static void main(String[] args) {
        int a = 5;
        int b = 10;
        int result = larger(a, b);
        System.out.println("The larger number is " + result);
    }
}
```

= Slide 25

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0025.jpg"),
  caption: [Lecture 1 Slide 25],
)

变量声明与类型：Java 要求在使用变量前“声明其存在并指定类型”（如 `int x;`）。类型一经声明不可变。把字符串赋给 `int` 会在编译时报“类型不兼容”。

Variable declaration and types: Java requires variables to be declared with a specific type before use (e.g., `int x;`). The type never changes. Assigning a string to an `int` yields a compile-time “incompatible types” error.

= Slide 26

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0026.jpg"),
  caption: [Lecture 1 Slide 26],
)

静态类型语言与静态类型检查：静态类型语言的许多错误在“运行前”就被编译器阻止（如把字符串与整数相加）。静态类型牺牲了部分灵活性，但在构建大型系统时显著减少“运行期踩坑”。

Static typing: Many errors are caught before running (e.g., adding a string to an integer). Static type checking trades some flexibility for fewer runtime landmines when building large systems.

= Slide 27

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0027.jpg"),
  caption: [Lecture 1 Slide 27],
)

= Slide 28

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0028.jpg"),
  caption: [Lecture 1 Slide 28],
)

当你在构建软件系统而不是在进行原型验证时，静态类型的语言会很棒，它使软件开发变得不那么烦人。

Static types of language are great when you're building a software system rather than prototyping, and it makes software development less annoying.

= Slide 29

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0029.jpg"),
  caption: [Lecture 1 Slide 29],
)

第二个示例所表达的重要的东西：

+ 在 Java 变量被使用之前，它们必须被声明。
+ Java 变量有一个特定的类型。
+ 那个类型永远不能改变。这就是为什么这些类型被称为静态类型，因为它们是静态的。
+ 类型在代码运行之前被验证。这也被称为静态类型检查。

The second example highlights the importance of static typing:

+ Variables must be declared before use in Java.
+ Java variables have a specific type.
+ The type cannot change. This is why these types are called static, because they are static.
+ Types are checked before code runs. This is called static type checking.

= Slide 30

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0030.jpg"),
  caption: [Lecture 1 Slide 30],
)

第三个示例是函数。

The third example is about functions.

= Slide 31

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0031.jpg"),
  caption: [Lecture 1 Slide 31],
)

= Slide 32

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0032.jpg"),
  caption: [Lecture 1 Slide 32],
)

= Slide 33

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0033.jpg"),
  caption: [Lecture 1 Slide 33],
)

函数（方法）定义：示例 `larger(x, y)`。

在 Python 中是这样的：

```python
def larger(x, y):
    if x > y:
        return x
    else:
        return y
```

在 Java 中需声明参数类型与返回类型（如 `public static int larger(int x, int y)`）。具体如下：

```java
public class LargerDemo {
    public static int larger(int x, int y) {
        if (x > y) {
            return x;
        } else {
            return y;
        }
    }
    public static void main(String[] args) {
        int a = -5;
        int b = 10;
        int result = larger(a, b);
        System.out.println("The larger number is " + result);
    }
}
```

Java 函数灵活性较低，但定义更精确，这让“定义域/值域”清晰（例如两整数→整数），但不如动态语言灵活，这是一种权衡，但在构建大型系统时，这种静态类型检查非常有用。

同名不同参数列表可通过“方法重载”处理（后续几周将讲解，亦会涉及泛型与 `Comparable`）。

Function definition: Example `larger(x, y)`.

In Python, it's like this:

```python
def larger(x, y):
    if x > y:
        return x
    else:
        return y
```

In Java, we need to declare the parameter types and return type (e.g., `public static int larger(int x, int y)`). More specifically:

```java
public class HelloNumbers {
    public static int larger(int x, int y) {
        if (x > y) {
            return x;
        } else {
            return y;
        }
    }
    public static void main(String[] args) {
        int a = -5;
        int b = 10;
        int result = larger(a, b);
        System.out.println("The larger number is " + result);
    }
}
```

Java functions are less flexible, but more precise in defining the domain and range (e.g., two integers → integer), which is a trade-off between flexibility and clarity. This is a compromise, but in building large systems, static type checking is very useful.

Overloading functions with different parameter lists can be handled by “method overloading” (which will be discussed in the next few weeks, and will also touch on generics and `Comparable`).

= Slide 34

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0034.jpg"),
  caption: [Lecture 1 Slide 34],
)

= Slide 35

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0035.jpg"),
  caption: [Lecture 1 Slide 35],
)

第三个示例所表达的重要的东西：

+ 在 Java 中，函数必须是类的一部分。不像 Python，函数可以被定义在全局作用域，形象点说就是函数悬浮在虚空中。在第三个例子中，`larger` 定义在 `LargerDemo` 类中，即它是 `LargerDemo` 类的一部分，它不能脱离 `LargerDemo` 而存在。如果另一个类想要使用它，另一个类就必须对 `LargerDemo` 说：请把你的 `larger` 函数给我。
  - 作为类的一部分的函数有时被称为方法。因此，Java 中的所有函数都是方法。
+ 要在 Java 中定义函数，我们当前使用的是 ```java public static``` 关键字。我们很快会看到其他方法。
+ 函数的所有参数都必须有声明的类型，而且函数必须返回特定的类型。
+ Java 中的函数只会返回一个值。如果你需要返回更多东西，你需要声明一个新类型，它可以将一堆东西捆绑在一起。

The third example highlights the importance of static typing:

+ Functions must be defined within a class in Java. Unlike Python, functions can be defined globally, floating in the void. In the third example, `larger` is defined within the `HelloNumbers` class, which means it is part of the `HelloNumbers` class and cannot exist without it. If another class wants to use it, it must ask `HelloNumbers` to give it to them.
  - Functions that are part of a class are called methods.
+ In Java, we use the `public static` keyword to define functions. We'll see other methods later.
+ All parameters in a function must have a declared type, and the function must return a specific type.
+ Java functions only return one value. If you need to return more than one thing, you need to declare a new type that can bundle them together.

= Slide 36

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0036.jpg"),
  caption: [Lecture 1 Slide 36],
)


= Slide 37

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0037.jpg"),
  caption: [Lecture 1 Slide 37],
)
编译与解释（两阶段流程——先编译后解释）：了解编译与解释是了解类型检查如何工作的关键。Java 源文件先由编译器编译为字节码（`.class` 文件），随后由解释器（解释器是世界上工程设计最精良的虚拟机之一，用于运行字节码，它进行一些疯狂的优化来使代码非常快，并且这个解释器能够运行来自多种语言的代码，因为它执行的实际是字节码，只要高级语言能够编译成这种字节码，就可以在解释器上执行）执行。字节码是较易优化的“中间语言”，细节不必深究，但它作为 JVM 的“通用语”（lingua franca）可承载多种语言（如 Scala 等）编译后的产物。

为何要产出 `.class` 文件：
- 已通过编译器的类型检查，避免“把字符串放进整数盒子”之类的问题；
- `.class` 文件更简单、更易于高效执行、更快地执行（超出本课的教学范围）；
- `.class` 文件便于保护你的知识产权，因为分发的是 `.class` 文件（一定程度“保护源码”——尽管可逆向/反编译为近似 Java，但并非一字不差）。
相关延伸：这些内容在 61C 与 CS164 中会更深入讨论。

Compilation and interpretation (two-stage process): Understanding compilation and interpretation is crucial to understanding how type checking works. Java source files are first compiled into bytecode (`.class` files), which are then executed by an interpreter (an interpreter is a world-class virtual machine designed to run bytecode, which performs some crazy optimizations to make code very fast, and it can run code from multiple languages because it executes actual bytecode, which is only possible if the high-level language can be compiled into such bytecode). Bytecode is a relatively easy-to-optimize “intermediate language”, but the details are not necessary to understand, and it serves as the “common language” of the JVM (lingua franca).

Why produce `.class` files:
- Type-checked by the compiler, avoiding issues like “putting a string in an integer box”;
- `.class` files are simpler, easier to execute efficiently, and faster (beyond the scope of this course);
- `.class` files make it easy to protect your intellectual property, because they distribute `.class` files (at least somewhat “protect the source”—decompiling to approximate Java is not a one-for-one replacement, but it’s still a good start).
Related extensions: These topics will be discussed in more depth in 61C and CS164.

= Slide 38

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0038.jpg"),
  caption: [Lecture 1 Slide 38],
)

= Slide 39

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0039.jpg"),
  caption: [Lecture 1 Slide 39],
)

静态类型优点（课堂讨论汇总）：
- 始终“知道事物的类型”，更易于理解代码；
- 用户输入造成的问题更少；
  - 可能的错去会少得多；
- 早期错误发现，减少运行期陷阱，通常意味着更少的缺陷，IDE 也能即时提示问题，即你在写代码时就知道一些错误并且能够修复它；
- 某些语言甚至进一步避免空指针等问题（Java 仍允许）。

静态类型缺点：
- 灵活性较低（不能把 `x` 改成 “horse” 等）；
- 使语言更加冗长；
- 语法更复杂、更“挑剔”，当涉及特定性质的类型与泛型时尤其如此。

Advantages of static typing (class discussion summary):
- Always “know the type of things,” making code easier to understand;
- Fewer issues from user input;
  - Fewer possible mistakes;
- Early error detection, reducing runtime traps, usually meaning fewer bugs; IDEs can also provide immediate feedback, so you know about some errors as you write code and can fix them;
- Some languages go further to avoid issues like null pointers (Java still allows them).

Disadvantages of static typing:
- Less flexibility (can’t change `x` to “horse,” etc.);
- Makes the language more verbose;
- More complex and “picky” syntax, especially when involving specific types and generics.

= Slide 40

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0040.jpg"),
  caption: [Lecture 1 Slide 40],
)

= Slide 41

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0041.jpg"),
  caption: [Lecture 1 Slide 41],
)

工作流演示（命令行）：`javac HelloWorld.java` 生成 `HelloWorld.class`；`java HelloWorld` 运行。class 文件可打开（可读性较差的字节码），过去学期曾用命令行为主；也可用带快捷运行的文本编辑器或笔记本环境。

Workflow demo (CLI): `javac HelloWorld.java` produces `HelloWorld.class`; `java HelloWorld` runs it. You can open the class file (bytecode, not very readable). We used to do command-line workflows; fancy editors and notebook environments also exist.

= Slide 42

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0042.jpg"),
  caption: [Lecture 1 Slide 42],
)

= Slide 43

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0043.jpg"),
  caption: [Lecture 1 Slide 43],
)

IDE 建议：本课建议使用 IntelliJ IDEA（工业级 IDE）。优势包括：自动补全、连续语法检查、从 class 反编译回 Java 视图（反编译展示）、与测试代码的紧密整合、错误位置的即时报错（“红色波浪线”）。请尽快开始 Homework 0 并完成开发环境配置。

IDE suggestion: Use IntelliJ IDEA (industrial-strength IDE). Benefits: autocomplete, continuous syntax checking, decompiling class files to Java views, tight integration with tests, and immediate error feedback (red squiggles). Please start Homework 0 and finish your environment setup.

= Slide 44

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0044.jpg"),
  caption: [Lecture 1 Slide 44],
)

= Slide 45

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0045.jpg"),
  caption: [Lecture 1 Slide 45],
)

本课程建议你使用 IntelliJ IDEA 作为你的主要开发环境，但你实际上可以使用你擅长的 IDE，例如 Visual Studio Code 等。

This course suggests that you use IntelliJ IDEA as your primary development environment, but you can also use your preferred IDE, such as Visual Studio Code.

= Slide 46

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0046.jpg"),
  caption: [Lecture 1 Slide 46],
)

= Slide 47

#figure(
  image("images/[61B-Sp25]-Lecture-1---Introduction/[61B Sp25] Lecture 1 - Introduction_page-0047.jpg"),
  caption: [Lecture 1 Slide 47],
)

课堂收尾与问答（部分）：会提供出勤相关的表单/问卷；多数同学已掌握 Python/数据 8 相关背景。课堂小插曲：有人问到常用语言（Python 等）与流行度榜单。

课堂杂项与提醒：有同学提到遗失水壶；容量与上座情况的调侃（房间容量约 1200，我们略有超员但仍有余量）。

环境配置收尾：关于“导入库/依赖”的短暂技术问题；剩余时间约 5 分钟；个别同学课程编号口误的小插曲；助教/讲师将留守帮助完成 IDE/库导入等设置。

再次强调：请按课程网站指引完成环境搭建与 HW0；遇到配置问题，可在办公时间或讨论课、Ed 论坛寻求帮助。

课程提示：后续将更系统地讲解字节码/JIT/运行时优化与泛型/`Comparable` 等内容；请保持每周节奏，避免靠近死线才开始项目。

结束语：欢迎来到 CS61B。祝你在“让程序更快、让开发更快”的道路上收获满满。

下课与现场技术支持：如需 IDE/库导入等帮助，请在教室前方排队或前往办公时间；线上同学可在 Ed 发帖。

Wrap-up and Q&A (partial): Attendance forms/surveys will be provided; most students have Python/Data 8 background. Side chat: common languages (e.g., Python) and popularity rankings came up.

Miscellany and reminders: A student mentioned a lost water bottle; joking about room capacity and attendance (room ~1200; slightly over but still fine).

Environment setup wrap-up: Brief hiccups around “importing libraries/dependencies”; about five minutes remaining; a minor confusion over course numbers; staff will stick around to help with IDE/library import setup.

Re-emphasis: Follow the course website to complete environment setup and HW0. For configuration issues, seek help in office hours, discussion, or on Ed.

Course tips: We’ll later cover bytecode/JIT/runtime optimizations and generics/`Comparable` in a more systematic way. Keep up weekly to avoid starting projects at the deadline.

Closing: Welcome to CS61B. Here’s to writing faster programs and developing faster.

Dismissal and tech support: If you need help with IDE/library imports, line up at the front or visit office hours. Remote students can post on Ed.
