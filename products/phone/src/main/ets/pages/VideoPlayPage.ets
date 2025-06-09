import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem'
import { font, router } from '@kit.ArkUI'
import { ExercisePlanService, WorkoutPlan, WorkoutPlanService } from 'exercise'
import { action } from 'exercise/src/main/ets/model/action'

interface ParamsObj {
  workoutPlan: WorkoutPlan
}

const TOTAL_TIME = 50
const MASK_ANIMATION_DURATION = 400
const OPACITY_ANIMATION_DURATION = 300

@Entry
@ComponentV2
struct VideoPlayPage {
  @Local isPlaying: boolean = true
  @Local time: number = 0
  @Local isCompleted: boolean = false
  @Local maskOpacity: number = 0
  @Local maskImgX: number = 0
  @Local maskImgY: number = 0
  @Local videoUrl: string = ''

  private workoutPlan: WorkoutPlan = new WorkoutPlan()
  private actionList: action[] = []
  private exercisePlanService: WorkoutPlanService = WorkoutPlanService.getInstance()
  controller: VideoController = new VideoController()

  private intervalID?: number

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as ParamsObj
    this.workoutPlan = params.workoutPlan

    if (this.workoutPlan.PlanID != undefined) {
      try {
        this.actionList = await this.exercisePlanService.getActionsByPlanID(this.workoutPlan.PlanID)
        if (this.actionList.length > 0 && this.actionList[0].IntroductionVideo) {
          this.videoUrl = this.actionList[0].IntroductionVideo
        }
      } catch (e) {
        console.error('Failed to load actions:', e)
      }
    }
    this.startTimer()
  }

  aboutToDisappear() {
    this.stopTimer()
  }

  private startTimer() {
    this.stopTimer()
    this.intervalID = setInterval(() => {
      this.time++
    }, 1000)
  }

  private stopTimer() {
    if (this.intervalID) {
      clearInterval(this.intervalID)
      this.intervalID = undefined
    }
  }

  build() {
    Stack() {
      Column() {
        this.renderProgress()
        this.renderWorkoutTitle()
        this.renderVideoPlayer()
        Blank()
        this.renderCompleteButton()
        this.renderControlPanel()
      }
      .fullSize()

      this.renderMaskOverlay()
    }
  }

  private renderProgress() {
    Progress({ value: this.time, total: TOTAL_TIME, type: ProgressType.Linear })
      .style({ strokeWidth: 6, enableSmoothEffect: true })
      .color('#24c789')
      .margin({ top: 20, left: 20, right: 20 })
  }

  private renderWorkoutTitle() {
    Row() {
      Text(`1/14 仰卧交替抬腿`)
        .width('100%')
        .fontColor('#5c5c5f')
        .fontWeight(FontWeight.Medium)
        .fontSize(20)
    }
    .margin({ top: 5, left: 20, right: 20 })
    .justifyContent(FlexAlign.Start)
  }

  private renderVideoPlayer() {
    Video({
      src: $rawfile(this.videoUrl || 'video_leg_rise.mp4'), // fallback处理
      controller: this.controller
    })
      .width('100%')
      .height(300)
      .autoPlay(true)
      .controls(false)
      .loop(true)
      .margin({ top: 100 })
  }

  private renderCompleteButton() {
    Button('完成训练')
      .onClick(() => {
        this.isCompleted = true
        this.maskOpacity = 1
        this.maskImgX = 1
        this.maskImgY = 1
        this.stopTimer()
      })
  }

  private renderControlPanel() {
    Column() {
      this.renderTimerProgress()
      this.renderControlButtons()
    }
    .fullWidth()
    .padding(20)
    .backgroundColor('#3a3340')
    .borderRadius({ topLeft: 10, topRight: 10 })
  }

  private renderTimerProgress() {
    Row() {
      Progress({ value: this.time, total: TOTAL_TIME, type: ProgressType.Linear })
        .style({ strokeWidth: 30, enableSmoothEffect: true, strokeRadius: 6 })
        .width('50%')
        .backgroundColor('#3cffffff')
        .color('#24c789')

      Text(this.showTime())
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .fontSize(28)
        .margin({ left: 14 })
    }
    .margin({ top: 10 })
    .fullWidth()
    .justifyContent(FlexAlign.SpaceBetween)
  }

  private renderControlButtons() {
    Row() {
      this.renderIconButton('app.media.ic_backward_end_fill')

      if (this.isPlaying) {
        this.renderPauseButton()
      } else {
        this.renderPlayAndStopButtons()
      }

      this.renderIconButton('app.media.ic_forward_end_fill')
    }
    .fullWidth()
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ top: 20, bottom: 8 })
  }

  private renderIconButton(media: string) {
    Row() {
      Image($r(media))
        .width(26)
        .fillColor('#a4ffffff')
    }
    .backgroundColor('#34ffffff')
    .size(40)
    .borderRadius(20)
    .justifyContent(FlexAlign.Center)
    .padding(5)
  }

  private renderPauseButton() {
    Row() {
      Image($r('app.media.ic_pause'))
        .width(26)
        .fillColor('#3a3340')
    }
    .backgroundColor('#fff')
    .size(40)
    .borderRadius(20)
    .justifyContent(FlexAlign.Center)
    .padding(5)
    .onClick(() => {
      this.isPlaying = false
      this.stopTimer()
      this.controller.pause()
    })
  }

  private renderPlayAndStopButtons() {
    Row({ space: 30 }) {
      this.renderControlButton('#fd5b54', '', () => router.back())
      this.renderControlButton('#26c688', 'app.media.ic_play_fill', () => {
        this.isPlaying = true
        this.startTimer()
        this.controller.start()
      })
    }
  }

  private renderControlButton(bgColor: string, media: string, onClick: () => void) {
    Row() {
      if (media) {
        Image($r(media))
          .width(22)
          .fillColor(Color.White)
      } else {
        Row().size(18).backgroundColor(Color.White)
      }
    }
    .backgroundColor(bgColor)
    .size(40)
    .borderRadius(20)
    .justifyContent(FlexAlign.Center)
    .padding(5)
    .onClick(onClick)
  }

  private renderMaskOverlay() {
    Column() {
      Column() {
        Text('恭喜您完成训练')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Image($r('app.media.badge_top_points'))
          .height(130)
          .margin({ top: 30 })
          .scale({ x: this.maskImgX, y: this.maskImgY })
          .animation({ duration: MASK_ANIMATION_DURATION })

        Blank()

        Row() {
          Blank()
          Row() {
            Text('写下此刻的感受')
              .fontSize(12)
              .fontColor('#9e000000')
            Image($r('app.media.ic_paintbrush_fill'))
              .height(20)
              .fillColor('#9e000000')
              .margin({ left: 5 })
          }
          .backgroundColor('#19000000')
          .padding(10)
          .borderRadius(8)
          .onClick(() => router.replaceUrl({ url: 'pages/AddRecordPage' }))
        }
        .fullWidth()
      }
      .backgroundColor(Color.White)
      .size(250, 300)
      .borderRadius(20)
      .padding(20)

      Row() {
        Image($r('app.media.ic_xmark'))
          .height(40)
          .fillColor(Color.White)
      }
      .margin({ top: 70 })
      .backgroundColor('#90000000')
      .size(100)
      .justifyContent(FlexAlign.Center)
      .padding(10)
      .borderRadius(15)
      .borderWidth(2)
      .borderColor(Color.White)
      .onClick(() => router.back())
    }
    .fullScreen()
    .backgroundColor('#ce000000')
    .zIndex(this.isCompleted ? 5 : -1)
    .justifyContent(FlexAlign.Center)
    .opacity(this.maskOpacity)
    .animation({ duration: OPACITY_ANIMATION_DURATION })
  }

  private showTime(): string {
    const min = Math.floor(this.time / 60).toString().padStart(2, '0')
    const sec = (this.time % 60).toString().padStart(2, '0')
    return `${min}:${sec}`
  }
}
