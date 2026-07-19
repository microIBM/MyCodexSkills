---
name: youzi-48-xinfa
description: "48位A股游资心法索引。基于本地PDF《48位柚子悟道心法》上下册全文OCR蒸馏，并将《著名游资实战交割单》全文OCR/样本证据并入对应人物心法。用于按游资姓名、短线风格、情绪/龙头/打板/低吸/趋势等关键词路由。"
---

# 48位游资心法技能库

> 来源：`E:\storybook\48位柚子悟道心法上册.pdf`、`E:\storybook\48位柚子悟道心法下册.pdf`、`E:\storybook\著名游资实战交割单.pdf`  
> 处理方式：扫描PDF全文OCR + 人工校正主题 + 现有深度skill复用。

## 使用方法

1. 用户点名某位游资时，优先加载表格中的具体skill。
2. 标记为“深度版”的人物已有更完整交割单/语录蒸馏，直接使用原路径。
3. 标记为“心法版”的人物是本次补齐的轻量skill，重点用于框架分析。
4. 个股、板块、行情问题必须先查事实数据，再套用对应心法。
5. 《著名游资实战交割单》不再作为单独skill调用；涉及林疯狂、退学炒股、瑞鹤仙、炒股养家、乔帮主、赵老哥、作手新一时，直接加载人物skill，并在人物skill内使用交割单实证段。
6. 需要回查原始扫描文本时，优先看“全文OCR索引”里的文件和覆盖报告。

## 48人索引

