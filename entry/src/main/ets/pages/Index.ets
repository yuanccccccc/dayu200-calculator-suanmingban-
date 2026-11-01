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
  matchedDate: string // YYYY-MM-DD，必须和输入日期一致
  kind: string // event / birth；逝世、校庆纪念日归 event
  dateRelation: string // occurred / anniversary / born
  personName: string
  title: string
  summary: string
  facts: string
  tone: string
}

const HISTORY_LOOKUP_PROMPT: string = [
  '你是给中国初高中学生选取“历史上的今天”的谨慎编辑。只依据你有把握的历史知识回答；你没有实时检索资料的能力，不得装作查过档案。',
  '先找与输入日期精确对应的候选，再按以下顺序挑一条：①中国国家发展和中国共产党的重大事件；②南开大学创办、校庆、复校等重要史事；③初高中历史课本常见的中国事件和重要人物诞辰；④少数广为人知且日期确切的外国人物诞辰或世界事件。南开大学是明确的专门收录对象，不受“课本未收录”限制。冷僻人物、地方琐事和无明确日期的长期过程不要选。',
  '类别必须分清：某人出生的准确日期是 birth；逝世、建国、建校纪念日等是 event。建校纪念日可以入选，但要把“后来确定的校庆日”与“当日确实举行的典礼”分开，不能混写。历史上的农历、儒略历和公历若无法确定换算，宁可不选。',
  '人物诞辰只收录1800年及以后的重要人物；更早日期仍可寻找重大事件。1901年以前的日期不因算命范围较窄而被排除。',
  '仅输出一行 JSON 对象，不要代码块。字段：found 布尔值；matchedDate 为与输入完全相同的 YYYY-MM-DD 或空字符串；kind 为 event、birth 或空字符串；dateRelation 为 occurred、anniversary、born 或空字符串；personName 人名或空字符串；title 不超过18字；summary 不超过45字；facts 用2至4个有把握的具体史实串成一段，写清时间与关联，不得猜想；tone 用2至6字描述情绪基调。found=false 时其余字段均为空字符串。绝不虚构引语、精确数字、出席者和场景。'
].join('\n')

const HISTORY_EVENT_PROMPT: string = [
  '你写的是供大一学生朗读的历史短文，约450至650字，分3至4个自然段。根据给定的史实写清背景、事情如何展开、后来的影响，再用一两句有余味的文字收束。用一处贯穿前后的意象或恰当比喻增加文采，但每段仍要有具体史事；不要凭空造出人群、天气、口号、对话或亲历者心情。',
  '文字要有节奏和画面感，句子长短交错，少用抽象名词和套话。以社会主义核心价值观为价值坐标：对于建国、革命和建设，写具体行动与历史后果，让爱国、责任、求真从事实中显出来；不堆“伟大光辉”“注定辉煌”之类空泛赞语。对牺牲、灾难和逝世保持克制与尊重，不作戏剧化消费。对历史人物和组织的评价实事求是，既不猎奇贬损，也不把复杂历史写成一串口号。',
  '只能使用输入中的事实作事实依据；输入没给出的具体日期、人数、引语和因果不要补。若 dateRelation 是 anniversary，应明确这是纪念日期，不能写成当日举办了开学或成立典礼。正文纯文本，不要 Markdown。'
].join('\n')

const HISTORY_BIRTH_PROMPT: string = [
  '你写的是历史人物诞辰纪念短文，不是算命，也不推断命运。用给定史实串起人物的经历、关键选择、成就及历史影响；评价要有依据，可写功绩与局限，但不得凭空揣测内心。语言有文采、有温度，避免口号、神化和空洞赞歌。以社会主义核心价值观为价值坐标，让爱国、敬业、求真、为人民服务等价值通过具体行动和结果体现，不直接罗列价值词。',
  '格式固定，全文约500至700字：',
  '【题辞】四句七言诗。七言指每句七个汉字；诗句须回望已知生平，不写生辰八字、天命、吉凶、五行或预言。',
  '【行迹】按时间讲清出身、学习或早年行动与后来两三件关键史事。',
  '【转折】选一处有史实依据的选择或时代关口，写其行动及结果。',
  '【评议】第一行单独写一句不超过八字的凝练判词，第二行起用白话论证贡献与局限；不可只下赞语。',
  '【回响】写这段人生留给后人的问题或启发，以具体而有余味的句子收束。',
  '只用输入中的事实；不得新增未经提供的精确数字、引语、细节和心理活动。若材料不足，宁可缩短，不能填空。正文纯文本，不要 Markdown。'
].join('\n')

