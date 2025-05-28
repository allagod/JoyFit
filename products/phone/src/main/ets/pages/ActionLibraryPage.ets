@Entry
@ComponentV2
struct ActionLibraryPage {
  @Local armsActionList: Action[] = []
  @Local abdomenActionList: Action[] = []
  @Local shouldersActionList: Action[] = []
  @Local nowActionList: Action[] = []
  @Local selectedItem: number = 0
  @Local chestActionList: Action[] = []
  @Local backActionList: Action[] = []
  @Local legActionList: Action[] = []

  private trainingPartList: string[] = ['胸', '背', '肩', '手臂', '腹部', '腿']
  private actionMap: Action[][] = []
  private exerciseList: exercise[] = [new exercise('app.media.test_exercise_item', '卷腹', 20)]
  private actionRepository: ActionRepository = ActionRepository.getInstance()
  private emptyWorkoutPlan: WorkoutPlan = new WorkoutPlan()

  async aboutToAppear(): Promise<void> {
    this.chestActionList = await this.actionRepository.getAllChestActions()
    this.backActionList = await this.actionRepository.getAllBackActions()
    this.legActionList = await this.actionRepository.getAllLegActions()
    this.armsActionList = await this.actionRepository.getAllArmsActions()
    this.abdomenActionList = await this.actionRepository.getAllAbdomenActions()
    this.shouldersActionList = await this.actionRepository.getAllShouldersActions()

    // 初始化映射关系
    this.actionMap = [
      this.chestActionList,
      this.backActionList,
      this.shouldersActionList,
      this.armsActionList,
      this.abdomenActionList,
      this.legActionList
    ]

    this.nowActionList = this.actionMap[0]
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
          ForEach(this.trainingPartList, (item: string, index: number) => {
            trainingPartItem({
              isSelected: this.selectedItem === index,
              trainingPartName: item
            })
              .onClick(() => {
                this.selectedItem = index
                this.nowActionList = this.actionMap[index]  // 替代多个 if 判断
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