| # | 游资 | 主题 | 版本 | 路径 |
|---|---|---|---|---|
| 01 | 炒股养家 | 洞悉情绪周期 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-qingxu-liu\02-chaoguyangjia\SKILL.md` |
| 02 | Asking | 超短节奏把握 | 心法版 | `02-asking/SKILL.md` |
| 03 | 职业炒手 | 交易的本质 | 心法版 | `03-zhiye-chaoshou/SKILL.md` |
| 04 | 作手新一 | 市场行为的分析 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-longtou-zhanfa\13-zuoshouxingyi\SKILL.md` |
| 05 | 涅盘重升 | 情绪演变的认知 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-qingxu-liu\05-niepanchongsheng\SKILL.md` |
| 06 | 小鳄鱼 | 超短线的核心 | 心法版 | `06-xiaoe-yu/SKILL.md` |
| 07 | 退学炒股 | 一万到千万的蜕变 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-ruozhuanqiang\04-tuixuechaogu\SKILL.md` |
| 08 | 92科比 | 解析情绪周期 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-duli-fengge\03-92biji\SKILL.md` |
| 09 | 赵老哥 | 超短选股要诀 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-longtou-zhanfa\07-zhaolaoge\SKILL.md` |
| 10 | 瑞鹤仙 | 熊市出英雄 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-longtou-zhanfa\29-ruihexian\SKILL.md` |
| 11 | 独孤一箭 | 超短线之王 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-duli-fengge\14-duguyijian\SKILL.md` |
| 12 | 北京炒家 | 专一的首板客 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-daban-gaopin\12-bjchaojia\SKILL.md` |
| 13 | 著名刺客 | 龙头战法执行者 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-duli-fengge\09-zhumingcike\SKILL.md` |
| 14 | 深南哥 | 割肉王 | 心法版 | `14-shennange/SKILL.md` |
| 15 | 江南神鹰 | 落升金字塔 | 心法版 | `15-jiangnan-shenying/SKILL.md` |
| 16 | 深圳板哥 | 简单纯粹 | 心法版 | `16-shenzhen-bange/SKILL.md` |
| 17 | 缠中说禅 | 高手都是哲学家 | 心法版 | `17-chanzhongshuochan/SKILL.md` |
| 18 | 无门问禅 | 势是市场之王 | 心法版 | `18-wumen-wenchan/SKILL.md` |
| 19 | 灯心人 | 你离成功只差十个牛股 | 心法版 | `19-dengxinren/SKILL.md` |
| 20 | 仓促的句号 | 只做已经，不做如果 | 心法版 | `20-cangcude-juhao/SKILL.md` |
| 21 | 小草骑墙 | 假如你坐庄 | 心法版 | `21-xiaocao-qiqiang/SKILL.md` |
| 22 | 葵花宝典 | 输在意淫 | 心法版 | `22-kuihua-baodian/SKILL.md` |
| 23 | 好运2008 | 信念是财富的催化剂 | 心法版 | `23-haoyun2008/SKILL.md` |
| 24 | 善行天助 | 接力高手 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-fangshou-fuli\26-shanxingzhianzhu\SKILL.md` |
| 25 | 徐翔 | 投机的心性 | 心法版 | `25-xuxiang/SKILL.md` |
| 26 | 乔帮主 | 低吸鼻祖 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-longtou-zhanfa\06-qiaobangzhu\SKILL.md` |
| 27 | 不动明王 | 熊市生存之道 | 心法版 | `27-budongmingwang/SKILL.md` |
| 28 | 龙飞虎 | 动态仓位管理 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-fangshou-fuli\18-longfeihu\SKILL.md` |
| 29 | 令狐冲 | 盘感训练和打板技术 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-qingxu-liu\17-linghuchong\SKILL.md` |
| 30 | 万法归宗 | 市场永远是对的 | 心法版 | `30-wanfa-guizong/SKILL.md` |
| 31 | 章盟主 | 趋势追击 | 心法版 | `31-zhangmengzhu/SKILL.md` |
| 32 | 丁一熊 | 长者的智慧 | 心法版 | `32-dingyixiong/SKILL.md` |
| 33 | 榜中榜 | 理解力才是王道 | 心法版 | `33-bangzhongbang/SKILL.md` |
| 34 | 杨永兴 | 短线快刀客 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-qushi-jiedian\08-yangyongxing\SKILL.md` |
| 35 | 艾琳歆 | 抓住大波段的奥秘 | 心法版 | `35-ailinxin/SKILL.md` |
| 36 | 浓野汤人 | 棉花期货大鳄 | 心法版 | `36-nongye-tangren/SKILL.md` |
| 37 | 凡倍无名 | 超短百科全书 | 心法版 | `37-fanbei-wuming/SKILL.md` |
| 38 | 孤独牛背 | 龙头妖股战法 | 心法版 | `38-gudu-niubei/SKILL.md` |
| 39 | 一瞬流光 | 新晋超短线游资 | 深度版 | `C:\Users\haoxi\.codex\skills\youzi-duli-fengge\21-yishunliuguang\SKILL.md` |
| 40 | 太阳连板 | 技法和心法都要硬 | 心法版 | `40-taiyang-lianban/SKILL.md` |
| 41 | 庖丁解牛 | 股市中给自己定位 | 心法版 | `41-paoding-jieniu/SKILL.md` |
| 42 | 糊涂118 | 左侧低吸潜伏 | 心法版 | `42-hutu118/SKILL.md` |
| 43 | 我是K | 交易不需要反人性 | 心法版 | `43-woshi-k/SKILL.md` |
| 44 | 陶永根 | 只要确定的1% | 心法版 | `44-taoyonggen/SKILL.md` |
| 45 | 彭道富 | 风险化解与热点逻辑 | 心法版 | `45-pengdaofu/SKILL.md` |
| 46 | 陈小群 | 情绪合力龙头 | 深度版 | `C:\Users\haoxi\.codex\skills\chen-xiaoqun-skill\SKILL.md` |
| 47 | 创世纪888888 | 控制回撤高手 | 心法版 | `47-chuangshiji888888/SKILL.md` |
| 48 | 葛卫东 | 顺势而为 | 心法版 | `48-geweidong/SKILL.md` |

## 质量说明

- 《著名游资实战交割单.pdf》的7位样本已经并入对应人物心法；不要把交割单当作独立角色skill使用。
- 新增心法版来自《48位柚子悟道心法》章节主题和全文OCR，适合做思维框架，不适合当作逐笔交易证据。
- 原始OCR文件位于 `references/research/`；全文OCR是机器识别稿，重要事实仍需回看PDF校对，不作为逐字引用。
- 48位人物均已生成章节级全文OCR研究摘录；覆盖报告见 `references/research/full-ocr/48-person-chapter-index.md`。

## 全文OCR索引

| PDF | OCR覆盖 | 文件 |
|---|---:|---|
| 《48位柚子悟道心法上册.pdf》 | 275/275页 | `references/research/full-ocr/48_youzi_shang_full_ocr.md` |
| 《48位柚子悟道心法下册.pdf》 | 239/239页 | `references/research/full-ocr/48_youzi_xia_full_ocr.md` |
| 《著名游资实战交割单.pdf》 | 227/227页 | `references/research/jiaogedan/jiaogedan_full_ocr.md` |
| 覆盖报告 | 976/976页 | `references/research/full-ocr/pdf-ocr-coverage.md` |

## 交割单已并入的人物心法

| 人物 | 并入的交割单证据 | 使用路径 |
|---|---|---|
| 林疯狂 | 2016年9个月约10倍、满仓高频切换、山东地矿/深物业A样本 | `C:\Users\haoxi\.codex\skills\youzi-daban-gaopin\16-linfengkuang\SKILL.md` |
| 退学炒股 | 2017年7月26日-8月28日小资金翻倍、金龙羽等弱转强样本 | `C:\Users\haoxi\.codex\skills\youzi-ruozhuanqiang\04-tuixuechaogu\SKILL.md` |
| 瑞鹤仙 | 2012年9月28日-11月8日账户86.5万到155万、沧州大化等样本 | `C:\Users\haoxi\.codex\skills\youzi-longtou-zhanfa\29-ruihexian\SKILL.md` |
| 炒股养家 | 2010年实盘赛、109万到300万、一字板重仓友利控股样本 | `C:\Users\haoxi\.codex\skills\youzi-yangjia-local-deep\SKILL.md` |
| 乔帮主 | 82万到97万、上海莱士低吸/融资样本 | `C:\Users\haoxi\.codex\skills\youzi-longtou-zhanfa\06-qiaobangzhu\SKILL.md` |
| 赵老哥 | 2010年3月-2011年6月、250万到1500万、首板复利样本 | `C:\Users\haoxi\.codex\skills\youzi-longtou-zhanfa\07-zhaolaoge\SKILL.md` |
| 作手新一 | 2017年后从杂乱打板到高质量模式筛选、反包/龙头二波样本 | `C:\Users\haoxi\.codex\skills\youzi-longtou-zhanfa\13-zuoshouxingyi\SKILL.md` |
