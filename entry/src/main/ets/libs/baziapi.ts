/**
 * 本地八字排盘 + 子平分析引擎（方案 B：板子独立运行）
 *
 * 排盘：移植 bazi-mcp + tyme4ts + cantian-tymext（纯计算，无网络无 Node 依赖）。
 * 分析：按《子平真诠》《渊海子平》传统规则在本地做确定性推演——
 *   五行加权统计 / 日主强弱(得令得地得势) / 喜用神(扶抑+调候) / 月令取格，
 * 结论以【】段落形式交给大模型展开论证，避免模型脱离命局泛泛而谈。
 */
import { SolarTime } from './tyme4ts'
import { buildBazi } from './bazibuild'

export interface BaziLite {
  baziShort: string // 例：'乙亥 甲申 癸未 戊午 · 猪'
  summary: string // 排盘数据 + 本地分析结论（给大模型）
}

// ---------------- 基础表 ----------------
const GAN_WX: Record<string, string> = {
  甲: '木', 乙: '木', 丙: '火', 丁: '火', 戊: '土',
  己: '土', 庚: '金', 辛: '金', 壬: '水', 癸: '水'
}
const SHENG: Record<string, string> = { 木: '火', 火: '土', 土: '金', 金: '水', 水: '木' } // A生B
const KE: Record<string, string> = { 木: '土', 土: '水', 水: '火', 火: '金', 金: '木' } // A克B
const SHENG_WO: Record<string, string> = { 木: '水', 火: '木', 土: '火', 金: '土', 水: '金' } // 生我者(印)
const KE_WO: Record<string, string> = { 木: '金', 火: '水', 土: '木', 金: '火', 水: '土' } // 克我者(官杀)
const TONG_DANG = ['比肩', '劫财', '正印', '偏印'] // 同党（帮身）
const ZHU_NAME = ['年柱', '月柱', '日柱', '时柱']

// ---------------- 典籍结构化数据（《穷通宝鉴》十干调候 + 四季调候） ----------------
// 十日主取用要点（穷通宝典逐日主论）
const DAYMASTER_TUNGTONG: Record<string, string> = {
  甲: '栋梁之木，取用次序重火暖、金裁、水润',
  乙: '花草藤萝，重丙火太阳温养、癸水滋润和依附环境',
  丙: '太阳之火，重壬水调济，忌过燥过晦',
  丁: '灯烛之火，重甲木引丁、庚金劈甲和环境承接',
  戊: '高山厚土，重甲木疏土、癸水润土，火土不过燥',
  己: '田园湿土，重丙火温养、癸水润泽、甲木疏理',
  庚: '顽金成器，重丁火锻炼、甲木引丁、壬水洗炼',
  辛: '珠玉之金，重壬水淘洗、丙火温润，忌土重埋金',
  壬: '江河之水，重戊土堤防、庚辛发源、丙火调候',
  癸: '雨露之水，重丙火照暖、辛金发源，忌土浊水滞'
}
// 四季调候（按月支）
const SEASON_TUNGTONG: Record<string, { season: string; need: string; caution: string }> = {
  寅: { season: '春', need: '火暖、水润、金裁', caution: '春木不宜过寒，也不宜水多漂木' },
  卯: { season: '春', need: '火暖、水润、金裁', caution: '春木不宜过寒，也不宜水多漂木' },
  辰: { season: '春', need: '火暖、水润、金裁', caution: '春土湿，宜火暖' },
  巳: { season: '夏', need: '水调候、金生水、湿土承接', caution: '夏火燥土重时，见财官未必轻松，先看水源和金印是否可用' },
  午: { season: '夏', need: '水调候、金生水、湿土承接', caution: '夏火燥土重时，见财官未必轻松，先看水源和金印是否可用' },
  未: { season: '夏', need: '水调候、金生水、湿土承接', caution: '未月燥土，宜水润' },
  申: { season: '秋', need: '火炼、水润、木疏', caution: '秋金过强需火制炼，燥土重时仍需水润' },
  酉: { season: '秋', need: '火炼、水润、木疏', caution: '秋金过强需火制炼' },
  戌: { season: '秋', need: '火炼、水润、木疏', caution: '秋土燥，宜水润' },
  亥: { season: '冬', need: '火暖、木引火、土制水', caution: '冬水过寒，见水未必为喜，需先看火暖和气机' },
  子: { season: '冬', need: '火暖、木引火、土制水', caution: '冬水过寒，见水未必为喜，需先看火暖和气机' },
  丑: { season: '冬', need: '火暖、木引火、土制水', caution: '冬令寒湿，宜火暖土' }
}
// 八正格成败 checklist（《子平真诠》格局论）
const GEJU_CHECK: Record<string, { cheng: string; bai: string }> = {
  正官格: { cheng: '官星清透、有印相生、财印不互伤', bai: '伤官直接破官、官杀混杂无制、比劫争权' },
  七杀格: { cheng: '食神制杀、印星化杀、杀印相生', bai: '杀旺无制、财滋杀变强压、制化两失' },
  正财格: { cheng: '身能任财、官印护财、财有源流', bai: '身弱财重、比劫争财、财多坏印' },
  偏财格: { cheng: '身旺或印比承接、财官相生', bai: '身弱逐财、资源无承接、比劫分夺' },
  正印格: { cheng: '印星清透、官印相生、有财不坏印', bai: '财重破印、印多身滞' },
  偏印格: { cheng: '偏印成专业方法、杀印相生、有食伤流通', bai: '枭神夺食、孤偏难落地' },
  食神格: { cheng: '食神生财、食神制杀、气机流通', bai: '枭神夺食、食伤太过泄身' },
  伤官格: { cheng: '伤官配印、伤官生财且身能任', bai: '伤官见官无制、表达冲撞规则' },
  建禄格: { cheng: '自立自强、财官食伤泄秀有力', bai: '印比重叠、秀气不吐' },
  月劫格: { cheng: '食伤化劫生财', bai: '比劫争财无制' }
}

