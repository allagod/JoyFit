//todo
// 创建动作：新增动作备注；修改图片为视频，增加动作时间，载加个textinput输入用户需求（文字形式）；音频创建AI：参考豆包，允许切换模板，或者直接输入；对接收的音频预览、删除重建
// 查看动作详情：
// 动作库：添加区分官方动作和自定义动作
// 开始运动：增加动作备注
// 我的页：展示年龄性别所在地（图标）；加体质表，加体脂历史数据展示
// 跑步计划：做静态页面


import MinePage from '../view/MinePage'
//import PlanPage from '../view/PlanPage'
import SportsDataPage from '../view/SportsDataPage'
import { ComposeListItem } from '@ohos.arkui.advanced.ComposeListItem'
import { router } from '@kit.ArkUI'
import { workoutPlan } from "exercise/src/main/ets/model/workoutPlan"
import { WorkoutPlanService } from "exercise/src/main/ets/service/WorkoutPlanService"
import { WorkoutPlan } from "exercise/src/main/ets/bean/WorkoutPlan"

@ObservedV2
class WorkoutPlanViewModel {
  @Trace PlanID: string | undefined;  // Integer类型
  @Trace UserID: string | undefined;  // String类型
  @Trace PlanName: string | undefined;  // String类型
  @Trace CoverPicture: string | undefined;  // String类型
  @Trace PlanState: string | undefined;  // String类型
  @Trace EndDate: Date | undefined;  // Integer类型
  @Trace DayOfWeek: string = '';  // String类型
  @Trace StartDate: Date | undefined;  // Date类型
  @Trace RestTimeBetweenSets: number | undefined;  // Integer类型
  @Trace RestTimeBetweenExercises: number | undefined;  // Integer类型
  @Trace TotalTime: number | undefined;
  @Trace Description: string | undefined;
  @Trace Tag: string | undefined;
}

@Entry
@ComponentV2
struct MainPage {
  @Local selectedIndex: number = 0

  @Local isWorkOut: boolean = true

  private inProgressPlanList: WorkoutPlan[] = []
  private notStartedPlanList: WorkoutPlan[] = []
  private abandonedPlanList: WorkoutPlan[] = []
  private completedPlanList: WorkoutPlan[] = []
  @Local inProgressPlanViewModelList: WorkoutPlanViewModel[] = []
  @Local notStartedPlanViewModelList: WorkoutPlanViewModel[] = []
  @Local abandonedPlanViewModelList: WorkoutPlanViewModel[] = []
  @Local completedPlanViewModelList: WorkoutPlanViewModel[] = []


  private workoutPlanService: WorkoutPlanService = WorkoutPlanService.getInstance()
  private emptyWorkoutPlan: WorkoutPlan = new WorkoutPlan()

  async aboutToAppear(): Promise<void> {
    try {
      this.emptyWorkoutPlan.PlanState = 'NotStarted'
      this.inProgressPlanList = await this.workoutPlanService.getInProgressPlan('2')
      this.notStartedPlanList = await this.workoutPlanService.getNotStartedPlan('2')
      this.abandonedPlanList = await this.workoutPlanService.getAbandonedPlan('2')
      this.completedPlanList = await this.workoutPlanService.getCompletedPlan('2')
      this.inProgressPlanViewModelList = this.inProgressPlanList
      this.notStartedPlanViewModelList = this.notStartedPlanList
      this.abandonedPlanViewModelList = this.abandonedPlanList
      this.completedPlanViewModelList = this.completedPlanList

      this.inProgressPlanViewModelList = this.inProgressPlanList
      this.notStartedPlanViewModelList = this.notStartedPlanList
      this.abandonedPlanViewModelList = this.abandonedPlanList
      this.completedPlanViewModelList = this.completedPlanList
    }
    catch (error) {
    }
  }

  build() {
    Tabs({barPosition: BarPosition.End}) {
      TabContent() {
        SportsDataPage()
      }
      .tabBar(this.myTabBar(0, '运动', $r('app.media.ic_figure_running')))
      TabContent() {
        // PlanPage()
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

              ForEach(this.inProgressPlanViewModelList, (item: WorkoutPlanViewModel, index) => {
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

              ForEach(this.notStartedPlanViewModelList, (item: WorkoutPlanViewModel, index) => {
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
              ForEach(this.completedPlanViewModelList, (item: WorkoutPlanViewModel, index) => {
                planItem({
                  workoutPlan: item
                })
              })
              ForEach(this.abandonedPlanViewModelList, (item: WorkoutPlanViewModel, index) => {
                planItem({
                  workoutPlan: item
                })
              })
            }
          }
          .scrollBar(BarState.Off)
          .height(540)
          .edgeEffect(EdgeEffect.Spring)


        }
        .width('100%')
        .height('100%')
        .padding({top: 20, left: 40, right: 40})
        .backgroundColor("#eeeeee")
      }
      .tabBar(this.myTabBar(1, '计划', $r('app.media.ic_list_bullet')))
      TabContent() {
        MinePage()
      }
      .tabBar(this.myTabBar(2, '我的', $r('app.media.ic_house_fill')))
    }
    .scrollable(true)
    .onChange((index: number) => {
      this.selectedIndex = index
    })
  }

  @Builder
  myTabBar(itemIndex: number, title: string, image: Resource) {
    Column() {
      Image(image)
        .width(20)
        .fillColor(itemIndex == this.selectedIndex ? Color.Black : '#6d000000')
      Text(title)
        .fontColor(itemIndex == this.selectedIndex ? Color.Black : '#6d000000')
        .fontSize(12)
        .margin({top: 5})
    }
    .margin({top: 8})
  }
}


@ComponentV2
struct planItem {
  @Param workoutPlan: WorkoutPlanViewModel = new WorkoutPlanViewModel()

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
