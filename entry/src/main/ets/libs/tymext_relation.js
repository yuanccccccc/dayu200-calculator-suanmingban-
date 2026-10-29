// 天干地支关系计算模块
// 基于Python版本的calculate_relation函数重新实现
// 常量定义
const ZHU_INFO = ['年', '月', '日', '时'];
// 天干五合映射
const GAN_WUHE = {
    甲己: '土',
    乙庚: '金',
    丙辛: '水',
    丁壬: '木',
    戊癸: '火',
    己甲: '土',
    庚乙: '金',
    辛丙: '水',
    壬丁: '木',
    癸戊: '火',
};
// 天干相冲映射 - 与Python版本完全一致
const GAN_CHONG = {
    甲庚: '冲',
    乙辛: '冲',
    丙壬: '冲',
    丁癸: '冲',
    庚甲: '冲',
    辛乙: '冲',
    壬丙: '冲',
    癸丁: '冲',
    甲戊: '尅',
    乙己: '尅',
    丙庚: '尅',
    丁辛: '尅',
    戊壬: '尅',
    己癸: '尅',
    戊甲: '尅',
    己乙: '尅',
    庚丙: '尅',
    辛丁: '尅',
    壬戊: '尅',
    癸己: '尅',
};
// 地支六合映射
const ZHI_LIUHE = {
    子丑: '土',
    寅亥: '木',
    卯戌: '火',
    辰酉: '金',
    巳申: '水',
    午未: '火',
    丑子: '土',
    亥寅: '木',
    戌卯: '火',
    酉辰: '金',
    申巳: '水',
    未午: '火',
};
// 地支六冲映射
const ZHI_CHONG = {
    子午: '冲',
    丑未: '冲',
    寅申: '冲',
    卯酉: '冲',
    辰戌: '冲',
    巳亥: '冲',
    午子: '冲',
    未丑: '冲',
    申寅: '冲',
    酉卯: '冲',
    戌辰: '冲',
    亥巳: '冲',
};
// 地支相害映射
const ZHI_HAI = {
    子未: '害',
    丑午: '害',
    寅巳: '害',
    卯辰: '害',
    申亥: '害',
    酉戌: '害',
    未子: '害',
    午丑: '害',
    巳寅: '害',
    辰卯: '害',
    亥申: '害',
    戌酉: '害',
};
// 地支相破映射
const ZHI_PO = {
    子酉: '破',
    卯午: '破',
    辰丑: '破',
    未戌: '破',
    寅亥: '破',
    巳申: '破',
    酉子: '破',
    午卯: '破',
    丑辰: '破',
    戌未: '破',
    亥寅: '破',
    申巳: '破',
};
// 地支暗合映射 - 与Python版本完全一致
const ZHI_ANHE = {
    寅丑: '暗合',
    午亥: '暗合',
    卯申: '暗合',
    丑寅: '暗合',
    亥午: '暗合',
    申卯: '暗合',
};
// 地支半三合映射 - 新增
const ZHI_HALF_SANHE = {
    申子: '水',
    子辰: '水',
    寅午: '火',
    午戌: '火',
    巳酉: '金',
    酉丑: '金',
    亥卯: '木',
    卯未: '木',
    子申: '水',
    辰子: '水',
    午寅: '火',
    戌午: '火',
    酉巳: '金',
    丑酉: '金',
    卯亥: '木',
    未卯: '木',
};
// 地支三合映射
const ZHI_SANHE = {
    申子辰: '水',
    寅午戌: '火',
    巳酉丑: '金',
    亥卯未: '木',
};
// 地支三会映射
const ZHI_SANHUI = {
    寅卯辰: '木',
    巳午未: '火',
    申酉戌: '金',
    亥子丑: '水',
};
// 地支三刑映射 - 与Python版本完全一致
const ZHI_SANXING = {
    寅巳申: '寅巳申三刑',
    丑未戌: '丑未戌三刑',
};
// 地支二元刑映射 - 与Python版本完全一致
const ZHI_XING = {
    子卯: '刑',
    卯子: '刑',
    辰辰: '刑',
    午午: '刑',
    酉酉: '刑',
    亥亥: '刑',
};
// 地支半三刑映射 - 与Python版本完全一致
const ZHI_HALF_SANXING = {
    寅巳: '刑',
    巳申: '刑',
    寅申: '刑',
    丑未: '刑',
    未戌: '刑',
    丑戌: '刑',
};
// 地支顺序表
const ZHI_ORDER = ['寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥', '子', '丑'];
// 辅助函数：添加关系到结果中
function addToRelation(relationObj, relationType, relationData) {
    if (!relationObj[relationType]) {
        relationObj[relationType] = [];
    }
    relationObj[relationType].push(relationData);
}
// 检查天干相冲
export function checkGanChong(gan1, gan2) {
    const ganStr = gan1 + gan2;
    return GAN_CHONG[ganStr] || false;
}
// 检查天干五合
export function checkGanHe(gan1, gan2) {
    const ganStr = gan1 + gan2;
    return GAN_WUHE[ganStr] || false;
}
// 检查地支六冲
export function checkZhiChong(zhi1, zhi2) {
    const zhiStr = zhi1 + zhi2;
    return ZHI_CHONG[zhiStr] || false;
}
// 检查地支六合
export function checkZhiHe(zhi1, zhi2) {
    const zhiStr = zhi1 + zhi2;
    return ZHI_LIUHE[zhiStr] || false;
}
// 检查地支相害
export function checkZhiHai(zhi1, zhi2) {
    const zhiStr = zhi1 + zhi2;
    return ZHI_HAI[zhiStr] || false;
}
// 检查地支相破
export function checkZhiPo(zhi1, zhi2) {
    const zhiStr = zhi1 + zhi2;
    return ZHI_PO[zhiStr] || false;
}
// 检查地支暗合
function checkZhiAnhe(zhi1, zhi2) {
    const zhiStr = zhi1 + zhi2;
    return ZHI_ANHE[zhiStr] || false;
}
// 检查地支二元刑
export function checkZhiXing(zhi1, zhi2) {
    const zhiStr = zhi1 + zhi2;
    return ZHI_XING[zhiStr] || false;
}
// 检查地支半三合 - 新增
function checkHalfSanhe(zhi1, zhi2) {
    const zhiStr = zhi1 + zhi2;
    return ZHI_HALF_SANHE[zhiStr] || false;
}
// 检查地支三合 - 修复
function checkSanhe(zhiSet) {
    if (zhiSet.size !== 3)
        return false;
    const zhiArray = Array.from(zhiSet).sort();
    for (const [sanhe, element] of Object.entries(ZHI_SANHE)) {
        const sanheArray = Array.from(sanhe).sort();
        if (zhiArray.join('') === sanheArray.join('')) {
            return element;
        }
    }
    return false;
}
// 检查地支三会 - 修复
function checkSanhui(zhiSet) {
    if (zhiSet.size !== 3)
        return false;
    const zhiArray = Array.from(zhiSet).sort();
    for (const [sanhui, element] of Object.entries(ZHI_SANHUI)) {
        const sanhuiArray = Array.from(sanhui).sort();
        if (zhiArray.join('') === sanhuiArray.join('')) {
            return element;
        }
    }
    return false;
}
// 检查地支三刑 - 修复
export function checkSanxing(zhiSet) {
    if (zhiSet.size !== 3)
        return false;
    const zhiArray = Array.from(zhiSet).sort();
    for (const [sanxing, description] of Object.entries(ZHI_SANXING)) {
        const sanxingArray = Array.from(sanxing).sort();
        if (zhiArray.join('') === sanxingArray.join('')) {
            return description;
        }
    }
    return false;
}
// 检查半三刑 - 与Python版本完全一致
export function checkHalfSanxing(zhi1, zhi2) {
    const zhiStr = zhi1 + zhi2;
    const zhiStrReverse = zhi2 + zhi1;
    if (ZHI_HALF_SANXING[zhiStr]) {
        return ZHI_HALF_SANXING[zhiStr];
    }
    else if (ZHI_HALF_SANXING[zhiStrReverse]) {
        return ZHI_HALF_SANXING[zhiStrReverse];
    }
    else {
        return false;
    }
}
// 检查拱夹关系
function checkGongJia(gan1, zhi1, gan2, zhi2) {
    if (gan1 !== gan2)
        return false;
    // 检查拱规则：三合或三会局的头尾
    for (const group of Object.keys(ZHI_SANHE)) {
        if (group.includes(zhi1) && group.includes(zhi2)) {
            const [head, middle, tail] = group;
            if ((zhi1 === head && zhi2 === tail) || (zhi1 === tail && zhi2 === head)) {
                return middle;
            }
        }
    }
    for (const group of Object.keys(ZHI_SANHUI)) {
        if (group.includes(zhi1) && group.includes(zhi2)) {
            const [head, middle, tail] = group;
            if ((zhi1 === head && zhi2 === tail) || (zhi1 === tail && zhi2 === head)) {
                return middle;
            }
        }
    }
    // 检查夹规则：顺序上的隔位
    const idx1 = ZHI_ORDER.indexOf(zhi1);
    const idx2 = ZHI_ORDER.indexOf(zhi2);
    if (idx1 !== -1 && idx2 !== -1) {
        const diff = Math.abs(idx1 - idx2);
        if (diff === 2) {
            const middleZhi = ZHI_ORDER[(Math.min(idx1, idx2) + 1) % ZHI_ORDER.length];
            return middleZhi;
        }
        if (diff === 10) {
            const middleZhi = ZHI_ORDER[(Math.max(idx1, idx2) + 1) % ZHI_ORDER.length];
            return middleZhi;
        }
    }
    return false;
}
// 主函数：计算刑冲合会关系
export function calculateRelation(zhuArray) {
    const relation = {};
    // 初始化关系对象
    for (const zhu of Object.keys(zhuArray)) {
        relation[zhu] = {
            天干: {},
            地支: {},
        };
    }
    // 遍历每个柱
    for (const [zhu1, data1] of Object.entries(zhuArray)) {
        const seenCombinations = new Set();
        for (const [zhu2, data2] of Object.entries(zhuArray)) {
            if (zhu1 === zhu2)
                continue;
            // 天干冲
            const ganChongResult = checkGanChong(data1.天干, data2.天干);
            if (ganChongResult) {
                addToRelation(relation[zhu1].天干, '冲', {
                    柱: zhu2,
                    知识点: `${data1.天干}${data2.天干}相${ganChongResult}`,
                });
            }
            // 天干合
            const ganHeResult = checkGanHe(data1.天干, data2.天干);
            if (ganHeResult) {
                addToRelation(relation[zhu1].天干, '合', {
                    柱: zhu2,
                    知识点: `${data1.天干}${data2.天干}合${ganHeResult}`,
                    元素: ganHeResult,
                });
            }
            // 地支冲
            const zhiChongResult = checkZhiChong(data1.地支, data2.地支);
            if (zhiChongResult) {
                addToRelation(relation[zhu1].地支, '冲', {
                    柱: zhu2,
                    知识点: `${data1.地支}${data2.地支}相${zhiChongResult}`,
                });
            }
            // 地支害
            const zhiHaiResult = checkZhiHai(data1.地支, data2.地支);
            if (zhiHaiResult) {
                addToRelation(relation[zhu1].地支, '害', {
                    柱: zhu2,
                    知识点: `${data1.地支}${data2.地支}相${zhiHaiResult}`,
                    元素: zhiHaiResult,
                });
            }
            // 地支破
            const zhiPoResult = checkZhiPo(data1.地支, data2.地支);
            if (zhiPoResult) {
                addToRelation(relation[zhu1].地支, '破', {
                    柱: zhu2,
                    知识点: `${data1.地支}${data2.地支}相${zhiPoResult}`,
                    元素: zhiPoResult,
                });
            }
            // 地支暗合
            const zhiAnheResult = checkZhiAnhe(data1.地支, data2.地支);
            if (zhiAnheResult) {
                addToRelation(relation[zhu1].地支, '暗合', {
                    柱: zhu2,
                    知识点: `${data1.地支}${data2.地支}${zhiAnheResult}`,
                    元素: zhiAnheResult,
                });
            }
            // 地支合
            const zhiHeResult = checkZhiHe(data1.地支, data2.地支);
            if (zhiHeResult) {
                addToRelation(relation[zhu1].地支, '合', {
                    柱: zhu2,
                    知识点: `${data1.地支}${data2.地支}合${zhiHeResult}`,
                    元素: zhiHeResult,
                });
            }
            // 地支刑（二元）
            const zhiXingResult = checkZhiXing(data1.地支, data2.地支);
            if (zhiXingResult) {
                addToRelation(relation[zhu1].地支, '刑', {
                    柱: zhu2,
                    知识点: `${data1.地支}${data2.地支}相${zhiXingResult}`,
                });
            }
            let sanheFlag = false;
            let sanxingFlag = false;
            // 三合，三会，三刑
            for (const [zhu3, data3] of Object.entries(zhuArray)) {
                if (zhu2 === zhu3 || zhu1 === zhu3)
                    continue;
                const combination = [zhu1, zhu2, zhu3].sort().join('');
                if (seenCombinations.has(combination))
                    continue;
                // 三合
                const sanheResult = checkSanhe(new Set([data1.地支, data2.地支, data3.地支]));
                if (sanheResult) {
                    addToRelation(relation[zhu1].地支, '三合', {
                        柱: zhu2 + zhu3,
                        柱1: zhu2,
                        柱2: zhu3,
                        知识点: `${data1.地支}${data2.地支}${data3.地支}三合${sanheResult}`,
                        元素: sanheResult,
                    });
                    seenCombinations.add(combination);
                    sanheFlag = true;
                }
                // 三会
                const sanhuiResult = checkSanhui(new Set([data1.地支, data2.地支, data3.地支]));
                if (sanhuiResult) {
                    addToRelation(relation[zhu1].地支, '三会', {
                        柱: zhu2 + zhu3,
                        柱1: zhu2,
                        柱2: zhu3,
                        知识点: `${data1.地支}${data2.地支}${data3.地支}三会${sanhuiResult}`,
                        元素: sanhuiResult,
                    });
                    seenCombinations.add(combination);
                }
                // 三刑
                const sanxingResult = checkSanxing(new Set([data1.地支, data2.地支, data3.地支]));
                if (sanxingResult) {
                    addToRelation(relation[zhu1].地支, '三刑', {
                        柱: zhu2 + zhu3,
                        柱1: zhu2,
                        柱2: zhu3,
                        知识点: `${data1.地支}${data2.地支}${data3.地支}三刑`,
                    });
                    seenCombinations.add(combination);
                    sanxingFlag = true;
                }
            }
            // 判断拱夹
            if (data1.天干 === data2.天干) {
                const gongJiaResult = checkGongJia(data1.天干, data1.地支, data2.天干, data2.地支);
                if (gongJiaResult) {
                    relation[zhu1].拱 = {
                        柱: zhu2,
                        知识点: `${zhu1}${zhu2}拱${gongJiaResult}`,
                        拱: gongJiaResult,
                    };
                }
            }
            // 检查半三合（二元）- 新增
            if (!sanheFlag) {
                const halfSanheResult = checkHalfSanhe(data1.地支, data2.地支);
                if (halfSanheResult) {
                    addToRelation(relation[zhu1].地支, '半合', {
                        柱: zhu2,
                        知识点: `${data1.地支}${data2.地支}半合${halfSanheResult}`,
                        元素: halfSanheResult,
                    });
                }
            }
            // 判断部分三刑（二元）
            if (!sanxingFlag) {
                const halfSanxingResult = checkHalfSanxing(data1.地支, data2.地支);
                if (halfSanxingResult) {
                    addToRelation(relation[zhu1].地支, '刑', {
                        柱: zhu2,
                        知识点: `${data1.地支}${data2.地支}刑`,
                    });
                }
            }
        }
    }
    // 处理双合双冲等进阶关系 - 与Python版本完全一致
    for (const [zhu, data] of Object.entries(relation)) {
        const ganChong = data.天干.冲 || [];
        const zhiChong = data.地支.冲 || [];
        const ganHe = data.天干.合 || [];
        const zhiHe = data.地支.合 || [];
        // 双冲处理：只检查同一个柱既有天干冲又有地支冲的情况
        for (const ganRelation of ganChong) {
            for (const zhiRelation of zhiChong) {
                if (ganRelation.柱 === zhiRelation.柱) {
                    if (!data.双冲)
                        data.双冲 = [];
                    data.双冲.push({
                        柱: ganRelation.柱,
                        知识点: `${zhu}与${ganRelation.柱}双冲`,
                    });
                }
            }
        }
        // 双合处理：只检查同一个柱既有天干合又有地支合的情况
        for (const ganRelation of ganHe) {
            for (const zhiRelation of zhiHe) {
                if (ganRelation.柱 === zhiRelation.柱) {
                    if (!data.双合)
                        data.双合 = [];
                    data.双合.push({
                        柱: ganRelation.柱,
                        知识点: `${zhu}与${ganRelation.柱}双合`,
                    });
                }
            }
        }
    }
    // 增加伏吟情况 - 新增
    for (const [zhu1, data1] of Object.entries(zhuArray)) {
        const zhu1GanZhi = data1.天干 + data1.地支;
        for (const [zhu2, data2] of Object.entries(zhuArray)) {
            if (zhu1 === zhu2)
                continue;
            const zhu2GanZhi = data2.天干 + data2.地支;
            if (zhu1GanZhi === zhu2GanZhi) {
                if (!relation[zhu1].伏吟)
                    relation[zhu1].伏吟 = [];
                relation[zhu1].伏吟.push({
                    柱: zhu2,
                    知识点: `${zhu1}柱与${zhu2}柱伏吟`,
                });
            }
        }
    }
    return relation;
}
//# sourceMappingURL=relation.js.map