// ---------------- 子平分析 ----------------

/** 四柱各干支信息（含十神）整合 */
function pillarInfo(bazi: any): string[] {
  return ZHU_NAME.map((k) => {
    const p = bazi[k]
    const gan = p.天干
    const zhi = p.地支
    const cg = [zhi.藏干.主气, zhi.藏干.中气, zhi.藏干.余气]
      .filter(Boolean)
      .map((h: any) => `${h.天干}(${h.十神})`)
      .join(' ')
    const tss = gan.十神 ? `天干${gan.十神}` : '日主'
    return `${k} ${gan.天干}${zhi.地支}｜${tss}｜藏干:${cg}｜纳音${p.纳音}`
  })
}

/** 五行加权统计：天干1.0，藏干主气1.0/中气0.4/余气0.2 */
function wuxingCount(bazi: any): Record<string, number> {
  const w: Record<string, number> = { 木: 0, 火: 0, 土: 0, 金: 0, 水: 0 }
  for (const k of ZHU_NAME) {
    const p = bazi[k]
    w[GAN_WX[p.天干.天干]] += 1
    const hd = p.地支.藏干
    if (hd.主气) w[GAN_WX[hd.主气.天干]] += 1
    if (hd.中气) w[GAN_WX[hd.中气.天干]] += 0.4
    if (hd.余气) w[GAN_WX[hd.余气.天干]] += 0.2
  }
  return w
}

/** 日主强弱：得令/得地/得势三要素评分（满分约10） */
function strengthAnalysis(bazi: any): { score: number; level: string; detail: string } {
  const dayEl = GAN_WX[bazi.日柱.天干.天干]
  const isTong = (t?: string) => !!t && TONG_DANG.includes(t)
  // 得令：月令为提纲，权重最高
  const mHD = bazi.月柱.地支.藏干
  let ling = 0
  let lingTxt = ''
  if (isTong(mHD.主气?.十神)) {
    ling = 3
    lingTxt = `月令${bazi.月柱.地支.地支}中${mHD.主气.天干}（${mHD.主气.十神}）当令，日主得令`
  } else if (isTong(mHD.中气?.十神) || isTong(mHD.余气?.十神)) {
    ling = 1.5
    lingTxt = `月令${bazi.月柱.地支.地支}藏干中${isTong(mHD.中气?.十神) ? mHD.中气.天干 + '（' + mHD.中气.十神 + '）' : mHD.余气.天干 + '（' + mHD.余气.十神 + '）'}暗助，日主半得令`
  } else {
    lingTxt = `月令${bazi.月柱.地支.地支}之气不帮身，日主失令`
  }
  // 得地：年/日/时支主气有根
  const diPillars: string[] = []
  for (const k of ['年柱', '日柱', '时柱']) {
    const hd = bazi[k].地支.藏干
    if (isTong(hd.主气?.十神)) {
      diPillars.push(`${k.replace('柱', '')}支${bazi[k].地支.地支}中${hd.主气.天干}通根`)
    }
  }
  const di = diPillars.length
  // 得势：天干同党（日主自坐 +1，年月时干各 +1）
  const ganTong: string[] = []
  for (const k of ['年柱', '月柱', '时柱']) {
    const ts = bazi[k].天干.十神
    if (isTong(ts)) ganTong.push(`${k.replace('柱', '')}干${bazi[k].天干.天干}（${ts}）帮身`)
  }
  const shi = 1 + ganTong.length
  const score = ling + di + shi
  let level = score >= 6.5 ? '偏强' : score <= 3.5 ? '偏弱' : '中和'
  let congGe = ''
  if (score <= 1.5) {
    level = '极弱'
    congGe = '（三得皆失，疑似从弱格，宜顺其弱势以官杀财食为用，忌印比帮身）'
  } else if (score >= 9) {
    level = '极旺'
    congGe = '（三得俱全，疑似从强格，宜顺其旺势以印比为用，忌官杀克身）'
  }
  const detail = [
    lingTxt,
    diPillars.length ? `得地：${diPillars.join('、')}` : '得地：年日时支主气无同类通根',
    `得势：${ganTong.length ? ganTong.join('、') : '天干无同党帮扶'}（日主自身计1）`,
    `三得评分 ${score.toFixed(1)}/10，判定：${level}${congGe}`
  ].join('；')
  return { score, level, detail }
}

