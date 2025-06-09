import { router } from '@kit.ArkUI'

@Entry
@ComponentV2
struct RunPage {
  @Local isRunning: boolean = true
  @Local time: number = 0

  private intervalID?: number

  private showTime(): string {
    const min = Math.floor(this.time / 60).toString().padStart(2, '0')
    const sec = (this.time % 60).toString().padStart(2, '0')
    return `${min}:${sec}`
  }

  aboutToAppear() {
    this.startTimer()
  }

  aboutToDisappear() {
    this.stopTimer()
  }

  private startTimer() {
    this.stopTimer() // 避免重复启动
    this.intervalID = setInterval(() => {
      if (this.isRunning) {
        this.time++
      }
    }, 1000)
  }

  private stopTimer() {
    if (this.intervalID) {
      clearInterval(this.intervalID)
      this.intervalID = undefined
    }
  }

  build() {
    Column() {
      Image($r('app.media.test_running_map'))
        .height(560)

      Column() {
        Row() {
          this.buildStatItem('0.00', '总距离')
          this.buildStatItem(this.showTime(), '总时长')
          this.buildStatItem('5\'11\'\'', '实时配速')
        }
        .margin({ top: 10 })
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Row() {
          if (this.isRunning) {
            this.buildControlButton('app.media.ic_pause', '#fff', '#3a3340', () => {
              this.isRunning = false
            })
          } else {
            Row({ space: 30 }) {
              this.buildControlButton('', '#fd5b54', Color.White, () => {
                router.back()
              }, 18)
              this.buildControlButton('app.media.ic_play_fill', '#26c688', Color.White, () => {
                this.isRunning = true
              }, 22)
            }
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 20, bottom: 8 })
      }
      .width('100%')
      .padding({ top: 20, left: 20, right: 20, bottom: 40 })
      .backgroundColor('#3a3340')
      .borderRadius({ topLeft: 10, topRight: 10 })
    }
  }

  private buildStatItem(value: string, label: string) {
    Column() {
      Text(value)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .fontSize(28)
        .margin({ left: 14 })

      Text(label)
        .fontColor('#9effffff')
        .fontSize(14)
        .margin({ left: 10 })
    }
  }

  private buildControlButton(icon: string, bgColor: string, iconColor: string, onClick: () => void, size: number = 26) {
    Row() {
      if (icon) {
        Image($r(icon))
          .width(size)
          .fillColor(iconColor)
      } else {
        Row()
          .size(18)
          .backgroundColor(iconColor)
      }
    }
    .backgroundColor(bgColor)
    .width(40)
    .height(40)
    .borderRadius(20)
    .justifyContent(FlexAlign.Center)
    .padding(5)
    .onClick(onClick)
  }
}
