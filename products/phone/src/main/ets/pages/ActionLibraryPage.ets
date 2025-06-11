@Entry
@ComponentV2
struct ActionLibraryPage {
  @Local selectedItem: number = 0
  @Local nowActionList: Action[] = []

  // 使用统一结构保存训练部位及其动作列表
  private trainingParts: { name: string; fetch: () => Promise<Action[]>; actions: Action[] }[] = [
    { name: '胸', fetch: () => this.actionRepository.getAllChestActions(), actions: [] },
    { name: '背', fetch: () => this.actionRepository.getAllBackActions(), actions: [] },
    { name: '肩', fetch: () => this.actionRepository.getAllShouldersActions(), actions: [] },
    { name: '手臂', fetch: () => this.actionRepository.getAllArmsActions(), actions: [] },
    { name: '腹部', fetch: () => this.actionRepository.getAllAbdomenActions(), actions: [] },
    { name: '腿', fetch: () => this.actionRepository.getAllLegActions(), actions: [] }
  ]

  private actionRepository: ActionRepository = ActionRepository.getInstance()
  private emptyWorkoutPlan: WorkoutPlan = new WorkoutPlan()

  async aboutToAppear(): Promise<void> {
    // 异步拉取所有部位的动作列表
    for (let part of this.trainingParts) {
      part.actions = await part.fetch()
    }

    this.nowActionList = this.trainingParts[0].actions
    this.emptyWorkoutPlan.PlanState = 'NotStarted'
    this.emptyWorkoutPlan.PlanName = '我的自定义计划'
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_chevron_left'))
          .height(30)
          .onClick(() => {
            router.back()
          })
        Text('动作库')
        Image($r('app.media.ic_plus_square'))
          .height(30)
          .onClick(() => {
            router.pushUrl({
              url: "pages/AddActionPage"
            })
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 30, right: 30 })

      Row() {
        Column() {
          ForEach(this.trainingParts, (part, index: number) => {
            trainingPartItem({
              isSelected: this.selectedItem === index,
              trainingPartName: part.name
            }).onClick(() => {
              this.selectedItem = index
              this.nowActionList = this.trainingParts[index].actions
            })
          })
        }

        Column() {
          ForEach(this.nowActionList, (item: Action, index) => {
            exerciseItem({ action: item })
              .onClick(() => {
                router.pushUrl({
                  url: "pages/CreatePlanPage2",
                  params: {
                    workoutPlan: this.emptyWorkoutPlan
                  }
                })
              })
          })
        }
        .height('100%')
        .width('100%')
      }
    }
  }
}