/** 喜用神与忌神：扶抑为主（从格时顺势），调候另列 */
function yongShen(bazi: any, level: string): string {
  const d = GAN_WX[bazi.日柱.天干.天干]
  if (level === '极旺') {
    return `从强论命：喜${SHENG_WO[d]}（印绶）、${d}（比劫）顺势；忌${KE_WO[d]}（官杀）逆势克身。`
  }
  if (level === '极弱') {
    return `从弱论命：喜${SHENG[d]}（食伤）、${KE[d]}（财星）、${KE_WO[d]}（官杀）顺势；忌${SHENG_WO[d]}（印）、${d}（比劫）帮身逆势。`
  }
  if (level === '偏强') {
    return `身强宜克泄耗：喜${SHENG[d]}（食伤泄秀）、${KE[d]}（财星耗身）、${KE_WO[d]}（官杀制身）；忌${SHENG_WO[d]}（印绶生身）、${d}（比劫帮身）。`
  }
  if (level === '偏弱') {
    return `身弱宜生扶：喜${SHENG_WO[d]}（印绶生身）、${d}（比劫帮身）；忌食伤、财星、官杀过度克泄。`
  }
  return `中和之局，重在五行流通：行运补其最弱、泄其最旺者为佳，调候参考【穷通调候】。`
}

/** 《穷通宝鉴》调候：十日主取用 + 四季需求 */
function tiaoHou(bazi: any): string {
  const dayGan = bazi.日柱.天干.天干
  const monthZhi = bazi.月柱.地支.地支
  const dm = DAYMASTER_TUNGTONG[dayGan] || ''
  const se = SEASON_TUNGTONG[monthZhi]
  const seTxt = se ? `生于${monthZhi}月（${se.season}季）：宜${se.need}；注意：${se.caution}` : ''
  return `日主${dayGan}，${dm}。${seTxt}`
}

/** 月令取格（《子平真诠》：藏干透出者取格，比劫不取正格）。返回格局名+依据 */
function geJu(bazi: any): { name: string; detail: string } {
  const mZhi = bazi.月柱.地支.地支
  const mHD = bazi.月柱.地支.藏干
  const tianGan: Record<string, string> = {}
  for (const k of ['年柱', '月柱', '时柱']) tianGan[bazi[k].天干.天干] = k.replace('柱', '干')
  const order: Array<[string, any]> = [['主气', mHD.主气], ['中气', mHD.中气], ['余气', mHD.余气]]
  for (const [qi, h] of order) {
    if (!h) continue
    const tou = tianGan[h.天干]
    if (tou) {
      const name = h.十神 === '比肩' ? '建禄格' : h.十神 === '劫财' ? '月劫格' : `${h.十神}格`
      return { name, detail: `${name}（月令${mZhi}中${h.天干}（${h.十神}）为${qi}，透于${tou}）` }
    }
  }
  const zhu = mHD.主气
  const name = !zhu ? '无从取格' : zhu.十神 === '比肩' ? '建禄格' : zhu.十神 === '劫财' ? '月劫格' : `${zhu.十神}格`
  return { name, detail: `${name}（月令${mZhi}本气${zhu ? zhu.天干 + '（' + zhu.十神 + '）' : ''}不透，以本气取格）` }
}

