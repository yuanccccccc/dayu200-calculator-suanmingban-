/**
 * 简易计算器 - DAYU200 / OpenHarmony 4.0 (API 9 兼容)
 * 主页面: entry/src/main/ets/pages/Index.ets
 *
 * 隐藏彩蛋：8 位合法日期先向 AI 查询当天史事；找到后 = 写史事，+ 改走算命。
 * 没找到明确史事时 = 算命；日期后继续输入 HH、HHMM 或 HHMMSS 则直接算命。
 * 算命结果与史事全文共用结果框和全屏阅读页。
 */
import http from '@ohos.net.http'
import { calcBazi, BaziLite } from '../libs/baziapi'

// DeepSeek 直连配置（测试版内嵌 key）
const DEEPSEEK_URL = 'https://api.deepseek.com/chat/completions'
const DEEPSEEK_KEY = 'sk-a485abd5f4f04224af2542286f45c601'
const DEEPSEEK_MODEL = 'deepseek-flash'

// 推演等待期间的玄学进度播报（每 6 秒轮换一条）
const FORTUNE_STAGES: string[] = [
  '焚香起盘，星斗布位……',
  '八字已排好，DeepSeek 天师披衣起卦……',
  '天师掐指细推，五行流转……',
  '天机玄玄，墨迹将成……',
  '批文欲就，心诚则灵……'
]

const EVENT_STAGES: string[] = [
  '翻检旧卷，辨认那一天……',
  '史事已寻得，正在梳理来龙去脉……',
  '斟酌字句，为这一天落笔……'
]

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

// 隐藏模式识别结果
interface FortuneMatch {
  matched: boolean
  hour: number // 0-23；-1 表示只输了生日，时辰需随机拈定
  minute: number
  second: number
}

interface EventLookup {
  found: boolean
  title: string
  summary: string
  facts: string
  tone: string
}

@Entry
@Component
struct Index {
  @State display: string = '0'
  @State hint: string = '' // 橙色小字：挂起运算 / 推演进度播报 / 错误提示
  @State gender: number = 0 // 0男(乾造) 1女(坤造)，隐藏开关：% 键在输入 8 位以上数字时切换
  @State baziShort: string = ''
  @State fortuneText: string = '' // ''=无结果；非空时显示在上方结果框
  @State busy: boolean = false
  @State fullView: boolean = false // 全屏阅读页
  @State bigFont: boolean = false // 阅读页字号（点正文切换）
  @State elapsed: number = 0 // 推演已用时（秒）
  @State route: string = '' // searching / event / fortune
  @State eventTitle: string = ''
  @State eventSummary: string = ''
  @State eventFacts: string = ''
  @State eventTone: string = ''
  private firstOperand: number = 0
  private pendingOp: string = ''
  private waitingForSecond: boolean = false
  private timerId: number = -1
  private lookupSerial: number = 0 // 忽略输入变化后才返回的旧检索结果
  private queuedEquals: boolean = false

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
  // 四位年份从 1000 年起可输入；日期必须真实存在，且不晚于板子系统日期。
  private validBirthDate(s: string): boolean {
    let y = parseInt(s.slice(0, 4))
    let m = parseInt(s.slice(4, 6))
    let d = parseInt(s.slice(6, 8))
    if (y < 1000 || m < 1 || m > 12 || d < 1 || d > 31) return false
    let birth = new Date(y, m - 1, d)
    let today = new Date()
    return birth.getFullYear() === y && birth.getMonth() === m - 1 &&
      birth.getDate() === d && birth.getTime() <= today.getTime()
  }

  // 时间前缀也要合理，避免输入 29 时、67 分时亮起算命装饰。
  private validTimePrefix(s: string): boolean {
    if (s.length >= 9 && parseInt(s.slice(8, 9)) > 2) return false
    if (s.length >= 10 && parseInt(s.slice(8, 10)) > 23) return false
    if (s.length >= 11 && parseInt(s.slice(10, 11)) > 5) return false
    if (s.length >= 12 && parseInt(s.slice(10, 12)) > 59) return false
    if (s.length >= 13 && parseInt(s.slice(12, 13)) > 5) return false
    if (s.length >= 14 && parseInt(s.slice(12, 14)) > 59) return false
    return true
  }

