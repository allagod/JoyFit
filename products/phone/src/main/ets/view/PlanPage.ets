import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem'
import { router } from '@kit.ArkUI'
import { workoutPlan } from "exercise/src/main/ets/model/workoutPlan"
import { WorkoutPlanService } from "exercise/src/main/ets/service/WorkoutPlanService"
import { WorkoutPlan } from "exercise/src/main/ets/bean/WorkoutPlan"

// PlanState: NotStarted Abandoned InProgress Completed

@ComponentV2
export default struct PlanPage {
  @Local isWorkOut: boolean = true

  private inProgressPlanList: WorkoutPlan[] = []
  private notStartedPlanList: WorkoutPlan[] = []
  private abandonedPlanList: WorkoutPlan[] = []
  private completedPlanList: WorkoutPlan[] = []

  private workoutPlanService: WorkoutPlanService = WorkoutPlanService.getInstance()
  private emptyWorkoutPlan: WorkoutPlan = new WorkoutPlan()

  async aboutToAppear(): Promise<void> {
    try {
      this.emptyWorkoutPlan.PlanState = 'NotStarted'
    }
    catch (error) {
    }
  }

  build() {
    Column() {
      Swiper() {
        Image($r('app.media.swipper1'))
        Image($r('app.media.swipper2'))
        Image($r('app.media.swipper3'))
      }
      .width('100%')
      .height(150)
      .loop(true)
      .autoPlay(true)
      .interval(3000)
      .borderRadius(10)
      .indicator(
        Indicator.dot()
          .itemWidth(10) //默认宽
          .itemHeight(3)
            //默认颜色：.color()
          .selectedItemWidth(30)
          .selectedColor(Color.White)
      )

      Scroll() {
        Column() {
          Row() {
            Text('正在执行')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .decoration({ type: TextDecorationType.Underline, color: Color.Black })

            Blank()
            Row() {
              Text(this.isWorkOut ? '健身' : '跑步')
                .fontColor(Color.White)
              Image($r('app.media.ic_reverse_order'))
                .width(20)
                .margin({left: 10})
                .fillColor(Color.White)
            }
            .padding(8)
            .backgroundColor("#ff2191fa")
            .borderRadius(15)
            .onClick(() => {
              this.isWorkOut = !this.isWorkOut
            })
          }.width('100%').margin({top: 15, bottom: 5})

          ForEach(this.inProgressPlanList, (item: WorkoutPlan, index) => {
            planItem({
              workoutPlan: item
            })
          })

          Row() {
            Text('即将进行')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .decoration({ type: TextDecorationType.Underline, color: Color.Black })
              .margin({top: 10, bottom: 10})
            Row() {
              Text('新增计划')
                .fontWeight(FontWeight.Bold)
                .margin({right: 5})
                .fontColor('#b05e74f5')
              Image($r('app.media.ic_plus_square'))
                .height(30)
                .fillColor('#ff5e74f5')
            }
            .onClick(() => {
              router.pushUrl({
                url: "pages/CreatePlanPage",
                params: {
                  workoutPlan: this.emptyWorkoutPlan
                }
              })
            })

          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          ForEach(this.notStartedPlanList, (item: WorkoutPlan, index) => {
            planItem({
              workoutPlan: item
            })
          })

          Text('历史计划')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .decoration({ type: TextDecorationType.Underline, color: Color.Black })
            .margin({top: 10})
            .width('100%')
          ForEach(this.completedPlanList, (item: WorkoutPlan, index) => {
            planItem({
              workoutPlan: item
            })
          })
          ForEach(this.abandonedPlanList, (item: WorkoutPlan, index) => {
            planItem({
              workoutPlan: item
            })
          })
        }.height(10)
      }
      .scrollBar(BarState.Off)
      .height(1)
      .edgeEffect(EdgeEffect.Spring)


    }
    .width('100%')
    .height('100%')
    .padding({top: 20, left: 40, right: 40})
    .backgroundColor("#eeeeee")
  }
}

@ComponentV2
struct planItem {
  @Param workoutPlan: WorkoutPlan = new WorkoutPlan()

  private statusImage: string = ''
  private statusText: string = ''
  private statusColor: string = ''

  aboutToAppear(): void {
    if(this.workoutPlan.PlanState == 'Completed') {this.statusImage = 'app.media.ic_checkmark'; this.statusText = '已完成'; this.statusColor = '#ff43cd0e'}
    else if(this.workoutPlan.PlanState == 'InProgress') {this.statusImage = 'app.media.ic_fast_forward'; this.statusText = '进行中'; this.statusColor = '#ffdd4141'}
    else if(this.workoutPlan.PlanState == 'Abandoned') {this.statusImage = 'app.media.ic_xmark'; this.statusText = '已放弃'; this.statusColor = '#ff474747'}
    else if(this.workoutPlan.PlanState == 'NotStarted') {this.statusImage = 'app.media.ic_clock'; this.statusText = '待开始'; this.statusColor = '#fffa6a0a'}
  }

  build() {
    Row() {
      Image($r(this.workoutPlan.CoverPicture))
        .height('100%')
        .borderRadius(10)

      Column() {
        Text(this.workoutPlan.PlanName)
          .fontWeight(FontWeight.Bold)
        Column() {
          Text(this.workoutPlan.Tag)
            .fontSize(12)
            .fontColor('#6d000000')
            .fontWeight(FontWeight.Bold)
          Text(`${this.workoutPlan.TotalTime?.toString()}min`)
            .fontSize(12)
            .fontColor('#6d000000')
        }
        .alignItems(HorizontalAlign.Start)
      }
      .height('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(HorizontalAlign.Start)
      .margin({left: 10})

      Blank()

      Column() {
        Row() {
          Image($r(this.statusImage))
            .height('100%')
            .width('100%')
            .fillColor(this.statusColor)
        }
        .height(30)
        .width(30)
        .borderRadius(15)
        .backgroundColor(Color.White)
        .borderColor(this.statusColor)
        .borderWidth(2)
        .padding(6)
        .margin({bottom: 8})

        Text(this.statusText)
          .fontColor(this.statusColor)
          .fontSize(14)
      }

    }
    .backgroundColor(Color.White)
    .padding(14)
    .height(80)
    .width('100%')
    .borderRadius(20)
    .margin({bottom: 5, top: 10})
    .onClick(() => {
      router.pushUrl({
        url: "pages/CreatePlanPage",
        params: {
          workoutPlan: this.workoutPlan
        }
      })
    })
  }
}
