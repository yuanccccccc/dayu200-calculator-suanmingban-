/**
 * 简易计算器 - DAYU200 / OpenHarmony 4.0 (API 9 兼容)
 * 主页面: entry/src/main/ets/pages/Index.ets
 *
 * 隐藏彩蛋：赛博算命（界面上无任何入口）
 *   计算器状态下直接键入：
 *     10 位「生日+时辰」如 2005031703 = 2005-03-17 03时
 *     或 12 位「生日+时分」如 200503170257 = 2005-03-17 02:57
 *   按 = 触发：本地排盘（ets/libs/ 移植 bazi-mcp/tyme4ts）
 *     -> 直连 DeepSeek 生成命书批文 -> 全屏阅读页展示。
 *   键入 8 位以上纯数字时按 % 可切换乾造(男)/坤造(女)，默认乾造。
 *   阅读页点正文可放大/缩小字号，按 C 或点 × 返回计算器。
 *   其余任何输入（含 8 位纯数字）都按普通计算器处理，完全无痕。
 */
import http from '@ohos.net.http'
import { calcBazi, BaziLite } from '../libs/baziapi'

// DeepSeek 直连配置（测试版内嵌 key）
const DEEPSEEK_URL = 'https://api.deepseek.com/chat/completions'
const DEEPSEEK_KEY = 'sk-a485abd5f4f04224af2542286f45c601'
const DEEPSEEK_MODEL = 'deepseek-flash'

interface DSMessage {
  role: string
  content: string
}

interface DSReq {
  model: string
  messages: DSMessage[]
  max_tokens: number
  temperature: number
  reasoning_effort: string
}

interface DSRespMessage {
  content?: string
}

interface DSRespChoice {
  message?: DSRespMessage
}

interface DSResp {
  choices?: DSRespChoice[]
  error?: DSRespError
}

interface DSRespError {
  message?: string
}

@Entry
@Component
struct Index {
  @State display: string = '0'
  @State hint: string = '' // 橙色小字：挂起运算 / 乾坤指示 / 推演进度 / 错误提示
  @State gender: number = 0 // 0男(乾造) 1女(坤造)，隐藏开关：% 键在输入 8 位以上数字时切换
  @State baziShort: string = ''
  @State fortuneText: string = ''
  @State busy: boolean = false
  @State fullView: boolean = false // 结果全屏阅读页
  @State bigFont: boolean = false // 阅读页字号（点正文切换）
  @State elapsed: number = 0 // 推演已用时（秒），等待期间显示在提示行
  private firstOperand: number = 0
  private pendingOp: string = ''
  private waitingForSecond: boolean = false
  private timerId: number = -1

  // ---------------- 计算器逻辑 ----------------
  private calc(a: number, b: number, op: string): number {
    switch (op) {
      case '+': return a + b
      case '-': return a - b
      case '×': return a * b
      case '÷': return b === 0 ? NaN : a / b
      default: return b
    }
  }

  private format(n: number): string {
    if (isNaN(n)) return '错误'
    if (!isFinite(n)) return '溢出'
    // 去掉浮点误差尾巴,如 0.30000000000000004
    let s = parseFloat(n.toPrecision(12)).toString()
    if (s.length > 12) s = n.toExponential(6)
    return s
  }

  private current(): number {
    return parseFloat(this.display)
  }

  // ---------------- 隐藏触发识别 ----------------
  // 纯数字 10 位（生日+时辰）或 12 位（生日+时分）且构成合法日期时间 -> 返回时辰 0-23；否则 -1
  private parsePattern(s: string): number {
    if (!/^\d{10}$|^\d{12}$/.test(s)) return -1
    let y = parseInt(s.slice(0, 4))
    let m = parseInt(s.slice(4, 6))
    let d = parseInt(s.slice(6, 8))
    let hh = parseInt(s.slice(8, 10))
    if (y < 1901 || y > 2099 || m < 1 || m > 12 || d < 1 || d > 31) return -1
    if (isNaN(hh) || hh > 23) return -1
    if (s.length === 12 && parseInt(s.slice(10, 12)) > 59) return -1
    return hh
  }

  // ---------------- 输入处理 ----------------
  private inputDigit(d: string) {
    if (this.busy || this.fullView) return
    if (this.display === '错误' || this.waitingForSecond) {
      this.display = d
      this.waitingForSecond = false
    } else if (this.display === '0') {
      this.display = d
    } else if (this.display.length < 12) {
      this.display += d
    }
  }