  // 纯数字 8/10/12/14 位日期和时间；hour=-1 表示缺时辰。
  private parsePattern(s: string): FortuneMatch {
    let nomatch: FortuneMatch = { matched: false, hour: -1, minute: 0, second: 0 }
    if (this.pendingOp !== '' || !/^(\d{8}|\d{10}|\d{12}|\d{14})$/.test(s)) return nomatch
    if (!this.validBirthDate(s) || !this.validTimePrefix(s)) return nomatch
    if (s.length === 8) return { matched: true, hour: -1, minute: 0, second: 0 }
    return {
      matched: true,
      hour: parseInt(s.slice(8, 10)),
      minute: s.length >= 12 ? parseInt(s.slice(10, 12)) : 0,
      second: s.length === 14 ? parseInt(s.slice(12, 14)) : 0
    }
  }

  // 敲入的数字像生日时亮起的"魔法"装饰；退格破坏模式后自动消失
  private magicHint(): string {
    if (this.busy || this.fortuneText !== '' || this.pendingOp !== '' || this.route !== 'fortune') return ''
    if (!/^\d{8,14}$/.test(this.display)) return ''
    if (!this.validBirthDate(this.display) || !this.validTimePrefix(this.display)) return ''
    let y = parseInt(this.display.slice(0, 4))
    let out = `✦ ${this.gender === 0 ? '乾造(男)' : '坤造(女)'} · ${y}-${this.display.slice(4, 6)}-${this.display.slice(6, 8)}`
    if (this.display.length >= 9) out += ` ${this.display.slice(8, 10)}${this.display.length === 9 ? '…' : '时'}`
    if (this.display.length >= 11) out += `${this.display.slice(10, 12)}${this.display.length === 11 ? '…' : '分'}`
    if (this.display.length >= 13) out += `${this.display.slice(12, 14)}${this.display.length === 13 ? '…' : '秒'}`
    if (this.display.length === 8) out += ' · 时辰待拈'
    return out + ' · 天机感应中'
  }

  // 提示行内容：优先级 = 推演播报 > 魔法装饰 > 挂起运算
  private topLine(): string {
    if (this.busy) return this.hint
    if (this.route === 'searching') return this.hint
    let magic = this.magicHint()
    if (magic !== '') return magic
    return this.hint !== '' ? this.hint : ' '
  }

  private clearDateRoute() {
    this.lookupSerial += 1
    this.queuedEquals = false
    this.route = ''
    this.eventTitle = ''
    this.eventSummary = ''
    this.eventFacts = ''
    this.eventTone = ''
  }

  private refreshDateRoute() {
    let s = this.display
    if (this.pendingOp === '' && /^\d{8}$/.test(s) && this.validBirthDate(s)) {
      this.beginEventLookup(s, false)
      return
    }
    this.clearDateRoute()
    if (this.pendingOp === '' && /^\d{9,14}$/.test(s) &&
      this.validBirthDate(s) && this.validTimePrefix(s)) {
      this.route = 'fortune'
    }
    this.hint = ''
  }

  // 检索未找到、超时或响应异常都回到默认算命路线。
  private useFortuneAfterLookup(date: string, serial: number) {
    if (serial !== this.lookupSerial || this.route !== 'searching' || this.display !== date) return
    let writeNow = this.queuedEquals
    this.queuedEquals = false
    this.route = 'fortune'
    this.hint = ''
    if (writeNow) this.goFortune(this.parsePattern(date))
  }

