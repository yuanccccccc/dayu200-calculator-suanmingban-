/**
 * 简易计算器 + 赛博算命 - DAYU200 / OpenHarmony 4.0 (API 9 兼容)
 * 主页面: entry/src/main/ets/pages/Index.ets
 *
 * 算命模式（方案 B：板子独立运行）：
 * 输入 8 位生日 YYYYMMDD + 男/女，按「占」
 * -> 本地排盘（移植 bazi-mcp/tyme4ts，见 ets/libs/）
 * -> 直连 DeepSeek API 生成解读，无需 PC 中转
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
  // 算命模式状态
  @State mode: string = 'calc' // 'calc' | 'fortune'
  @State birth: string = '' // 8位生日 YYYYMMDD
  @State gender: number = 0 // 0男 1女
  @State baziShort: string = '' // 八字简述（结果顶部展示）
  @State fortuneText: string = '' // 解读正文；'' 表示尚未出结果
  @State busy: boolean = false
  private firstOperand: number = 0
  private pendingOp: string = ''
  private waitingForSecond: boolean = false

  // ---------------- 计算器逻辑（原有） ----------------
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

  // ---------------- 输入处理（双模式） ----------------
  private inputDigit(d: string) {
    if (this.mode === 'fortune') {
      if (this.busy) return
      if (this.fortuneText !== '') { // 已有结果，重新开始输入
        this.fortuneText = ''
        this.baziShort = ''
        this.birth = ''
      }
      if (this.birth.length < 8) { // 前 8 位：生日
        this.birth += d
      } else if (this.birth.length === 8) { // 第 9 位：时辰十位（24 小时制）
        if (parseInt(d) > 2) this.birth += '0' // 输 3-9 自动补 0：按 5 视作 05
        this.birth += d
      } else if (this.birth.length === 9) { // 第 10 位：时辰个位
        if (this.birth[8] === '2' && parseInt(d) > 3) return // 24-29 非法，不接收
        this.birth += d
      }
      return
    }
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
    if (this.mode === 'fortune') return
    if (this.display === '错误' || this.waitingForSecond) {
      this.display = '0.'
      this.waitingForSecond = false
    } else if (!this.display.includes('.')) {
      this.display += '.'
    }
  }

  private setOp(op: string) {
    if (this.mode === 'fortune') return
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
  }

  private equals() {
    if (this.mode === 'fortune') {
      this.goFortune() // 算命模式下 = 也触发占卜
      return
    }
    if (this.pendingOp === '') return
    let r = this.calc(this.firstOperand, this.current(), this.pendingOp)
    this.display = this.format(r)
    this.pendingOp = ''
    this.firstOperand = 0
    this.waitingForSecond = true
  }

  private clearAll() {
    if (this.mode === 'fortune') {
      this.birth = ''
      this.fortuneText = ''
      this.baziShort = ''
      return
    }
    this.display = '0'
    this.firstOperand = 0
    this.pendingOp = ''
    this.waitingForSecond = false
  }

  private backspace() {
    if (this.mode === 'fortune') {
      if (this.busy || this.fortuneText !== '') return
      this.birth = this.birth.length > 0 ? this.birth.slice(0, -1) : ''
      return
    }
    if (this.display === '错误' || this.waitingForSecond) return
    this.display = this.display.length > 1 ? this.display.slice(0, -1) : '0'
  }

  // ---------------- 赛博算命 ----------------
  private toggleMode() {
    if (this.busy) return
    if (this.mode === 'calc') {
      this.mode = 'fortune'
      this.birth = ''
      this.fortuneText = ''
      this.baziShort = ''
    } else {
      this.mode = 'calc'
      this.display = '0'
    }
  }

  private toggleGender() {
    if (this.mode !== 'fortune' || this.busy) return
    this.gender = this.gender === 0 ? 1 : 0
  }

  // 1995082014 -> '1995-08-20 14时'，不足位时显示已输入部分
  private birthDisplay(): string {
    let s = this.birth
    if (s === '') return ''
    let y = s.slice(0, 4)
    let m = s.length > 4 ? s.slice(4, 6) : ''
    let d = s.length > 6 ? s.slice(6, 8) : ''
    let h = s.length > 8 ? s.slice(8, 10) : ''
    let out = y
    if (s.length >= 5) out += '-' + m
    if (s.length >= 7) out += '-' + d
    if (s.length >= 9) out += ' ' + h + (s.length === 10 ? '时' : '?')
    return out
  }

  private goFortune() {
    if (this.mode !== 'fortune' || this.busy) return
    if (this.birth.length !== 8 && this.birth.length !== 10) {
      this.fortuneText = '请输入 8 位生日（如 19950820），可再加 2 位时辰（24 小时制，如 09、21）；不输时辰则随机定。'
      return
    }
    let y = parseInt(this.birth.slice(0, 4))
    let m = parseInt(this.birth.slice(4, 6))
    let d = parseInt(this.birth.slice(6, 8))
    if (y < 1901 || y > 2099 || m < 1 || m > 12 || d < 1 || d > 31) {
      this.fortuneText = '日期不合法，请检查后重输。'
      return
    }
    // 时辰：输满 10 位用输入值；只输 8 位则现场随机拈一个（古人"时辰不知，以卜定之"）
    let hour = 12
    let hourNote = ''
    if (this.birth.length === 10) {
      hour = parseInt(this.birth.slice(8, 10))
      if (isNaN(hour) || hour > 23) {
        this.fortuneText = '时辰不合法（应为 00-23），请检查后重输。'
        return
      }
    } else {
      hour = Math.floor(Math.random() * 24)
      hourNote = `求测者不知出生时辰，现场拈得${hour}时，时柱由此而定。时柱可以照常推演，但涉及时柱的断语措辞宜留三分余地。`
    }
    this.busy = true
    this.baziShort = ''
    this.fortuneText = '正在排盘……'

    // 1. 本地排盘（无网络，毫秒级）
    let b: BaziLite
    try {
      b = calcBazi(y, m, d, hour, this.gender)
    } catch (e) {
      this.busy = false
      this.fortuneText = '排盘失败：' + (e as Error).message
      return
    }
    this.baziShort = b.baziShort
    this.fortuneText = '八字已排好，正在请 DeepSeek 天师解读……'

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
${b.summary}${hourNote ? '\n注：' + hourNote : ''}

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
      this.busy = false
      if (resp.responseCode !== 200) {
        this.fortuneText = 'DeepSeek HTTP ' + resp.responseCode
        return
      }
      let r = JSON.parse(String(resp.result)) as DSResp
      let text = r.choices && r.choices.length > 0 && r.choices[0].message ? r.choices[0].message.content : undefined
      if (text) {
        this.fortuneText = text
      } else {
        this.fortuneText = '解读失败：' + (r.error && r.error.message ? r.error.message : '返回为空')
      }
    }).catch((e: Error) => {
      client.destroy()
      this.busy = false
      this.fortuneText = '网络错误：' + (e.message || '无法连接 DeepSeek（板子需可上外网）')
    })
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
    Column() {
      // 显示屏
      Column() {
        if (this.mode === 'fortune') {
          Text(this.baziShort !== ''
            ? this.baziShort
            : `赛博算命 · ${this.gender === 0 ? '乾造(男)' : '坤造(女)'} · 生日后可加 2 位时辰(24h)，缺省随机`)
            .fontSize(20)
            .fontColor('#FF9F0A')
            .width('100%')
            .textAlign(TextAlign.End)
            .maxLines(2)
          if (this.fortuneText !== '') {
            // 结果/提示文本
            Scroll() {
              Text(this.fortuneText)
                .fontSize(22)
                .fontColor(Color.White)
                .width('100%')
                .lineHeight(30)
            }
            .scrollable(ScrollDirection.Vertical)
            .width('100%')
            .layoutWeight(1)
            .align(Alignment.BottomEnd)
            .margin({ top: 8 })
          } else {
            Text(this.birthDisplay() !== '' ? this.birthDisplay() : '输入生日 YYYYMMDD')
              .fontSize(this.birth.length === 8 ? 44 : 36)
              .fontColor(this.birthDisplay() !== '' ? Color.White : '#8E8E93')
              .width('100%')
              .textAlign(TextAlign.End)
              .maxLines(1)
          }
        } else {
          Text(this.pendingOp ? this.format(this.firstOperand) + ' ' + this.pendingOp : ' ')
            .fontSize(24)
            .fontColor('#FF9F0A')
            .width('100%')
            .textAlign(TextAlign.End)
          Text(this.display)
            .fontSize(56)
            .fontColor(Color.White)
            .width('100%')
            .textAlign(TextAlign.End)
            .maxLines(1)
        }
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16, bottom: 12 })
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)

      // 按键区
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          this.btn('C', '#A5A5A5', () => this.clearAll())
          this.btn('←', '#A5A5A5', () => this.backspace())
          this.btn('%', '#A5A5A5', () => {
            if (this.mode !== 'calc') return
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
        // 算命功能行（矮一排，给显示区留空间）
        Row({ space: 12 }) {
          Button(this.mode === 'fortune' ? '返回' : '算命')
            .fontSize(18)
            .fontColor(Color.White)
            .backgroundColor('#5856D6')
            .width('22%')
            .height(62)
            .borderRadius(20)
            .onClick(() => this.toggleMode())
          Button(this.gender === 0 ? '男' : '女')
            .fontSize(18)
            .fontColor(Color.White)
            .backgroundColor(this.gender === 0 ? '#5AC8FA' : '#FF2D55')
            .width('22%')
            .height(62)
            .borderRadius(20)
            .onClick(() => this.toggleGender())
          Button(this.busy ? '…' : '占')
            .fontSize(22)
            .fontColor(Color.White)
            .backgroundColor('#FF9F0A')
            .width('22%')
            .height(62)
            .borderRadius(20)
            .onClick(() => this.goFortune())
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
