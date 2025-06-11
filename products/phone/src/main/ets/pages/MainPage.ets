import MinePage from '../view/MinePage'
import SportsDataPage from '../view/SportsDataPage'
import { router } from '@kit.ArkUI'
import { WorkoutPlanService } from "exercise/src/main/ets/service/WorkoutPlanService"
import { WorkoutPlan } from "exercise/src/main/ets/bean/WorkoutPlan"
import { WorkoutPlanViewModel } from './WorkoutPlanViewModel' // 假设已分离

@Entry
@ComponentV2
struct MainPage {
  @Local selectedIndex: number = 0
  @Local isWorkOut: boolean = true

  private workoutPlanService: WorkoutPlanService = WorkoutPlanService.getInstance()
  private emptyWorkoutPlan: WorkoutPlan = new WorkoutPlan()

  private inProgressPlanList: WorkoutPlan[] = []
  private notStartedPlanList: WorkoutPlan[] = []
  private abandonedPlanList: WorkoutPlan[] = []
  private completedPlanList: WorkoutPlan[] = []

  @Local inProgressPlanViewModelList: WorkoutPlanViewModel[] = []
  @Local notStartedPlanViewModelList: WorkoutPlanViewModel[] = []
  @Local abandonedPlanViewModelList: WorkoutPlanViewModel[] = []
  @Local completedPlanViewModelList: WorkoutPlanViewModel[] = []

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
    } catch (error) {
      // 可补充错误提示
    }
  }

  private renderSportsTab() {
    return SportsDataPage()
  }

  private renderPlanTab() {
    return Column() {
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
          .itemWidth(10)
          .itemHeight(3)
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
              Text(this.isWorkOut ? '健身' : '跑步').fontColor(Color.White)
              Image($r('app.media.ic_reverse_order')).width(20).margin({ left: 10 }).fillColor(Color.White)
            }
            .padding(8)
            .backgroundColor("#ff2191fa")
            .borderRadius(15)
            .onClick(() => this.isWorkOut = !this.isWorkOut)
          }
          .width('100%')
          .margin({ top: 15, bottom: 5 })

          ForEach(this.inProgressPlanViewModelList, (item: WorkoutPlanViewModel) => {
            planItem({ workoutPlan: item })
          })

          Row() {
            Text('即将进行')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .decoration({ type: TextDecorationType.Underline, color: Color.Black })
            Row() {
              Text('新增计划')
                .fontWeight(FontWeight.Bold)
                .margin({ right: 5 })
                .fontColor('#b05e74f5')
              Image($r('app.media.ic_plus_square'))
                .height(30)
                .fillColor('#ff5e74f5')
            }
            .onClick(() => {
              router.pushUrl({
                url: "pages/CreatePlanPage",
                params: { workoutPlan: this.emptyWorkoutPlan }
              })
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 10, bottom: 10 })

          ForEach(this.notStartedPlanViewModelList, (item: WorkoutPlanViewModel) => {
            planItem({ workoutPlan: item })
          })

          Text('历史计划')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .decoration({ type: TextDecorationType.Underline, color: Color.Black })
            .margin({ top: 10 })
            .width('100%')

          ForEach(this.completedPlanViewModelList, (item: WorkoutPlanViewModel) => {
            planItem({ workoutPlan: item })
          })
          ForEach(this.abandonedPlanViewModelList, (item: WorkoutPlanViewModel) => {
            planItem({ workoutPlan: item })
          })
        }
      }
      .scrollBar(BarState.Off)
      .height(540)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .padding({ top: 20, left: 40, right: 40 })
    .backgroundColor("#eeeeee")
  }

  private renderMineTab() {
    return MinePage()
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        this.renderSportsTab()
      }
      .tabBar(this.myTabBar(0, '运动', $r('app.media.ic_figure_running')))

      TabContent() {
        this.renderPlanTab()
      }
      .tabBar(this.myTabBar(1, '计划', $r('app.media.ic_list_bullet')))

      TabContent() {
        this.renderMineTab()
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
        .margin({ top: 5 })
    }
    .margin({ top: 8 })
  }
}
