/**
 * 简易计算器 - DAYU200 / OpenHarmony 4.0 (API 9 兼容)
 * 主页面: entry/src/main/ets/pages/Index.ets
 */

@Entry
@Component
struct Index {
  @State display: string = '0'
  private firstOperand: number = 0
  private pendingOp: string = ''
  private waitingForSecond: boolean = false

  // 计算 firstOperand (pendingOp) current
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

  private inputDigit(d: string) {
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
    if (this.display === '错误' || this.waitingForSecond) {
      this.display = '0.'
      this.waitingForSecond = false
    } else if (!this.display.includes('.')) {
      this.display += '.'
    }
  }

  private setOp(op: string) {
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
    if (this.pendingOp === '') return
    let r = this.calc(this.firstOperand, this.current(), this.pendingOp)
    this.display = this.format(r)
    this.pendingOp = ''
    this.firstOperand = 0
    this.waitingForSecond = true
  }

  private clearAll() {
    this.display = '0'
    this.firstOperand = 0
    this.pendingOp = ''
    this.waitingForSecond = false
  }

  private backspace() {
    if (this.display === '错误' || this.waitingForSecond) return
    this.display = this.display.length > 1 ? this.display.slice(0, -1) : '0'
  }

  @Builder
  private btn(label: string, bg: ResourceColor, onTap: () => void) {
    Button(label)
      .fontSize(28)
      .fontColor(Color.White)
      .backgroundColor(bg)
      .width('22%')
      .aspectRatio(1)
      .borderRadius(999)
      .onClick(onTap)
  }

  build() {
    Column() {
      // 显示屏
      Column() {
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
      .width('100%')
      .padding({ left: 24, right: 24, top: 40, bottom: 16 })
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)

      // 按键区
      Column({ space: 14 }) {
        Row({ space: 14 }) {
          this.btn('C', '#A5A5A5', () => this.clearAll())
          this.btn('⌫', '#A5A5A5', () => this.backspace())
          this.btn('%', '#A5A5A5', () => {
            let r = this.current() / 100
            this.display = this.format(r)
          })
          this.btn('÷', '#FF9F0A', () => this.setOp('÷'))
        }
        Row({ space: 14 }) {
          this.btn('7', '#333333', () => this.inputDigit('7'))
          this.btn('8', '#333333', () => this.inputDigit('8'))
          this.btn('9', '#333333', () => this.inputDigit('9'))
          this.btn('×', '#FF9F0A', () => this.setOp('×'))
        }
        Row({ space: 14 }) {
          this.btn('4', '#333333', () => this.inputDigit('4'))
          this.btn('5', '#333333', () => this.inputDigit('5'))
          this.btn('6', '#333333', () => this.inputDigit('6'))
          this.btn('-', '#FF9F0A', () => this.setOp('-'))
        }
        Row({ space: 14 }) {
          this.btn('1', '#333333', () => this.inputDigit('1'))
          this.btn('2', '#333333', () => this.inputDigit('2'))
          this.btn('3', '#333333', () => this.inputDigit('3'))
          this.btn('+', '#FF9F0A', () => this.setOp('+'))
        }
        Row({ space: 14 }) {
          this.btn('0', '#333333', () => this.inputDigit('0'))
          this.btn('.', '#333333', () => this.inputDot())
          this.btn('=', '#FF9F0A', () => this.equals())
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 24 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