  private inputDot() {
    if (this.busy || this.fullView) return
    if (this.display === '错误' || this.waitingForSecond) {
      this.display = '0.'
      this.waitingForSecond = false
    } else if (!this.display.includes('.')) {
      this.display += '.'
    }
  }

  private setOp(op: string) {
    if (this.busy || this.fullView) return
    if (this.pendingOp !== '' && !this.waitingForSecond) {
      // 连续运算: 先算出前面的结果
      let r = this.calc(this.firstOperand, this.current(), this.pendingOp)
      this.display = this.format(r)
      this.firstOperand = r
    } else {
      this.firstOperand = this.current()
    }
    this.pendingOp = op
    this.waitingForSecond = true
    this.hint = this.format(this.firstOperand) + ' ' + op
  }

  private equals() {
    if (this.busy || this.fullView) return
    // 隐藏彩蛋：没有挂起运算时，10/12 位合法日期时间 -> 算命；其余一律按普通等号
    if (this.pendingOp === '') {
      let hour = this.parsePattern(this.display)
      if (hour >= 0) {
        this.goFortune(hour)
        return
      }
    }
    if (this.pendingOp === '') return
    let r = this.calc(this.firstOperand, this.current(), this.pendingOp)
    this.display = this.format(r)
    this.pendingOp = ''
    this.firstOperand = 0
    this.waitingForSecond = true
    this.hint = ''
  }

  private clearAll() {
    if (this.busy) return
    if (this.fullView) { // 阅读页按 C = 关闭并清场
      this.closeFortune()
      return
    }
    this.display = '0'
    this.hint = ''
    this.firstOperand = 0
    this.pendingOp = ''
    this.waitingForSecond = false
  }

  private backspace() {
    if (this.busy || this.fullView) return
    if (this.display === '错误' || this.waitingForSecond) return
    this.display = this.display.length > 1 ? this.display.slice(0, -1) : '0'
  }

  private closeFortune() {
    this.fullView = false
    this.fortuneText = ''
    this.baziShort = ''
    this.display = '0'
    this.hint = ''
    this.bigFont = false
  }