/** 刑冲合会提炼：'甲己合土(月-时)' 式，去重 */
function relationSummary(rel: any): string {
  const order = ['年', '月', '日', '时']
  const seen = new Set<string>()
  const parts: string[] = []
  for (const zhu of order) {
    const node = rel?.[zhu]
    if (!node) continue
    for (const kind of ['天干', '地支']) {
      const sub = node[kind]
      if (!sub) continue
      for (const act of Object.keys(sub)) {
        for (const item of sub[act] || []) {
          const pair = [zhu, item.柱].sort((a, b) => order.indexOf(a) - order.indexOf(b)).join('-')
          // 去重键去掉干支字（"亥申相害"与"申亥相害"视为同一作用）
          const key = pair + String(item.知识点).replace(/[甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳午未申酉戌亥]/g, '')
          if (!seen.has(key)) {
            seen.add(key)
            parts.push(`${item.知识点}(${pair})`)
          }
        }
      }
    }
  }
  return parts.length ? parts.join('、') : '原局无明显刑冲合会'
}

/** 神煞：只列非空柱 */
function shenShaSummary(s: any): string {
  const parts = Object.entries(s || {})
    .filter(([, v]) => (v as string[]).length > 0)
    .map(([k, v]) => `${k}:${(v as string[]).join('、')}`)
  return parts.length ? parts.join('；') : '无'
}

/**
 * gender: 0男 1女（应用约定）；bazi-mcp 内部约定为 1男 0女，此处转换。
 */
export function calcBazi(y: number, m: number, d: number, hour: number, gender: number): BaziLite {
  const g = gender === 0 ? 1 : 0
  const solarTime = SolarTime.fromYmdHms(y, m, d, hour, 0, 0)
  const lunarHour = solarTime.getLunarHour()
  const bazi = buildBazi({ lunarHour: lunarHour, gender: g, eightCharProviderSect: 2 })

  // ---- 本地子平分析 ----
  const w = wuxingCount(bazi)
  const total = Object.values(w).reduce((a, b) => a + b, 0)
  const wDesc = Object.entries(w)
    .map(([k, v]) => `${k}${((v / total) * 100).toFixed(0)}%`)
    .join(' ')
  const lack = Object.entries(w).filter(([, v]) => v < 0.05).map(([k]) => k)
  const st = strengthAnalysis(bazi)
  const yong = yongShen(bazi, st.level)
  const tiao = tiaoHou(bazi)
  const ge = geJu(bazi)
  const geCheck = GEJU_CHECK[ge.name]
  const geTxt = ge.detail + (geCheck
    ? `。成格条件：${geCheck.cheng}；破格风险：${geCheck.bai}——请对照命局干支逐项论证成格或破格`
    : '')
  const rel = relationSummary(bazi.刑冲合会)
  const dy = bazi.大运
  const dyDesc = (dy.大运 || [])
    .map((d2: any) => `${d2.干支}(${d2.开始年龄}-${d2.结束年龄}岁·${d2.天干十神})`)
    .join(' ')
  const ganInfo = ZHU_NAME.map((k) => {
    const p = bazi[k].天干
    return p.十神 ? `${k.replace('柱', '')}干${p.天干}为${p.十神}` : ''
  }).filter(Boolean).join('，')

  const summary = [
    '【基础排盘】',
    `性别：${bazi.性别}｜阳历：${bazi.阳历}｜农历：${bazi.农历}｜生肖：${bazi.生肖}`,
    `八字：${bazi.八字}｜日主：${bazi.日主}（${GAN_WX[bazi.日主]}，${bazi.日柱.天干.阴阳}）`,
    ...pillarInfo(bazi),
    `命宫：${bazi.命宫}｜胎元：${bazi.胎元}｜身宫：${bazi.身宫}`,
    '【十神】' + ganInfo,
    '【五行力量】' + wDesc + (lack.length ? `｜五行缺${lack.join('')}` : '｜五行俱全'),
    '【日主强弱】' + st.detail,
    '【穷通调候】' + tiao,
    '【喜用神】' + yong,
    '【格局】' + geTxt,
    '【刑冲合会】' + rel,
    '【神煞】' + shenShaSummary(bazi.神煞),
    `【大运】${dy.起运年龄}岁起运：${dyDesc}`
  ].join('\n')

  return {
    baziShort: `${bazi.八字} · ${bazi.生肖}`,
    summary: summary
  }
}
