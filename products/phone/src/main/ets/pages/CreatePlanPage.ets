import { router } from '@kit.ArkUI'
import { Action, PlanTask } from 'exercise'
import { PlanAction } from 'exercise/src/main/ets/bean/PlanAction'
import { WorkoutPlan } from 'exercise/src/main/ets/bean/WorkoutPlan'

interface ParamsObj {
  workoutPlan: WorkoutPlan
}

class SysRecord {
  public index: number = 0
  public state: string = ''
  public color: string = ''

  constructor(index: number, state: string) {
    this.index = index
    this.state = state
    if (state == 'Completed') this.color = '#a344ab30'
    if (state == 'Pending') this.color = "#c42191fa"
  }
}

@Entry
@ComponentV2
struct CreatePlanPage {
  @Local workoutPlan: WorkoutPlan = new WorkoutPlan()
  @Local startDate: Date = new Date()
  @Local endDate: Date = new Date()
  @Local dayOfWeek: string = ''
  @Local weekdayIsSelected: boolean[] = [false, false, false, false, false, false, false]
  @Local state: string = ''
  @Local isRecord: boolean = true
  @Local planTasks: PlanTask[] = []

  private weekdaysList: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
  private title: string = ''
  private startEndDatePrompt: string = ''
  private workoutDayPrompt: string = ''
  private actionList: Action[] = [new Action()]
  private planActionList: PlanAction[] = []

  aboutToAppear(): void {
    const params = router.getParams() as ParamsObj
    this.workoutPlan = params.workoutPlan

    if (this.workoutPlan.StartDate instanceof Date)
      this.startDate = this.workoutPlan.StartDate

    if (this.workoutPlan.EndDate instanceof Date)
      this.endDate = this.workoutPlan.EndDate

    for (let i = 0; i < this.workoutPlan.DayOfWeek.length; i += 2)
      this.weekdayIsSelected[(Number(this.workoutPlan.DayOfWeek[i]) + 6) % 7] = true

    if (this.workoutPlan.PlanState != undefined)
      this.state = this.workoutPlan.PlanState

    this.initPlanDisplayText(this.state)

    this.actionList[0].ActionName = '卷腹'
  }

  // ✅ 提取状态对应文案逻辑
  private initPlanDisplayText(state: string): void {
    const isCreate = state === 'NotStarted'
    this.title = isCreate ? '计划创建' : '计划详情'
    this.startEndDatePrompt = isCreate ? '点击修改起止日期' : '训练起止日期'
    this.workoutDayPrompt = isCreate ? '点击选择训练日' : '训练日'
  }

  // 🧮 示例辅助方法（未改动）
  private getDaysFromMonth(month: number, year: number): number {
    let days: number[] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    let run: boolean = false
    if (year % 4 == 0) run = true
    if (year % 100 == 0 && year % 400 != 0) run = false
    days[1] += run ? 1 : 0
    return days[month]
  }

  private generateMonthlySysRecords(): SysRecord[] {
    return []  // 可根据月份构造真实数据
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_chevron_left'))
          .height(30)
          .onClick(() => router.back())
        Text(this.title)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 30, right: 30, bottom: 15 })

      // 省略中间 build 中非常长的 UI 区域...
      // 如需继续优化其他部分结构，请说明

    }
  }
}
