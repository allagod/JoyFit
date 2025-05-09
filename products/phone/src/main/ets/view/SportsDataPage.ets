import { bar } from '@mcui/mccharts/src/main/ets/mcCore/core'
import {mcLineChart} from './mccharts'
import { router, Router } from '@kit.ArkUI'
import { WorkoutPlan, WorkoutPlanService } from 'exercise'
import { BusinessError } from '@kit.BasicServicesKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

@ComponentV2
export default struct SportsDataPage {


  build() {
    Column() {
      Text('运动统计')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .decoration({ type: TextDecorationType.Underline, color: Color.Black })
        .width('100%')
        .margin({bottom: 10})
      //今日运动数据显示区域
      Row({space: 10}) {
        steps()
        calories()
      }
      exerciseDuration()

      //查看今日任务区域
      todayTask()
        .height('100%')
    }
    .width('100%')
    .height('100%')
    .padding({top: 20, left: 40, right: 40})
    .backgroundColor("#ffeeeeee")
  }
}

@ComponentV2
struct steps {
  @Local stepsValue: number[] = [9964, 6031, 1551, 8256, 10208, 4456, 14998]
  @Local selectedDate: number = 6
  build() {
    Column() {
      Row() {
        Column() {
          Text('步数')
            .fontColor("#94e2fd")
            .fontSize(12)
          Text(this.stepsValue[this.selectedDate].toString())
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .fontSize(20)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({top: 20, left: 10})

        Image($r('app.media.ic_figure_running'))
          .width(50)
          .fillColor("#ff8ad5f3")
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)


      Scroll() {
        Row() {
          ForEach(this.stepsValue, (item: number, index) => {
            Column() {
              Text(`12月${(index + 24).toString()}日`)
                .fontSize(7)
                .fontColor(index == this.selectedDate ? Color.White : '#a4ffffff')
                .margin({bottom: 5})
                .fontWeight(FontWeight.Bold)
              Column() {
                ForEach(Array.from({ length: item / 1300 }), () => {
                  Column().width(15).height(3).backgroundColor(index == this.selectedDate ? Color.White : '#a4ffffff').margin({bottom: 5}).borderRadius(5)
                })
              }
              .height(100)
              .width(20)
              .backgroundColor("#ff50a4f6")
              .justifyContent(FlexAlign.End)
              .borderRadius(5)
            }
            .margin({left: 7})
            .onClick(() => {
              this.selectedDate = index
            })
          })
        }
        .reverse(false)
        .padding(10)
      }
      .width('100%')
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .initialOffset({ xOffset: '100%'})
    }
    .width('50%')
    .height(200)
    .backgroundColor("#ff2191fa")
    .borderRadius(20)
  }
}

@ComponentV2
struct calories {
  build() {
    Column() {
      Row() {
        Column() {
          Text('今日卡路里消耗')
            .fontColor("#94e2fd")
            .fontSize(12)
          Text('8960')
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .fontSize(20)
        }
        .alignItems(HorizontalAlign.Start)
        .margin({top: 20, left: 10})

        Image($r('app.media.ic_figure_arms_open'))
          .width(50)
          .fillColor("#ff56f3c2")
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      //显示折线图
      mcLineChart()
        .width('100%')
        .height('80%')
    }
    .width('50%')
    .height(200)
    .backgroundColor("#0bbe86")
    .borderRadius(20)
  }
}

@ComponentV2
struct exerciseDuration {
  @Local timeList: number[] = [10, 30, 20, 28, 16, 48, 43]

  build() {
    Row() {
      Column() {
        Text('运动时长')
          .fontColor('#ff838383')
        Row() {
          Text('56')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .margin({right: 3})
          Text('min')
            .margin({right: 6})
          Image($r('app.media.ic_arrowtriangle_down_fill'))
            .height(20)
            .fillColor("#ff22bc8d")
            .margin({right: 5})
          Text('2%')
            .fontSize(14)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .height('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(HorizontalAlign.Start)

      //显示柱状图
      Row() {
        ForEach(this.timeList, (item: number, index) =>{
          Column().height(item).width(13).margin(2).backgroundColor(index == 6 ? "#ff22bc8d": "#7a22bc8d")
        })
      }
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .height(100)
    .backgroundColor(Color.White)
    .margin({top: 20})
    .borderRadius(20)
    .padding(20)
    .justifyContent(FlexAlign.SpaceBetween)
  }
}

@ComponentV2
struct todayTask {
  @Local isWorkOut: boolean = true
  @Local todayTaskList: WorkoutPlan[] = []

  private ex: WorkoutPlanService = WorkoutPlanService.getInstance();

  aboutToAppear(): void {
    this.ex.getTodayTasks('2').then((result: WorkoutPlan[]) => {
      this.todayTaskList = result; //可以直接使用这个变量进行后续展示处理
      hilog.info(2, "查询", JSON.stringify(result))
    }
    ).catch((error: BusinessError) => {
    });
  }

  build() {
    Column() {
      Row() {
        Text('今日待办')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .decoration({ type: TextDecorationType.Underline, color: Color.Black })
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
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Top)
      .margin({bottom: 10})

      List() {
        ForEach(this.todayTaskList, (item: WorkoutPlan, index) => {
          ListItem () {
            TaskItem({
              workoutPlan: item,
              taskType: this.isWorkOut ? '健身' : '跑步',
              runningDistance: this.isWorkOut ? 0 : 3, //单位km
              runningTime: this.isWorkOut ? 0 : 15,
            }).margin({top: 10})
          }
        })
      }
      .height(215)
      .scrollBar(BarState.Off)
    }
    .height('100%')
    .margin({top: 20})
  }
}

@ComponentV2
struct TaskItem {
  @Param workoutPlan: WorkoutPlan = new WorkoutPlan()
  @Local workoutTime: number = 0

  @Param taskType: string = ''
  @Param runningDistance: number = 0
  @Param runningTime: number = 0

  aboutToAppear(): void {
    if(this.workoutPlan.TotalTime != undefined)
      this.workoutTime = this.workoutPlan.TotalTime
  }

  build() {
    Row() {
      Image($r(this.workoutPlan.CoverPicture))
        .width(50)
        .borderRadius(10)
      Column() {
        Text(this.workoutPlan.PlanName)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text(`${this.workoutTime.toString()} min`)
          .fontSize(12)
          .fontColor('#ff6b6b6b')
          .margin({right: 5})
      }
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({left: 10})

      Blank()

      Image($r('app.media.ic_chevron_right'))
        .width(20)
    }
    .width('100%')
    .height(80)
    .borderRadius(20)
    .backgroundColor(Color.White)
    .padding(15)
    .onClick(() => {
      router.pushUrl({
        url: this.taskType == '健身' ? "pages/VideoPlayPage" : "pages/RunPage",
        params: {
          workoutPlan: this.workoutPlan
        }
      })
    })
  }
}