  // ---------------- 赛博算命（隐藏） ----------------
  private goFortune(hour: number) {
    let y = parseInt(this.display.slice(0, 4))
    let m = parseInt(this.display.slice(4, 6))
    let d = parseInt(this.display.slice(6, 8))
    this.busy = true
    this.elapsed = 0
    this.hint = '推演中 0s'
    this.timerId = setInterval(() => {
      this.elapsed += 1
      this.hint = `推演中 ${this.elapsed}s`
    }, 1000)

    // 1. 本地排盘（无网络，毫秒级）
    let b: BaziLite
    try {
      b = calcBazi(y, m, d, hour, this.gender)
    } catch (e) {
      this.stopTimer()
      this.busy = false
      this.hint = '排盘失败'
      return
    }
    this.baziShort = b.baziShort

    // 2. 直连 DeepSeek（系统指令 = 子平典籍方法论 + 谶语批文表达，防止术语堆砌与万金油套话）
    let sys = '你是一位以《子平真诠》《穷通宝鉴》《滴天髓》《神峰通考》为方法论根基的老命师，为人写命书批文。你推演时用最严的专业功夫，落笔时如江湖先生断命——谶语判词起句，白话点破收尾，玄之又玄又句句有据。\n' +
      '\n' +
      '【推演纪律——内功，每条必须遵守】\n' +
      '1. 用户消息中以【】标注的排盘数据与本地推演结论（五行力量、日主强弱、穷通调候、喜用神、格局）是分析骨架，不得推翻或无视；你的任务是论证与展开，不是另起炉灶。\n' +
      '2. 每个论断的依据必须落到具体命局：干支、柱位、五行生克、刑冲合会（如年与月相冲、日时天干相合）。禁止脱离命局泛泛而谈。\n' +
      '3. 作用优先级：月令提纲最重 > 日主强弱与寒暖 > 格局成败 > 大运环境 > 刑冲合会引动 > 神煞点缀。\n' +
      '4. 格局须对照给出的成格条件与破格风险逐项论证，明确此命成在何处、损在何处。\n' +
      '5. 十神落到现世生活：印=平台背书/资质文凭/贵人保护；官杀=职位责任/规则压力/合规；财=收入/商业化/资源；食伤=表达/才艺创新/锋芒；比劫=同辈伙伴/竞争分利。\n' +
      '\n' +
      '【表达纪律——落笔，违者重写】\n' +
      '6. 术语一律转译，行话不得出现在正文："正官格""七杀""伤官""食神""建禄""藏干""透干""十神""喜用神""三得""扶抑""调候""中气""通根"等命理行话全部禁用；数字评分与百分比（如三得评分、五行百分比）禁用。须转译成意象或白话，例："伤官见官"→"一身才气锋芒，偏撞上规矩管束，易因言获咎"；"财滋杀"→"钱财反倒喂养了压力，越挣越重"。\n' +
      '7. 市井能懂的词可用：五行金木水火土、干支、生肖、方位、颜色、数字、身强身弱、命硬、担财、官星、财星、文星、桃花、贵人、驿马、行大运——这类词自带江湖气，尽管用。\n' +
      '8. 每节先出一句判词：半文半白，四字或七字成句，可对仗，如谶语；判词之后必须紧跟白话点破，白话要具体到行当、年份、方位、性情，不得空泛。正文一律纯文本，不得出现 **、#、* 等 markdown 符号，重点全靠行文本身。\n' +
      '9. 玄而不空：每句判词须能在其后的白话里落到实处；凡换个八字也成立的恭维话、套话（如"五行平衡注意健康""贵人相助事业有成"），一律删去。\n' +
      '10. 柱位行话转译：白话中不得裸用"年支/月令/时上/日坐/日支"这类柱位词，须转成人生阶段——年柱=祖上与早年，月柱=青年与根基，日支=婚姻宫/中年，时柱=晚年与归宿；判词中可用"时上之水"这类意象，但其后的白话必须点破它指什么。\n' +
      '11. 判词意象自释：判词里每个比喻（如"火被水牵住""金埋土中"）都必须在其后的白话里用大白话再讲一遍，让读者先觉玄、后能懂；只可意会不可言传的句子不要写。\n' +
      '12. 禁江湖保险话："劝晚婚""发不了横财""不宜投机""破财免灾"之类万金油结论，除非恰由此命局推出（并点明是哪步运、哪些年份的依据），否则一律不得出现；婚姻早晚、财的快慢大小，每个命都要有自己的具体年代与说法。\n' +
      '\n' +
      '【输出格式】全文约 500-600 字，如一纸命书批文，分节书写，节名用【】：\n' +
      '【定盘】四句七言诗，总括此命，玄而不空；\n' +
      '【总断】一句判词起头，再两三句白话讲明此命大势、成在何处、损在何处；\n' +
      '【性情】判词 + 白话，真实性情，须含短处；\n' +
      '【财官】判词 + 白话，适合的行当、财的来路与风险，可点方位颜色；\n' +
      '【姻缘】判词 + 白话，感情与人际模式，可点配偶性情；\n' +
      '【行运】判词 + 白话，点出起运后 2-3 步关键大运的具体年龄段与吉凶主题。\n' +
      '末尾单起一行：命由己造，仅供参考。'
    let messages: DSMessage[] = [
      { role: 'system', content: sys },
      {
        role: 'user',
        content: `以下是求测者排盘与本地推演结论（你的推演依据，正文不得直接引用其中的行话与数字）：
${b.summary}

请按系统指令为此命写一纸批文：推演以上述骨架为准并逐项对照成格破格，但落笔时全部转译成谶语判词加白话点破，行话与评分数字不得出现在正文。`
      }
    ]
    let req: DSReq = {
      model: DEEPSEEK_MODEL,
      messages: messages,
      max_tokens: 8000, // flash 是推理模型，medium 思考 + 600字正文，给足余量
      temperature: 0.7,
      reasoning_effort: 'medium'
    }
    let client = http.createHttp()
    client.request(DEEPSEEK_URL, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + DEEPSEEK_KEY
      },
      extraData: JSON.stringify(req),
      connectTimeout: 15000,
      readTimeout: 120000
    }).then((resp: http.HttpResponse) => {
      client.destroy()
      this.stopTimer()
      this.busy = false
      if (resp.responseCode !== 200) {
        this.hint = '解读失败 HTTP ' + resp.responseCode
        return
      }
      let r = JSON.parse(String(resp.result)) as DSResp
      let text = r.choices && r.choices.length > 0 && r.choices[0].message ? r.choices[0].message.content : undefined
      if (text) {
        this.fortuneText = text
        this.fullView = true // 直接进全屏阅读页
        this.hint = ''
      } else {
        this.hint = '解读失败：' + (r.error && r.error.message ? r.error.message : '返回为空')
      }
    }).catch((e: Error) => {
      client.destroy()
      this.stopTimer()
      this.busy = false
      this.hint = '网络错误：' + (e.message || '无法连接 DeepSeek（板子需可上外网）')
    })
  }

  private stopTimer() {
    if (this.timerId >= 0) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
  }

  // ---------------- UI ----------------
  @Builder
  private btn(label: string, bg: ResourceColor, onTap: () => void) {
    Button(label)
      .fontSize(24)
      .fontColor(Color.White)
      .backgroundColor(bg)
      .width('22%')
      .height(72)
      .borderRadius(16)
      .onClick(onTap)
  }

  build() {
    if (this.fullView) {
      // 全屏阅读页：结果不再挤在按键上方的小条里
      Column() {
        Row() {
          Text(this.baziShort)
            .fontSize(22)
            .fontColor('#FF9F0A')
            .layoutWeight(1)
            .maxLines(1)
          Text('×')
            .fontSize(30)
            .fontColor(Color.White)
            .width(48)
            .height(48)
            .textAlign(TextAlign.Center)
            .onClick(() => this.closeFortune())
        }
        .width('100%')
        .padding({ left: 20, right: 12, top: 12 })

        Scroll() {
          Text(this.fortuneText)
            .fontSize(this.bigFont ? 34 : 25)
            .lineHeight(this.bigFont ? 50 : 37)
            .fontColor(Color.White)
            .width('100%')
        }
        .scrollable(ScrollDirection.Vertical)
        .layoutWeight(1)
        .padding({ left: 20, right: 20, top: 8 })
        .onClick(() => { this.bigFont = !this.bigFont }) // 点正文放大/缩小

        Text(this.bigFont ? '点正文缩小' : '点正文放大')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 4 })

        Button('C · 关闭')
          .fontSize(20)
          .fontColor(Color.White)
          .backgroundColor('#A5A5A5')
          .width('60%')
          .height(56)
          .borderRadius(16)
          .margin({ top: 8, bottom: 16 })
          .onClick(() => this.closeFortune())
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
    } else {
      Column() {
        // 显示屏
        Column() {
          Text(this.pendingOp !== '' ? this.hint : (this.hint !== '' ? this.hint : ' '))
            .fontSize(24)
            .fontColor('#FF9F0A')
            .width('100%')
            .textAlign(TextAlign.End)
            .maxLines(1)
          Text(this.display)
            .fontSize(56)
            .fontColor(Color.White)
            .width('100%')
            .textAlign(TextAlign.End)
            .maxLines(1)
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 16, bottom: 12 })
        .layoutWeight(1)
        .justifyContent(FlexAlign.End)

        // 按键区（纯计算器，无任何算命入口）
        Column({ space: 12 }) {
          Row({ space: 12 }) {
            this.btn('C', '#A5A5A5', () => this.clearAll())
            this.btn('←', '#A5A5A5', () => this.backspace())
            this.btn('%', '#A5A5A5', () => {
              if (this.busy || this.fullView) return
              // 输入 8 位以上纯数字（疑似在敲隐藏模式）-> 切换乾造/坤造
              if (/^\d{8,12}$/.test(this.display)) {
                this.gender = this.gender === 0 ? 1 : 0
                this.hint = this.gender === 0 ? '乾造(男)' : '坤造(女)'
                return
              }
              let r = this.current() / 100
              this.display = this.format(r)
            })
            this.btn('÷', '#FF9F0A', () => this.setOp('÷'))
          }
          Row({ space: 12 }) {
            this.btn('7', '#333333', () => this.inputDigit('7'))
            this.btn('8', '#333333', () => this.inputDigit('8'))
            this.btn('9', '#333333', () => this.inputDigit('9'))
            this.btn('×', '#FF9F0A', () => this.setOp('×'))
          }
          Row({ space: 12 }) {
            this.btn('4', '#333333', () => this.inputDigit('4'))
            this.btn('5', '#333333', () => this.inputDigit('5'))
            this.btn('6', '#333333', () => this.inputDigit('6'))
            this.btn('-', '#FF9F0A', () => this.setOp('-'))
          }
          Row({ space: 12 }) {
            this.btn('1', '#333333', () => this.inputDigit('1'))
            this.btn('2', '#333333', () => this.inputDigit('2'))
            this.btn('3', '#333333', () => this.inputDigit('3'))
            this.btn('+', '#FF9F0A', () => this.setOp('+'))
          }
          Row({ space: 12 }) {
            this.btn('0', '#333333', () => this.inputDigit('0'))
            this.btn('.', '#333333', () => this.inputDot())
            this.btn('=', '#FF9F0A', () => this.equals())
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 12 })
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
    }
  }
}
