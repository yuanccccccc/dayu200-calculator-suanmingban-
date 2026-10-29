// 纳音
const NAYIN_WUXING = {
    甲子: '金',
    甲午: '金',
    丙寅: '火',
    丙申: '火',
    戊辰: '木',
    戊戌: '木',
    庚午: '土',
    庚子: '土',
    壬申: '金',
    壬寅: '金',
    甲戌: '火',
    甲辰: '火',
    丙子: '水',
    丙午: '水',
    戊寅: '土',
    戊申: '土',
    庚辰: '金',
    庚戌: '金',
    壬午: '木',
    壬子: '木',
    甲申: '水',
    甲寅: '水',
    丙戌: '土',
    丙辰: '土',
    戊子: '火',
    戊午: '火',
    庚寅: '木',
    庚申: '木',
    壬辰: '水',
    壬戌: '水',
    乙丑: '金',
    乙未: '金',
    丁卯: '火',
    丁酉: '火',
    己巳: '木',
    己亥: '木',
    辛未: '土',
    辛丑: '土',
    癸酉: '金',
    癸卯: '金',
    乙亥: '火',
    乙巳: '火',
    丁丑: '水',
    丁未: '水',
    己卯: '土',
    己酉: '土',
    辛巳: '金',
    辛亥: '金',
    癸未: '木',
    癸丑: '木',
    乙酉: '水',
    乙卯: '水',
    丁亥: '土',
    丁巳: '土',
    己丑: '火',
    己未: '火',
    辛卯: '木',
    辛酉: '木',
    癸巳: '水',
    癸亥: '水',
};
const XUN = {
    甲子: '甲子',
    乙丑: '甲子',
    丙寅: '甲子',
    丁卯: '甲子',
    戊辰: '甲子',
    己巳: '甲子',
    庚午: '甲子',
    辛未: '甲子',
    壬申: '甲子',
    癸酉: '甲子',
    甲戌: '甲戌',
    乙亥: '甲戌',
    丙子: '甲戌',
    丁丑: '甲戌',
    戊寅: '甲戌',
    己卯: '甲戌',
    庚辰: '甲戌',
    辛巳: '甲戌',
    壬午: '甲戌',
    癸未: '甲戌',
    甲申: '甲申',
    乙酉: '甲申',
    丙戌: '甲申',
    丁亥: '甲申',
    戊子: '甲申',
    己丑: '甲申',
    庚寅: '甲申',
    辛卯: '甲申',
    壬辰: '甲申',
    癸巳: '甲申',
    甲午: '甲午',
    乙未: '甲午',
    丙申: '甲午',
    丁酉: '甲午',
    戊戌: '甲午',
    己亥: '甲午',
    庚子: '甲午',
    辛丑: '甲午',
    壬寅: '甲午',
    癸卯: '甲午',
    甲辰: '甲辰',
    乙巳: '甲辰',
    丙午: '甲辰',
    丁未: '甲辰',
    戊申: '甲辰',
    己酉: '甲辰',
    庚戌: '甲辰',
    辛亥: '甲辰',
    壬子: '甲辰',
    癸丑: '甲辰',
    甲寅: '甲寅',
    乙卯: '甲寅',
    丙辰: '甲寅',
    丁巳: '甲寅',
    戊午: '甲寅',
    己未: '甲寅',
    庚申: '甲寅',
    辛酉: '甲寅',
    壬戌: '甲寅',
    癸亥: '甲寅',
};
// 干支阴阳，1代表阳，0代表阴
const GAN_YINYANG = {
    甲: 1,
    乙: 0,
    丙: 1,
    丁: 0,
    戊: 1,
    己: 0,
    庚: 1,
    辛: 0,
    壬: 1,
    癸: 0,
};
// 天乙贵人
const TIANYIGUIREN_MAP = {
    甲: '丑未',
    乙: '子申',
    丙: '亥酉',
    丁: '亥酉',
    戊: '丑未',
    己: '子申',
    庚: '丑未',
    辛: '午寅',
    壬: '卯巳',
    癸: '卯巳',
};
const grabTianyiguiren = (dayGan, yearGan, zhi) => {
    if (TIANYIGUIREN_MAP[yearGan].includes(zhi) || TIANYIGUIREN_MAP[dayGan].includes(zhi)) {
        return '天乙贵人';
    }
};
// 天德贵人
const TIANDEGUIREN_MAP = {
    寅: '丁',
    卯: '申',
    辰: '壬',
    巳: '辛',
    午: '亥',
    未: '甲',
    申: '癸',
    酉: '寅',
    戌: '丙',
    亥: '乙',
    子: '巳',
    丑: '庚',
};
const grabTiandeguiren = (monthZhi, ganzhi) => {
    if (ganzhi.includes(TIANDEGUIREN_MAP[monthZhi])) {
        return '天德贵人';
    }
};
// 月德贵人
const YUEDEGUIREN_MAP = {
    寅: '丙',
    午: '丙',
    戌: '丙',
    申: '壬',
    子: '壬',
    辰: '壬',
    亥: '甲',
    卯: '甲',
    未: '甲',
    巳: '庚',
    酉: '庚',
    丑: '庚',
};
const grabYuedeguiren = (monthZhi, ganzhi) => {
    if (ganzhi.includes(YUEDEGUIREN_MAP[monthZhi])) {
        return '月德贵人';
    }
};
// 天德合
const TIANDEHE_MAP = {
    寅: '壬',
    卯: '巳',
    辰: '丁',
    巳: '丙',
    午: '寅',
    未: '己',
    申: '戊',
    酉: '亥',
    戌: '辛',
    亥: '庚',
    子: '申',
    丑: '乙',
};
const grabTiandehe = (monthZhi, ganzhi) => {
    if (ganzhi.includes(TIANDEHE_MAP[monthZhi])) {
        return '天德合';
    }
};
// 月德合
const YUEDEHE_MAP = {
    寅: '辛',
    午: '辛',
    戌: '辛',
    申: '丁',
    子: '丁',
    辰: '丁',
    巳: '乙',
    酉: '乙',
    丑: '乙',
    亥: '己',
    卯: '己',
    未: '己',
};
const grabYuedehe = (monthZhi, gan) => {
    if (YUEDEHE_MAP[monthZhi] === gan) {
        return '月德合';
    }
};
// 天赦日
const TIANSHERI_MAP = {
    寅: '戊寅',
    卯: '戊寅',
    辰: '戊寅',
    巳: '甲午',
    午: '甲午',
    未: '甲午',
    申: '戊申',
    酉: '戊申',
    戌: '戊申',
    亥: '甲子',
    子: '甲子',
    丑: '甲子',
};
const grabTiansheri = (monthZhi, dayGanzhi) => {
    if (TIANSHERI_MAP[monthZhi] === dayGanzhi) {
        return '天赦星';
    }
};
// 禄神
const LUSHEN_MAP = {
    甲: '寅',
    乙: '卯',
    丙: '巳',
    丁: '午',
    戊: '巳',
    己: '午',
    庚: '申',
    辛: '酉',
    壬: '亥',
    癸: '子',
};
const grabLushen = (dayGan, zhi) => {
    if (LUSHEN_MAP[dayGan] === zhi) {
        return '禄神';
    }
};
// 驿马
const YIMA_MAP = {
    申: '寅',
    子: '寅',
    辰: '寅',
    寅: '申',
    午: '申',
    戌: '申',
    巳: '亥',
    酉: '亥',
    丑: '亥',
    亥: '巳',
    卯: '巳',
    未: '巳',
};
const grabYima = (yearOrDayZhi, restZhi) => {
    if (YIMA_MAP[yearOrDayZhi] === restZhi) {
        return '驿马';
    }
};
// 太极贵人
const TAIJIGUIREN_MAP = {
    甲: '子午',
    乙: '子午',
    丙: '酉卯',
    丁: '酉卯',
    戊: '辰戌丑未',
    己: '辰戌丑未',
    庚: '寅亥',
    辛: '寅亥',
    壬: '巳申',
    癸: '巳申',
};
const grabTaijiguiren = (dayGan, yearGan, zhi) => {
    if (TAIJIGUIREN_MAP[dayGan].includes(zhi) || TAIJIGUIREN_MAP[yearGan].includes(zhi)) {
        return '太极贵人';
    }
};
// 将星
const JIANGXING_MAP = {
    子: '子',
    丑: '酉',
    寅: '午',
    卯: '卯',
    辰: '子',
    巳: '酉',
    午: '午',
    未: '卯',
    申: '子',
    酉: '酉',
    戌: '午',
    亥: '卯',
};
const grabJiangxing = (yearOrDayZhi, restZhi) => {
    if (JIANGXING_MAP[yearOrDayZhi] === restZhi) {
        return '将星';
    }
};
// 学堂 - 两种算法都加上
const XUETANG_MAP = {
    金: '巳',
    木: '亥',
    水: '申',
    土: '申',
    火: '寅',
    甲: '己亥',
    乙: '壬午',
    丙: '丙寅',
    丁: '丁酉',
    戊: '戊寅',
    己: '己酉',
    庚: '辛巳',
    辛: '甲子',
    壬: '甲申',
    癸: '乙卯',
};
const grabXuetang = (yearNayinWuxing, dayGan, ganzhi) => {
    if (XUETANG_MAP[yearNayinWuxing] === ganzhi[1] || XUETANG_MAP[dayGan] === ganzhi) {
        return '学堂'; // 不分正学堂
    }
};
// 词馆 - 两种算法都加上
const CIGUAN_MAP = {
    金: '申',
    木: '寅',
    水: '亥',
    土: '亥',
    火: '巳',
    甲: '庚寅',
    乙: '辛卯',
    丙: '乙巳',
    丁: '戊午',
    戊: '丁巳',
    己: '庚午',
    庚: '壬申',
    辛: '癸酉',
    壬: '癸亥',
    癸: '壬戌',
};
const grabCiguan = (yearNayinWuxing, dayGan, ganzhi) => {
    if (CIGUAN_MAP[yearNayinWuxing] === ganzhi[1] || CIGUAN_MAP[dayGan] === ganzhi) {
        return '词馆'; // 不分正词馆
    }
};
// 国印贵人
const GUOYINGUIREN_MAP = {
    甲: '戌',
    乙: '亥',
    丙: '丑',
    丁: '寅',
    戊: '丑',
    己: '寅',
    庚: '辰',
    辛: '巳',
    壬: '未',
    癸: '申',
};
const grabGuoyinguiren = (dayGan, yearGan, zhi) => {
    if (GUOYINGUIREN_MAP[dayGan] === zhi || GUOYINGUIREN_MAP[yearGan] === zhi) {
        return '国印';
    }
};
// 三奇贵人 - 流年里不算
const SANQIGUIREN_MAP = [/甲.*戊.*庚|庚.*戊.*甲/, /乙.*丙.*丁|丁.*丙.*乙/, /壬.*癸.*辛｜辛.*癸.*壬/];
const grabSanqiguiren = (bazi) => {
    for (const combo of SANQIGUIREN_MAP) {
        if (combo.test(bazi)) {
            return '三奇贵人';
        }
    }
};
// 文昌贵人
const WENCHANGGUIREN_MAP = {
    甲: '巳',
    乙: '午',
    丙: '申',
    丁: '酉',
    戊: '申',
    己: '酉',
    庚: '亥',
    辛: '子',
    壬: '寅',
    癸: '卯',
};
const grabWenchangguiren = (dayGan, yearGan, zhi) => {
    if (WENCHANGGUIREN_MAP[dayGan] === zhi || WENCHANGGUIREN_MAP[yearGan] === zhi) {
        return '文昌贵人';
    }
};
// 华盖
const HUAGAI_MAP = {
    寅: '戌',
    午: '戌',
    戌: '戌',
    亥: '未',
    卯: '未',
    未: '未',
    申: '辰',
    子: '辰',
    辰: '辰',
    巳: '丑',
    酉: '丑',
    丑: '丑',
};
const grabHuagai = (yearOrDayZhi, restZhi) => {
    if (HUAGAI_MAP[yearOrDayZhi] === restZhi) {
        return '华盖';
    }
};
// 天医
const TIANYI_MAP = {
    寅: '丑',
    卯: '寅',
    辰: '卯',
    巳: '辰',
    午: '巳',
    未: '午',
    申: '未',
    酉: '申',
    戌: '酉',
    亥: '戌',
    子: '亥',
    丑: '子',
};
const grabTianyi = (monthZhi, restZhi) => {
    if (TIANYI_MAP[monthZhi] === restZhi) {
        return '天医星';
    }
};
// 金舆
const JINYU_MAP = {
    甲: '辰',
    乙: '巳',
    丙: '未',
    丁: '申',
    戊: '未',
    己: '申',
    庚: '戌',
    辛: '亥',
    壬: '丑',
    癸: '寅',
};
const grabJinyu = (yearGan, dayGan, zhi) => {
    if (JINYU_MAP[yearGan] === zhi || JINYU_MAP[dayGan] === zhi) {
        return '金舆';
    }
};
// 空亡
const KONGWANG_MAP = {
    甲子: '戌亥',
    甲戌: '申酉',
    甲申: '午未',
    甲午: '辰巳',
    甲辰: '寅卯',
    甲寅: '子丑',
};
const grabKongwang = (yearOrDayXun, restZhi) => {
    if (KONGWANG_MAP[yearOrDayXun].includes(restZhi)) {
        return '空亡';
    }
};
// 灾煞
const ZAISHA_MAP = {
    申: '午',
    子: '午',
    辰: '午',
    亥: '酉',
    卯: '酉',
    未: '酉',
    寅: '子',
    午: '子',
    戌: '子',
    巳: '卯',
    酉: '卯',
    丑: '卯',
};
const grabZaisha = (yearZhi, restZhi) => {
    if (ZAISHA_MAP[yearZhi] === restZhi) {
        return '灾煞';
    }
};
// 劫煞
const JIESHA_MAP = {
    寅: '亥',
    午: '亥',
    戌: '亥',
    申: '巳',
    子: '巳',
    辰: '巳',
    巳: '寅',
    酉: '寅',
    丑: '寅',
    亥: '申',
    卯: '申',
    未: '申',
};
const grabJiesha = (yearOrDayZhi, restZhi) => {
    if (JIESHA_MAP[yearOrDayZhi] === restZhi) {
        return '劫煞';
    }
};
// 亡神
const WANGSHEN_MAP = {
    寅: '巳',
    午: '巳',
    戌: '巳',
    申: '亥',
    子: '亥',
    辰: '亥',
    亥: '寅',
    卯: '寅',
    未: '寅',
    巳: '申',
    酉: '申',
    丑: '申',
};
const grabWangsheng = (yearOrDayZhi, restZhi) => {
    if (WANGSHEN_MAP[yearOrDayZhi] === restZhi) {
        return '亡神';
    }
};
// 羊刃
const YANGREN_MAP = {
    甲: '卯',
    乙: '寅',
    丙: '午',
    丁: '巳',
    戊: '午',
    己: '巳',
    庚: '酉',
    辛: '申',
    壬: '子',
    癸: '亥',
};
const grabYangren = (dayGan, zhi) => {
    if (YANGREN_MAP[dayGan] === zhi) {
        return '羊刃';
    }
};
// 飞刃
const FEIREN_MAP = {
    甲: '酉',
    乙: '申',
    丙: '子',
    丁: '亥',
    戊: '子',
    己: '亥',
    庚: '卯',
    辛: '寅',
    壬: '午',
    癸: '巳',
};
const grabFeiren = (dayGan, zhi) => {
    if (FEIREN_MAP[dayGan] === zhi) {
        return '飞刃';
    }
};
// 血刃
const XUEREN_MAP = {
    寅: '丑',
    卯: '未',
    辰: '寅',
    巳: '申',
    午: '卯',
    未: '酉',
    申: '辰',
    酉: '戌',
    戌: '巳',
    亥: '亥',
    子: '午',
    丑: '子',
};
const grabXueren = (monthZhi, zhi) => {
    if (XUEREN_MAP[monthZhi] === zhi) {
        return '血刃';
    }
};
// 流霞
const LIUXIA_MAP = {
    甲: '酉',
    乙: '戌',
    丙: '未',
    丁: '申',
    戊: '巳',
    己: '午',
    庚: '辰',
    辛: '卯',
    壬: '亥',
    癸: '寅',
};
const grabLiuxia = (dayGan, zhi) => {
    if (LIUXIA_MAP[dayGan] === zhi) {
        return '流霞';
    }
};
// 四废日
const SIFEIRI_MAP = {
    寅: ['庚申', '辛酉'],
    卯: ['庚申', '辛酉'],
    辰: ['庚申', '辛酉'],
    巳: ['壬子', '癸亥'],
    午: ['壬子', '癸亥'],
    未: ['壬子', '癸亥'],
    申: ['甲寅', '乙卯'],
    酉: ['甲寅', '乙卯'],
    戌: ['甲寅', '乙卯'],
    亥: ['丙午', '丁巳'],
    子: ['丙午', '丁巳'],
    丑: ['丙午', '丁巳'],
};
const grabSifeiri = (monthZhi, dayGanzhi) => {
    if (SIFEIRI_MAP[monthZhi].includes(dayGanzhi)) {
        return '四废';
    }
};
// 天罗地网 - 算法1
const grabTianluodiwang2 = (yearNayin, dayZhi) => {
    if (yearNayin === '火') {
        if (dayZhi === '戌' || dayZhi === '亥') {
            return '天罗地网';
        }
    }
    else if (yearNayin === '水' || yearNayin === '土') {
        if (dayZhi === '辰' || dayZhi === '巳') {
            return '天罗地网';
        }
    }
};
// 天罗地网 - 算法2
const TIANLUODIWANG_MAP = ['戌亥', '辰巳', '亥戌', '巳辰'];
const grabTianluodiwang1 = (yearOrDayZhi, restZhi) => {
    if (TIANLUODIWANG_MAP.includes(yearOrDayZhi + restZhi)) {
        return '天罗地网';
    }
};
// 桃花
const TAOHUA_MAP = {
    申: '酉',
    子: '酉',
    辰: '酉',
    寅: '卯',
    午: '卯',
    戌: '卯',
    巳: '午',
    酉: '午',
    丑: '午',
    亥: '子',
    卯: '子',
    未: '子',
};
const grabTaohua = (yearOrDayZhi, restZhi) => {
    if (TAOHUA_MAP[yearOrDayZhi] === restZhi) {
        return '桃花';
    }
};
// 孤辰
const GUCHEN_MAP = {
    亥: '寅',
    子: '寅',
    丑: '寅',
    寅: '巳',
    卯: '巳',
    辰: '巳',
    巳: '申',
    午: '申',
    未: '申',
    申: '亥',
    酉: '亥',
    戌: '亥',
};
const grabGuchen = (yearZhi, restZhi) => {
    if (GUCHEN_MAP[yearZhi].includes(restZhi)) {
        return '孤辰';
    }
};
// 寡宿
const GUAXIU_MAP = {
    亥: '戌',
    子: '戌',
    丑: '戌',
    寅: '丑',
    卯: '丑',
    辰: '丑',
    巳: '辰',
    午: '辰',
    未: '辰',
    申: '未',
    酉: '未',
    戌: '未',
};
const grabGuaxiu = (yearZhi, restZhi) => {
    if (GUAXIU_MAP[yearZhi] === restZhi) {
        return '寡宿';
    }
};
// 阴差阳错
const YINCHAYANGCUO_MAP = ['丙子', '丙午', '丁丑', '丁未', '戊寅', '戊申', '辛卯', '辛酉', '壬辰', '壬戌', '癸巳', '癸亥'];
const grabYinchayangcuo = (dayGanzhi) => {
    if (YINCHAYANGCUO_MAP.includes(dayGanzhi)) {
        return '阴差阳错';
    }
};
// 魁罡
const KUIGANG_MAP = ['戊戌', '壬辰', '庚戌', '庚辰'];
const grabKuigang = (dayGanzhi) => {
    if (KUIGANG_MAP.includes(dayGanzhi)) {
        return '魁罡';
    }
};
// 孤鸾煞
const GULUANSHA_MAP = ['甲寅', '乙巳', '丙午', '丁巳', '戊午', '戊申', '辛亥', '壬子'];
const grabGuluansha = (dayGanzhi) => {
    if (GULUANSHA_MAP.includes(dayGanzhi)) {
        return '孤鸾';
    }
};
// 红鸾
const HONGLUAN_MAP = {
    子: '卯',
    丑: '寅',
    寅: '丑',
    卯: '子',
    辰: '亥',
    巳: '戌',
    午: '酉',
    未: '申',
    申: '未',
    酉: '午',
    戌: '巳',
    亥: '辰',
};
const grabHongluan = (yearZhi, restZhi) => {
    if (HONGLUAN_MAP[yearZhi] === restZhi) {
        return '红鸾';
    }
};
// 天喜
const TIANXI_MAP = {
    子: '酉',
    丑: '申',
    寅: '未',
    卯: '午',
    辰: '巳',
    巳: '辰',
    午: '卯',
    未: '寅',
    申: '丑',
    酉: '子',
    戌: '亥',
    亥: '戌',
};
const grabTianxi = (yearZhi, restZhi) => {
    if (TIANXI_MAP[yearZhi] === restZhi) {
        return '天喜';
    }
};
// 勾绞煞
const GOUJIAOSHA_MAP = {
    子: '卯',
    丑: '辰',
    寅: '巳',
    卯: '午',
    辰: '未',
    巳: '申',
    午: '酉',
    未: '戌',
    申: '亥',
    酉: '子',
    戌: '丑',
    亥: '寅',
};
const grabGoujiaosha = (yearZhi, restZhi) => {
    if (GOUJIAOSHA_MAP[yearZhi] === restZhi) {
        return '勾绞煞';
    }
};
// 红艳煞
const HONGYANSHA_MAP = {
    甲: '午',
    乙: '午',
    丙: '寅',
    丁: '未',
    戊: '辰',
    己: '辰',
    庚: '戌',
    辛: '酉',
    壬: '子',
    癸: '申',
};
const grabHongyansha = (dayGan, zhi) => {
    if (HONGYANSHA_MAP[dayGan] === zhi) {
        return '红艳';
    }
};
// 十恶大败
const SHIEDABAI_MAP = ['甲辰', '乙巳', '壬申', '丙申', '丁亥', '庚辰', '戊戌', '癸亥', '辛巳', '己丑'];
const grabShiedabai = (dayGanzhi) => {
    if (SHIEDABAI_MAP.includes(dayGanzhi)) {
        return '十恶大败';
    }
};
// 元辰
const YUANCHEN_MAP = {
    同: {
        子: '未',
        丑: '申',
        寅: '酉',
        卯: '戌',
        辰: '亥',
        巳: '子',
        午: '丑',
        未: '寅',
        申: '卯',
        酉: '辰',
        戌: '巳',
        亥: '午',
    },
    异: {
        子: '巳',
        丑: '午',
        寅: '未',
        卯: '申',
        辰: '酉',
        巳: '戌',
        午: '亥',
        未: '子',
        申: '丑',
        酉: '寅',
        戌: '卯',
        亥: '辰',
    },
};
const grabYuanchen = (yearYinyang, yearZhi, gender, restZhi) => {
    const key = yearYinyang === gender ? '同' : '异';
    if (YUANCHEN_MAP[key][yearZhi] === restZhi) {
        return '元辰';
    }
};
// 金神
const JINSHEN_MAP = ['乙丑', '己巳', '癸酉'];
const grabJinshen = (dayOrHourGanzhi) => {
    if (JINSHEN_MAP.includes(dayOrHourGanzhi)) {
        return '金神';
    }
};
// 天转
const TIANZHUAN_MAP = {
    寅: '乙卯',
    卯: '乙卯',
    辰: '乙卯',
    巳: '丙午',
    午: '丙午',
    未: '丙午',
    申: '辛酉',
    酉: '辛酉',
    戌: '辛酉',
    亥: '壬子',
    子: '壬子',
    丑: '壬子',
};
const grabTianzhuan = (monthZhi, dayGanzhi) => {
    if (TIANZHUAN_MAP[monthZhi] === dayGanzhi) {
        return '天转';
    }
};
// 地转
const DIZHUAN_MAP = {
    寅: '辛卯',
    卯: '辛卯',
    辰: '辛卯',
    巳: '戊午',
    午: '戊午',
    未: '戊午',
    申: '癸酉',
    酉: '癸酉',
    戌: '癸酉',
    亥: '丙子',
    子: '丙子',
    丑: '丙子',
};
const grabDizhuan = (monthZhi, dayGanzhi) => {
    if (DIZHUAN_MAP[monthZhi] === dayGanzhi) {
        return '地转';
    }
};
// 丧门
const SANGMEN_MAP = {
    子: '寅',
    丑: '卯',
    寅: '辰',
    卯: '巳',
    辰: '午',
    巳: '未',
    午: '申',
    未: '酉',
    申: '戌',
    酉: '亥',
    戌: '子',
    亥: '丑',
};
const grabSangmen = (yearZhi, restZhi) => {
    if (SANGMEN_MAP[yearZhi] === restZhi) {
        return '丧门';
    }
};
// 吊客
const DIAOKE_MAP = {
    子: '戌',
    丑: '亥',
    寅: '子',
    卯: '丑',
    辰: '寅',
    巳: '卯',
    午: '辰',
    未: '巳',
    申: '午',
    酉: '未',
    戌: '申',
    亥: '酉',
};
const grabDiaoke = (yearZhi, restZhi) => {
    if (DIAOKE_MAP[yearZhi] === restZhi) {
        return '吊客';
    }
};
// 披麻
const PIMA_MAP = {
    子: '酉',
    丑: '戌',
    寅: '亥',
    卯: '子',
    辰: '丑',
    巳: '寅',
    午: '卯',
    未: '辰',
    申: '巳',
    酉: '午',
    戌: '未',
    亥: '申',
};
const grabPima = (yearZhi, restZhi) => {
    if (PIMA_MAP[yearZhi] === restZhi) {
        return '披麻';
    }
};
// 十灵日
const SHILINGRI_MAP = ['甲辰', '乙亥', '丙辰', '丁酉', '戊午', '庚戌', '庚寅', '辛亥', '壬寅', '癸未'];
const grabShilingri = (dayGanzhi) => {
    if (SHILINGRI_MAP.includes(dayGanzhi)) {
        return '十灵';
    }
};
// 六秀日
const LIUXIURI_MAP = ['丙午', '丁未', '戊子', '戊午', '己丑', '己未'];
const grabLiuxiuri = (dayGanzhi) => {
    if (LIUXIURI_MAP.includes(dayGanzhi)) {
        return '六秀';
    }
};
// 八专
const BAZHUAN_MAP = ['甲寅', '乙卯', '丁未', '戊戌', '己未', '庚申', '辛酉', '癸丑'];
const grabBazhuan = (dayGanzhi) => {
    if (BAZHUAN_MAP.includes(dayGanzhi)) {
        return '八专';
    }
};
// 九丑
const JIUCHOU_MAP = ['丁酉', '戊子', '戊午', '己卯', '己酉', '辛卯', '辛酉', '壬子', '壬午'];
const grabJiuchou = (dayGanzhi) => {
    if (JIUCHOU_MAP.includes(dayGanzhi)) {
        return '九丑';
    }
};
// 童子煞
const grabTongzisha = (monthZhi, yearNayinWuxing, restZhi) => {
    // 春秋寅子贵，冬夏卯未辰
    if ('寅卯辰申酉戌'.includes(monthZhi)) {
        if (restZhi === '寅' || restZhi === '子') {
            return '童子煞';
        }
    }
    else if ('巳午未亥子丑'.includes(monthZhi)) {
        if (restZhi === '卯' || restZhi === '未' || restZhi === '辰') {
            return '童子煞';
        }
    }
    // 金木马卯合，水火鸡犬多；土命逢辰巳，童子定不错。
    if (yearNayinWuxing === '金' || yearNayinWuxing === '木') {
        if (restZhi === '午' || restZhi === '卯') {
            return '童子煞';
        }
    }
    else if (yearNayinWuxing === '水' || yearNayinWuxing === '火') {
        if (restZhi === '酉' || restZhi === '戌') {
            return '童子煞';
        }
    }
    else if (yearNayinWuxing === '土') {
        if (restZhi === '辰' || restZhi === '巳') {
            return '童子煞';
        }
    }
};
// 天厨贵人
const TIANCHUGUIREN_MAP = {
    甲: '巳',
    乙: '午',
    丙: '巳',
    丁: '午',
    戊: '申',
    己: '酉',
    庚: '亥',
    辛: '子',
    壬: '寅',
    癸: '卯',
};
const grabTianchuguiren = (yearGan, dayGan, restZhi) => {
    if (TIANCHUGUIREN_MAP[yearGan] === restZhi || TIANCHUGUIREN_MAP[dayGan] === restZhi) {
        return '天厨贵人';
    }
};
// 福星贵人
const FUXINGGUIREN_MAP = {
    甲: '寅子',
    乙: '卯丑',
    丙: '寅子',
    丁: '亥',
    戊: '申',
    己: '未',
    庚: '午',
    辛: '巳',
    壬: '辰',
    癸: '卯丑',
};
const grabFuxingguiren = (yearGan, dayGan, zhi) => {
    if (FUXINGGUIREN_MAP[yearGan].includes(zhi) || FUXINGGUIREN_MAP[dayGan].includes(zhi)) {
        return '福星贵人';
    }
};
// 德秀贵人
const DEXIUGUIREN_MAP = {
    寅午戌: '丙丁戊癸',
    申子辰: '壬癸戊丙辛甲己',
    巳酉丑: '庚辛乙',
    亥卯未: '甲乙丁壬',
};
const grabDexiuguiren = (monthZhi, gan) => {
    for (const [key, value] of Object.entries(DEXIUGUIREN_MAP)) {
        if (key.includes(monthZhi) && value.includes(gan)) {
            return '德秀贵人';
        }
    }
};
// 拱禄
const GONGLU_MAP = {
    癸亥: '癸丑',
    癸丑: '癸亥',
    丁巳: '丁未',
    己未: '己巳',
    戊辰: '戊午',
};
const grabGonglu = (dayGanzhi, hourGanzhi) => {
    if (GONGLU_MAP[dayGanzhi] === hourGanzhi) {
        return '拱禄';
    }
};
// 天官贵人 - extra
const TIANGUANGUIREN_MAP = {
    甲: '未',
    乙: '辰',
    丙: '巳',
    丁: '酉',
    戊: '戌',
    己: '卯',
    庚: '丑',
    辛: '申',
    壬: '寅',
    癸: '午',
};
const grabTianguanguiren = (dayGan, yearGan, zhi) => {
    if (TIANGUANGUIREN_MAP[yearGan] === zhi || TIANGUANGUIREN_MAP[dayGan] === zhi) {
        return '天官贵人';
    }
};
// 披头 - extra
const PITOU_MAP = {
    子: '辰',
    丑: '卯',
    寅: '寅',
    卯: '丑',
    辰: '子',
    巳: '亥',
    午: '戌',
    未: '酉',
    申: '申',
    酉: '未',
    戌: '午',
    亥: '巳',
};
const grabPitou = (yearZhi, restZhi) => {
    if (PITOU_MAP[yearZhi] === restZhi) {
        return '披头';
    }
};
// 六厄 - extra
const LIUER_MAP = {
    寅: '酉',
    午: '酉',
    戌: '酉',
    申: '卯',
    子: '卯',
    辰: '卯',
    亥: '午',
    卯: '午',
    未: '午',
    巳: '子',
    酉: '子',
    丑: '子',
};
const grabLiuer = (yearZhi, restZhi) => {
    if (LIUER_MAP[yearZhi] === restZhi) {
        return '披头';
    }
};
// 进神 - extra
const JINSHENX_MAP = ['甲子', '甲午', '己卯', '己酉'];
const grabJinshenx = (dayGanzhi) => {
    if (JINSHENX_MAP.includes(dayGanzhi)) {
        return '进神';
    }
};
// 隔角煞 - extra
const GEJIAO_SHA = {
    子: '寅',
    丑: '卯',
    寅: '辰',
    卯: '巳',
    辰: '午',
    巳: '未',
    午: '申',
    未: '酉',
    申: '戌',
    酉: '亥',
    戌: '子',
    亥: '丑',
};
const grabGejiaosha = (dayZhi, hourZhi) => {
    if (GEJIAO_SHA[dayZhi] === hourZhi) {
        return '隔角煞';
    }
};
export const getShen = (sizhu, gender, extraGanzhiList = []) => {
    const bazi = sizhu.replaceAll(' ', '');
    const ganzhiList = [bazi.slice(0, 2), bazi.slice(2, 4), bazi.slice(4, 6), bazi.slice(6, 8)];
    const yearGanzhi = ganzhiList[0];
    const monthGanzhi = ganzhiList[1];
    const dayGanzhi = ganzhiList[2];
    const hourGanzhi = ganzhiList[3];
    const yearGan = yearGanzhi[0];
    const yearZhi = yearGanzhi[1];
    const monthZhi = monthGanzhi[1];
    const dayGan = dayGanzhi[0];
    const dayZhi = dayGanzhi[1];
    const hourZhi = hourGanzhi[1];
    const yearXun = XUN[yearGanzhi];
    const dayXun = XUN[dayGanzhi];
    const yearNayinWuxing = NAYIN_WUXING[yearGanzhi];
    // 分别放年、月、日、时、额外柱的神煞列表
    const gods = [new Set(), new Set(), new Set(), new Set()];
    for (let i = 0; i < extraGanzhiList?.length; i++) {
        gods.push(new Set());
        ganzhiList.push(extraGanzhiList[i]);
    }
    // 各柱都需要查的神煞
    for (let i = 0; i < gods.length; i++) {
        gods[i].add(grabTianyiguiren(dayGan, yearGan, ganzhiList[i][1]));
        gods[i].add(grabTiandeguiren(monthZhi, ganzhiList[i]));
        gods[i].add(grabYuedeguiren(monthZhi, ganzhiList[i]));
        gods[i].add(grabTiandehe(monthZhi, ganzhiList[i]));
        gods[i].add(grabYuedehe(monthZhi, ganzhiList[i][0]));
        gods[i].add(grabLushen(dayGan, ganzhiList[i][1]));
        gods[i].add(grabTaijiguiren(dayGan, yearGan, ganzhiList[i][1]));
        gods[i].add(grabGuoyinguiren(dayGan, yearGan, ganzhiList[i][1]));
        gods[i].add(grabWenchangguiren(dayGan, yearGan, ganzhiList[i][1]));
        gods[i].add(grabJinyu(yearGan, dayGan, ganzhiList[i][1]));
        gods[i].add(grabYangren(dayGan, ganzhiList[i][1]));
        gods[i].add(grabFeiren(dayGan, ganzhiList[i][1]));
        gods[i].add(grabXueren(monthZhi, ganzhiList[i][1]));
        gods[i].add(grabLiuxia(dayGan, ganzhiList[i][1]));
        gods[i].add(grabHongyansha(dayGan, ganzhiList[i][1]));
        gods[i].add(grabFuxingguiren(yearGan, dayGan, ganzhiList[i][1]));
        gods[i].add(grabDexiuguiren(monthZhi, ganzhiList[i][0]));
        gods[i].add(grabTianchuguiren(yearGan, dayGan, ganzhiList[i][1]));
        gods[i].add(grabTianguanguiren(dayGan, yearGan, ganzhiList[i][1]));
    }
    // 不在年柱的神煞，通常以年柱为锚
    for (let i = 1; i < gods.length; i++) {
        gods[i].add(grabXuetang(yearNayinWuxing, dayGan, ganzhiList[i]));
        gods[i].add(grabCiguan(yearNayinWuxing, dayGan, ganzhiList[i]));
        gods[i].add(grabZaisha(yearZhi, ganzhiList[i][1]));
        gods[i].add(grabGuchen(yearZhi, ganzhiList[i][1]));
        gods[i].add(grabGuaxiu(yearZhi, ganzhiList[i][1]));
        gods[i].add(grabHongluan(yearZhi, ganzhiList[i][1]));
        gods[i].add(grabTianxi(yearZhi, ganzhiList[i][1]));
        gods[i].add(grabGoujiaosha(yearZhi, ganzhiList[i][1]));
        gods[i].add(grabYuanchen(GAN_YINYANG[yearGan], yearZhi, gender, ganzhiList[i][1]));
        gods[i].add(grabSangmen(yearZhi, ganzhiList[i][1]));
        gods[i].add(grabDiaoke(yearZhi, ganzhiList[i][1]));
        gods[i].add(grabPima(yearZhi, ganzhiList[i][1]));
        gods[i].add(grabPitou(yearZhi, ganzhiList[i][1]));
        gods[i].add(grabLiuer(yearZhi, ganzhiList[i][1]));
    }
    // 不在月柱的神煞，通常以月柱为锚
    for (let i = 0; i < gods.length; i++) {
        if (i !== 1) {
            gods[i].add(grabTianyi(monthZhi, ganzhiList[i][1]));
        }
    }
    // 以年/日柱为锚看其它柱的神煞
    for (let i = 0; i < gods.length; i++) {
        if (i !== 0) {
            gods[i].add(grabJiangxing(yearZhi, ganzhiList[i][1]));
            gods[i].add(grabYima(yearZhi, ganzhiList[i][1]));
            gods[i].add(grabYima(yearZhi, ganzhiList[i][1]));
            gods[i].add(grabHuagai(yearZhi, ganzhiList[i][1]));
            gods[i].add(grabWangsheng(yearZhi, ganzhiList[i][1]));
            gods[i].add(grabJiesha(yearZhi, ganzhiList[i][1]));
            gods[i].add(grabKongwang(yearXun, ganzhiList[i][1]));
            gods[i].add(grabTaohua(yearZhi, ganzhiList[i][1]));
            gods[i].add(grabTianluodiwang1(yearZhi, ganzhiList[i][1]));
        }
        if (i !== 2) {
            gods[i].add(grabJiangxing(dayZhi, ganzhiList[i][1]));
            gods[i].add(grabYima(dayZhi, ganzhiList[i][1]));
            gods[i].add(grabYima(dayZhi, ganzhiList[i][1]));
            gods[i].add(grabHuagai(dayZhi, ganzhiList[i][1]));
            gods[i].add(grabWangsheng(dayZhi, ganzhiList[i][1]));
            gods[i].add(grabJiesha(dayZhi, ganzhiList[i][1]));
            gods[i].add(grabKongwang(dayXun, ganzhiList[i][1]));
            gods[i].add(grabTaohua(dayZhi, ganzhiList[i][1]));
            gods[i].add(grabTianluodiwang1(dayZhi, ganzhiList[i][1]));
        }
    }
    gods[2].add(grabTiansheri(monthZhi, dayGanzhi));
    gods[2].add(grabSanqiguiren(bazi));
    gods[2].add(grabSifeiri(monthZhi, dayGanzhi));
    gods[2].add(grabTianluodiwang2(yearNayinWuxing, dayZhi));
    gods[2].add(grabYinchayangcuo(dayGanzhi));
    gods[2].add(grabKuigang(dayGanzhi));
    gods[2].add(grabGuluansha(dayGanzhi));
    gods[2].add(grabShiedabai(dayGanzhi));
    gods[2].add(grabJinshen(dayGanzhi));
    gods[3].add(grabJinshen(hourGanzhi));
    gods[2].add(grabTianzhuan(monthZhi, dayGanzhi));
    gods[2].add(grabDizhuan(monthZhi, dayGanzhi));
    gods[2].add(grabShilingri(dayGanzhi));
    gods[2].add(grabLiuxiuri(dayGanzhi));
    gods[2].add(grabBazhuan(dayGanzhi));
    gods[2].add(grabJiuchou(dayGanzhi));
    gods[2].add(grabTongzisha(monthZhi, yearNayinWuxing, dayZhi));
    gods[3].add(grabTongzisha(monthZhi, yearNayinWuxing, hourZhi));
    gods[2].add(grabGonglu(dayGanzhi, hourGanzhi));
    gods[2].add(grabJinshenx(dayGanzhi));
    gods[3].add(grabGejiaosha(dayZhi, hourZhi));
    const results = [];
    for (const item of gods) {
        item.delete(undefined);
        results.push(Array.from(item));
    }
    return results;
};
//# sourceMappingURL=shen.js.map