  // 8 位合法日期立即问 AI；请求期间仍允许继续输入时间或按 +。
  private beginEventLookup(date: string, writeAfterLookup: boolean) {
    this.clearDateRoute()
    let serial = this.lookupSerial
    this.queuedEquals = writeAfterLookup
    this.route = 'searching'
    this.hint = '✦ 搜寻史册中 · ' + date.slice(0, 4) + '-' + date.slice(4, 6) + '-' + date.slice(6, 8)
    let req: DSReq = {
      model: DEEPSEEK_MODEL,
      messages: [
        {
          role: 'system',
          content: '你是谨慎的中国历史教材编辑。仅凭你确定的知识，判断指定公历日期是否对应一件重大历史事件，或一位广为人知的历史人物的确切生日。优先级：①中华人民共和国、国家发展和中国共产党的重大事件；②南开大学相关的重大事件；③中国初高中历史课本常见的事件与人物；④仅限爱因斯坦等普通学生也熟悉的外国人物或重大事件。只选其中最重要的一件；冷僻人物、地方小事、未进入常见历史教学的条目一律不要。必须能确认准确的公历年月日；“牛顿发现万有引力”这类没有可靠单日日期的过程不得硬配某一天，古代农历与公历换算不确定也不得猜测。无法确认或不符合范围就返回 found=false。只返回一个 JSON 对象，字段必须是 found(布尔值)、title(短标题)、summary(40字内简介)、facts(2至3条确知事实的纯文本)、tone(庄严/沉痛/欣喜等基调)。未找到时其他字段用空字符串。不要 Markdown，不要虚构引语、数字或人物。'
        },
        {
          role: 'user',
          content: `公历 ${date.slice(0, 4)}-${date.slice(4, 6)}-${date.slice(6, 8)} 发生过什么足够重要且日期确切的事件，或是哪位重要历史人物的出生日期？`
        }
      ],
      max_tokens: 600,
      temperature: 0.1,
      reasoning_effort: 'low'
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
      readTimeout: 60000
    }).then((resp: http.HttpResponse) => {
      client.destroy()
      if (serial !== this.lookupSerial || this.route !== 'searching' || this.display !== date) return
      if (resp.responseCode !== 200) {
        this.useFortuneAfterLookup(date, serial)
        return
      }
      try {
        let answer = JSON.parse(String(resp.result)) as DSResp
        let content = answer.choices && answer.choices.length > 0 && answer.choices[0].message
          ? answer.choices[0].message.content : ''
        if (!content) throw new Error('返回为空')
        let clean = content.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '')
        let found = JSON.parse(clean) as EventLookup
        if (found.found === true && found.title && found.summary && found.facts && found.tone) {
          this.route = 'event'
          this.eventTitle = found.title
          this.eventSummary = found.summary
          this.eventFacts = found.facts
          this.eventTone = found.tone
          this.hint = ''
          if (this.queuedEquals) {
            this.queuedEquals = false
            this.goEventEssay()
          }
        } else if (found.found === false) {
          this.useFortuneAfterLookup(date, serial)
        } else {
          throw new Error('检索结果格式不完整')
        }
      } catch (e) {
        this.useFortuneAfterLookup(date, serial)
      }
    }).catch((e: Error) => {
      client.destroy()
      this.useFortuneAfterLookup(date, serial)
    })
  }

  // ---------------- 输入处理 ----------------
  private inputDigit(d: string) {
    if (this.busy || this.fullView) return
    if (this.fortuneText !== '') this.closeFortune() // 已有结果，敲数字即开始新一轮
    if (this.display === '错误' || this.waitingForSecond) {
      this.display = d
      this.waitingForSecond = false
    } else if (this.display === '0') {
      this.display = d
    } else if (this.display.length < 14) {
      this.display += d
    }
    this.refreshDateRoute()
  }

  private inputDot() {
    if (this.busy || this.fullView) return
    if (this.fortuneText !== '') this.closeFortune()
    if (this.display === '错误' || this.waitingForSecond) {
      this.display = '0.'
      this.waitingForSecond = false
    } else if (!this.display.includes('.')) {
      this.display += '.'
    }
    this.clearDateRoute()
    this.hint = ''
  }

  private setOp(op: string) {
    if (this.busy || this.fullView) return
    if (this.fortuneText !== '') this.closeFortune()
    if (op === '+' && /^\d{8}$/.test(this.display) && this.validBirthDate(this.display) &&
      (this.route === 'searching' || this.route === 'event')) {
      this.clearDateRoute()
      this.route = 'fortune'
      this.hint = ''
      return
    }
    this.clearDateRoute()
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
    // 8 位日期先完成史事分流；时间输入或明确切到算命时走本地排盘。
    if (this.pendingOp === '') {
      let match = this.parsePattern(this.display)
      if (match.matched) {
        if (this.display.length === 8) {
          if (this.route === 'searching') {
            this.queuedEquals = true
            this.hint = '正在检索；找到结果后将自动继续……'
            return
          }
          if (this.route === 'event') {
            this.goEventEssay()
            return
          }
          if (this.route === '') {
            this.beginEventLookup(this.display, true)
            return
          }
        }
        this.goFortune(match)
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
    if (this.fullView) { // 全屏页无键盘，正常不会走到这里
      this.closeFortune()
      return
    }
    if (this.fortuneText !== '') { // 结果框有内容：按 C 清场回到计算器
      this.closeFortune()
      return
    }
    this.display = '0'
    this.clearDateRoute()
    this.hint = ''
    this.firstOperand = 0
    this.pendingOp = ''
    this.waitingForSecond = false
  }

  private backspace() {
    if (this.busy || this.fullView) return
    if (this.fortuneText !== '') this.closeFortune()
    if (this.display === '错误' || this.waitingForSecond) return
    this.display = this.display.length > 1 ? this.display.slice(0, -1) : '0'
    this.refreshDateRoute()
  }

  private closeFortune() {
    this.clearDateRoute()
    this.fullView = false
    this.fortuneText = ''
    this.baziShort = ''
    this.display = '0'
    this.hint = ''
    this.bigFont = false
  }

  // ---------------- 史事短文 ----------------
  private goEventEssay() {
    let date = `${this.display.slice(0, 4)}-${this.display.slice(4, 6)}-${this.display.slice(6, 8)}`
    let title = this.eventTitle
    let summary = this.eventSummary
    let facts = this.eventFacts
    let tone = this.eventTone
    this.busy = true
    this.elapsed = 0
    this.hint = EVENT_STAGES[0] + '（0s）'
    this.timerId = setInterval(() => {
      this.elapsed += 1
      let stage = EVENT_STAGES[Math.floor(this.elapsed / 6) % EVENT_STAGES.length]
      this.hint = `${stage}（${this.elapsed}s）`
    }, 1000)
    let req: DSReq = {
      model: DEEPSEEK_MODEL,
      messages: [
        {
          role: 'system',
          content: '你是历史短文作者。依据给定日期、事件和事实写一段有感染力的中文短文，约350至500字，分成2至4段。先交代这一天发生了什么，再写事情的走向与时代处境，最后以符合给定基调的句子收束。悲剧保持克制，喜事可以明朗；人物生辰可写其后来的人生影响，但不可编造细节。不得虚构引语、统计数字、后续事件或历史人物的心理活动；给定事实不足时宁可写短。不要把AI线索称为已核实史料。只输出正文纯文本。'
        },
        {
          role: 'user',
          content: `公历日期：${date}\n事件：${title}\n简述：${summary}\n已知事实：${facts}\n情感基调：${tone}\n请据此写一段史事短文。`
        }
      ],
      max_tokens: 6000,
      temperature: 0.5,
      reasoning_effort: 'low'
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
        this.hint = '史事写作失败 HTTP ' + resp.responseCode + '；按 = 重试'
        return
      }
      try {
        let answer = JSON.parse(String(resp.result)) as DSResp
        let content = answer.choices && answer.choices.length > 0 && answer.choices[0].message
          ? answer.choices[0].message.content : ''
        if (!content) throw new Error('返回为空')
        this.baziShort = `${date} · ${title}`
        this.fortuneText = content
        this.hint = ''
      } catch (e) {
        this.hint = '史事写作结果无法读取；按 = 重试'
      }
    }).catch((e: Error) => {
      client.destroy()
      this.stopTimer()
      this.busy = false
      this.hint = '史事写作失败：' + (e.message || '网络不可用') + '；按 = 重试'
    })
  }

  // ---------------- 赛博算命（隐藏） ----------------
  private goFortune(match: FortuneMatch) {
    let y = parseInt(this.display.slice(0, 4))
    let m = parseInt(this.display.slice(4, 6))
    let d = parseInt(this.display.slice(6, 8))
    // 时辰：显式输入直接用；只输生日则现场随机拈一个（古人"时辰不知，以卜定之"）
    let hour: number
    let hourNote = ''
    if (match.hour >= 0) {
      hour = match.hour
    } else {
      hour = Math.floor(Math.random() * 24)
      hourNote = `求测者不知出生时辰，现场拈得${hour}时，时柱由此而定。时柱可以照常推演，但涉及时柱的断语措辞宜留三分余地。`
    }
    this.busy = true
    this.elapsed = 0
    this.hint = FORTUNE_STAGES[0] + '（0s）'
    this.timerId = setInterval(() => {
      this.elapsed += 1
      let stage = FORTUNE_STAGES[Math.floor(this.elapsed / 6) % FORTUNE_STAGES.length]
      this.hint = `${stage}（${this.elapsed}s）`
    }, 1000)

    // 1. 本地排盘（无网络，毫秒级）
    let b: BaziLite
    try {
      b = calcBazi(y, m, d, hour, this.gender, match.minute, match.second)
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
      this.stopTimer()
      this.busy = false
      if (resp.responseCode !== 200) {
        this.hint = '解读失败 HTTP ' + resp.responseCode
        return
      }
      let r = JSON.parse(String(resp.result)) as DSResp
      let text = r.choices && r.choices.length > 0 && r.choices[0].message ? r.choices[0].message.content : undefined
      if (text) {
        this.fortuneText = text // 先显示在上方结果框，用户可再点全屏
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
      // 全屏阅读页：大字号长文阅读；「⤡ 缩小」收回结果框，「✕ 关闭」清场
      Column() {
        Row() {
          Text(this.baziShort)
            .fontSize(22)
            .fontColor('#FF9F0A')
            .layoutWeight(1)
            .maxLines(1)
          Text('✕')
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

        Row({ space: 12 }) {
          Button('⤡ 缩小')
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor('#5856D6')
            .layoutWeight(1)
            .height(56)
            .borderRadius(16)
            .onClick(() => { this.fullView = false }) // 收回结果框，结果保留
          Button('✕ 关闭')
            .fontSize(20)
            .fontColor(Color.White)
            .backgroundColor('#A5A5A5')
            .layoutWeight(1)
            .height(56)
            .borderRadius(16)
            .margin({ bottom: 16 })
            .onClick(() => this.closeFortune())
        }
        .width('70%')
        .padding({ left: 16, right: 16, top: 8 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
    } else {
      Column() {
        // 显示屏（结果优先显示在这里的小框里，可再点全屏）
        Column() {
          if (this.fortuneText !== '') {
            Row() {
              Text(this.baziShort)
                .fontSize(20)
                .fontColor('#FF9F0A')
                .layoutWeight(1)
                .maxLines(1)
              Text('⤢ 全屏')
                .fontSize(20)
                .fontColor('#FF9F0A')
                .padding({ left: 12, right: 4, top: 4, bottom: 4 })
                .onClick(() => { this.fullView = true })
            }
            .width('100%')
            Scroll() {
              Text(this.fortuneText)
                .fontSize(20)
                .fontColor(Color.White)
                .width('100%')
                .lineHeight(28)
            }
            .scrollable(ScrollDirection.Vertical)
            .width('100%')
            .layoutWeight(1)
            .align(Alignment.BottomEnd)
            .margin({ top: 6 })
          } else if (this.route === 'event') {
            Text(`✦ 史册有载 · ${this.display.slice(0, 4)}-${this.display.slice(4, 6)}-${this.display.slice(6, 8)}`)
              .fontSize(21)
              .fontColor('#FF9F0A')
              .width('100%')
              .textAlign(TextAlign.End)
            Text(this.eventTitle)
              .fontSize(32)
              .fontColor(Color.White)
              .width('100%')
              .textAlign(TextAlign.End)
              .maxLines(2)
              .margin({ top: 12 })
            Text(this.eventSummary)
              .fontSize(21)
              .fontColor('#DDDDDD')
              .width('100%')
              .textAlign(TextAlign.End)
              .maxLines(3)
              .margin({ top: 8 })
            Text(this.hint !== '' ? this.hint : '按 = 写史事全文 · 按 + 改为算命')
              .fontSize(18)
              .fontColor('#FF9F0A')
              .width('100%')
              .textAlign(TextAlign.End)
              .margin({ top: 12 })
            Text('AI 提供的史事线索，重要事实请核对')
              .fontSize(14)
              .fontColor('#888888')
              .width('100%')
              .textAlign(TextAlign.End)
              .margin({ top: 5 })
          } else {
            Text(this.topLine())
              .fontSize(22)
              .fontColor('#FF9F0A')
              .width('100%')
              .textAlign(TextAlign.End)
              .maxLines(1)
            Text(this.busy ? `☯ ${this.elapsed}s` : this.display)
              .fontSize(this.busy ? 48 : 56)
              .fontColor(this.busy ? '#FF9F0A' : Color.White)
              .width('100%')
              .textAlign(TextAlign.End)
              .maxLines(1)
          }
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
              // 进入算命路线后才用 % 切换乾坤；史事路线用 + 切换。
              if (this.route === 'fortune' && /^\d{8,14}$/.test(this.display)) {
                this.gender = this.gender === 0 ? 1 : 0
                return
              }
              this.clearDateRoute()
              let r = this.current() / 100
              this.display = this.format(r)
              this.hint = ''
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