// 南开大学官方校史：1919-09-25 开学；11-22 举行成立纪念大会（原拟 10-17）；
// 现行章程规定校庆日为 10-17。1919-10-17 应表述为建校纪念日，不是开学典礼。
// https://www.nankai.edu.cn/173/list.htm
// https://xxgk.nankai.edu.cn/2024/0122/c2762a535612/page.htm
// https://www.nankai.edu.cn/_s264/162/list.psp
const NANKAI_FOUNDING_DAY: EventLookup = {
  found: true,
  matchedDate: '1919-10-17',
  kind: 'event',
  dateRelation: 'anniversary',
  personName: '',
  title: '南开大学建校纪念日',
  summary: '南开大学创办于1919年，10月17日是学校校庆日。',
  facts: '南开大学由严修、张伯苓秉承教育救国理念创办，1919年9月25日举行开学典礼；成立纪念大会原拟10月17日举行，实际于11月22日举行。1937年校园遭侵华日军炸毁，学校南迁，1938年在昆明与北京大学、清华大学组成国立西南联合大学。1946年回天津复校；学校现行章程规定10月17日为校庆日。',
  tone: '庄重昂扬'
}

// 毛主席纪念堂公开年表与生平资料：
// https://cpc.people.com.cn/GB/143527/143544/10536428.html
// https://cpc.people.com.cn/GB/143527/143544/index.html
const MAO_BIRTH_DAY: EventLookup = {
  found: true,
  matchedDate: '1893-12-26',
  kind: 'birth',
  dateRelation: 'born',
  personName: '毛泽东',
  title: '毛泽东诞辰',
  summary: '1893年12月26日，毛泽东出生于湖南湘潭韶山冲。',
  facts: '毛泽东1893年12月26日出生于湖南湘潭韶山冲。青年时在长沙求学，组织新民学会，探索救国道路。他是中国共产党、中国人民解放军和中华人民共和国的主要缔造者之一，领导中国革命取得胜利；1949年10月1日出席开国大典，宣告中华人民共和国中央人民政府成立。其历史功绩重大，晚年亦犯过严重错误，评价应坚持实事求是。',
  tone: '庄重深沉'
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
  @State route: string = '' // searching / event / fortune / historyOnly
  @State eventKind: string = '' // event / birth
  @State eventDateRelation: string = ''
  @State eventPersonName: string = ''
  @State eventSourceNote: string = ''
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
  // 史事可查 1000 年起的四位年份；日期必须真实存在，且不晚于板子系统日期。
  private validHistoricalDate(s: string): boolean {
    let y = parseInt(s.slice(0, 4))
    let m = parseInt(s.slice(4, 6))
    let d = parseInt(s.slice(6, 8))
    if (y < 1000 || m < 1 || m > 12 || d < 1 || d > 31) return false
    let birth = new Date(y, m - 1, d)
    let today = new Date()
    return birth.getFullYear() === y && birth.getMonth() === m - 1 &&
      birth.getDate() === d && birth.getTime() <= today.getTime()
  }

  // 人物诞辰从 1800 年起收录；命盘沿用较稳妥的 1901 年起范围。
  private validPersonBirthDate(s: string): boolean {
    return this.validHistoricalDate(s) && parseInt(s.slice(0, 4)) >= 1800
  }

  private validFortuneDate(s: string): boolean {
    return this.validHistoricalDate(s) && parseInt(s.slice(0, 4)) >= 1901
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
    if (!this.validFortuneDate(s) || !this.validTimePrefix(s)) return nomatch
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
    if (!this.validFortuneDate(this.display) || !this.validTimePrefix(this.display)) return ''
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
    if (this.route === 'searching' || this.route === 'historyOnly') return this.hint
    let magic = this.magicHint()
    if (magic !== '') return magic
    return this.hint !== '' ? this.hint : ' '
  }

  private clearDateRoute() {
    this.lookupSerial += 1
    this.queuedEquals = false
    this.route = ''
    this.eventKind = ''
    this.eventDateRelation = ''
    this.eventPersonName = ''
    this.eventSourceNote = ''
    this.eventTitle = ''
    this.eventSummary = ''
    this.eventFacts = ''
    this.eventTone = ''
  }

  private refreshDateRoute() {
    let s = this.display
    if (this.pendingOp === '' && /^\d{8}$/.test(s) && this.validHistoricalDate(s)) {
      this.beginEventLookup(s, false)
      return
    }
    this.clearDateRoute()
    if (this.pendingOp === '' && /^\d{9,14}$/.test(s) &&
      this.validFortuneDate(s) && this.validTimePrefix(s)) {
      this.route = 'fortune'
      this.hint = ''
    } else if (this.pendingOp === '' && /^\d{9,14}$/.test(s) &&
      this.validHistoricalDate(s) && !this.validFortuneDate(s)) {
      this.route = 'historyOnly'
      this.hint = '命盘仅支持 1901 年及以后'
    } else {
      this.hint = ''
    }
  }

  // 检索未找到、超时或响应异常都回到默认算命路线。
  private useFortuneAfterLookup(date: string, serial: number) {
    if (serial !== this.lookupSerial || this.route !== 'searching' || this.display !== date) return
    let writeNow = this.queuedEquals
    this.queuedEquals = false
    if (this.validFortuneDate(date)) {
      this.route = 'fortune'
      this.hint = ''
      if (writeNow) this.goFortune(this.parsePattern(date))
    } else {
      this.route = 'historyOnly'
      this.hint = '✦ 暂无可展示的史事 · 命盘支持 1901 年起'
    }
  }

  private finishHistoryLookup(date: string, serial: number, candidate: EventLookup | null) {
    if (serial !== this.lookupSerial || this.route !== 'searching' || this.display !== date) return
    // 校史日期已有官方资料核对。AI 仍参与查询，遇到遗漏或断线时使用这一条本地事实锚点。
    let item: EventLookup | null = date === '19191017' ? NANKAI_FOUNDING_DAY
      : date === '18931226' ? MAO_BIRTH_DAY : candidate
    let expectedDate = `${date.slice(0, 4)}-${date.slice(4, 6)}-${date.slice(6, 8)}`
    if (item && item.found === true && item.matchedDate === expectedDate &&
      item.title && item.summary && item.facts && item.tone &&
      ((item.kind === 'event' && (item.dateRelation === 'occurred' || item.dateRelation === 'anniversary')) ||
        (item.kind === 'birth' && item.dateRelation === 'born' && item.personName && this.validPersonBirthDate(date)))) {
      this.route = 'event'
      this.eventKind = item.kind
      this.eventDateRelation = item.dateRelation
      this.eventPersonName = item.personName || ''
      this.eventTitle = item.title
      this.eventSummary = item.summary
      this.eventFacts = item.facts
      this.eventTone = item.tone
      this.eventSourceNote = date === '19191017' ? '据南开大学官方校史与章程核对'
        : date === '18931226' ? '据毛主席纪念堂公开年表核对'
          : 'AI 提供的历史线索，重要事实请核对'
      this.hint = ''
      if (this.queuedEquals) {
        this.queuedEquals = false
        this.goEventEssay()
      }
    } else {
      this.useFortuneAfterLookup(date, serial)
    }
  }

  // 8 位合法日期立即问 AI；请求期间仍允许继续输入时间或按 +。
  private beginEventLookup(date: string, writeAfterLookup: boolean) {
    this.clearDateRoute()
    let serial = this.lookupSerial
    this.queuedEquals = writeAfterLookup
    this.route = 'searching'
    this.hint = '✦ 搜寻史册中 · ' + date.slice(0, 4) + '-' + date.slice(4, 6) + '-' + date.slice(6, 8)
    let nankaiContext = date === '19191017'
      ? '已核对南开大学校史：南开大学创办于1919年；1919年9月25日举行开学典礼；成立纪念大会原拟10月17日，实际于11月22日举行；学校章程规定10月17日为校庆日。应识别为建校纪念日，不得说10月17日举行了开学典礼。'
      : ''
    let req: DSReq = {
      model: DEEPSEEK_MODEL,
      messages: [
        {
          role: 'system',
          content: HISTORY_LOOKUP_PROMPT
        },
        {
          role: 'user',
          content: `目标公历日期：${date.slice(0, 4)}-${date.slice(4, 6)}-${date.slice(6, 8)}。请先核对日期归属，再选择一条适合课堂讲述的事件或人物诞辰。${nankaiContext}`
        }
      ],
      max_tokens: 1200,
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
        this.finishHistoryLookup(date, serial, null)
        return
      }
      try {
        let answer = JSON.parse(String(resp.result)) as DSResp
        let content = answer.choices && answer.choices.length > 0 && answer.choices[0].message
          ? answer.choices[0].message.content : ''
        if (!content) throw new Error('返回为空')
        let clean = content.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '')
        let found = JSON.parse(clean) as EventLookup
        this.finishHistoryLookup(date, serial, found)
      } catch (e) {
        this.finishHistoryLookup(date, serial, null)
      }
    }).catch((e: Error) => {
      client.destroy()
      this.finishHistoryLookup(date, serial, null)
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
    if (op === '+' && /^\d{8}$/.test(this.display) && this.validHistoricalDate(this.display) &&
      (this.route === 'searching' || this.route === 'event')) {
      if (!this.validFortuneDate(this.display)) {
        this.hint = '命盘仅支持 1901 年及以后'
        return
      }
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
      if (/^\d{8}$/.test(this.display) && this.validHistoricalDate(this.display)) {
        if (this.route === 'searching') {
          this.queuedEquals = true
          this.hint = '正在检索；找到结果后将自动继续……'
          return
        }
        if (this.route === 'event') {
          this.goEventEssay()
          return
        }
        if (this.route === 'historyOnly') return
        if (this.route === '') {
          this.beginEventLookup(this.display, true)
          return
        }
      }
      let match = this.parsePattern(this.display)
      if (match.matched) {
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
    let isBirth = this.eventKind === 'birth'
    let title = this.eventTitle
    let summary = this.eventSummary
    let facts = this.eventFacts
    let tone = this.eventTone
    let person = this.eventPersonName
    let relation = this.eventDateRelation
    let sourceNote = this.eventSourceNote
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
          content: isBirth ? HISTORY_BIRTH_PROMPT : HISTORY_EVENT_PROMPT
        },
        {
          role: 'user',
          content: `公历日期：${date}\n类别：${isBirth ? '历史人物诞辰' : '历史事件'}\n日期关系：${relation}\n人物：${person}\n题目：${title}\n简述：${summary}\n可用事实：${facts}\n基调：${tone}\n资料说明：${sourceNote}\n请按本类别的格式写作，尊重史实，避免空泛赞词。`
        }
      ],
      max_tokens: 4000,
      temperature: 0.5,
      reasoning_effort: 'none'
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
        this.hint = '写作失败 HTTP ' + resp.responseCode + '；按 = 重试'
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
        this.hint = '写作结果无法读取；按 = 重试'
      }
    }).catch((e: Error) => {
      client.destroy()
      this.stopTimer()
      this.busy = false
      this.hint = '写作失败：' + (e.message || '网络不可用') + '；按 = 重试'
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
            Text(`✦ ${this.eventKind === 'birth' ? '人物诞辰' : '史册有载'} · ${this.display.slice(0, 4)}-${this.display.slice(4, 6)}-${this.display.slice(6, 8)}`)
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
            Text(this.hint !== '' ? this.hint :
              `按 = ${this.eventKind === 'birth' ? '读人物评传' : '写史事全文'}${this.validFortuneDate(this.display) ? ' · 按 + 改为算命' : ''}`)
              .fontSize(18)
              .fontColor('#FF9F0A')
              .width('100%')
              .textAlign(TextAlign.End)
              .margin({ top: 12 })
            Text(this.eventSourceNote)
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
