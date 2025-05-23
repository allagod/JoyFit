import { router } from '@kit.ArkUI'
import { Action, WorkoutPlan } from 'exercise'
import { ActionRepository } from 'exercise/src/main/ets/service/ActionRepository'

class exercise {
  imageUrl: string = ''
  name: string = ''
  time: number = 0

  constructor(imageUrl: string, name: string, time: number) {
    this.imageUrl = imageUrl
    this.name = name
    this.time = time
  }
}

//

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
    this.nowActionList = this.chestActionList
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
      .padding({left: 30, right: 30})

      Row() {
        Column() {
          ForEach(this.trainingPartList, (item: string, index) => {
            trainingPartItem({
              isSelected: this.selectedItem == index ? true : false,
              trainingPartName: item
            })
              .onClick(() => {
              this.selectedItem = index
              if(index == 0) this.nowActionList = this.chestActionList
              if(index == 1) this.nowActionList = this.backActionList
              if(index == 2) this.nowActionList = this.shouldersActionList
              if(index == 3) this.nowActionList = this.armsActionList
              if(index == 4) this.nowActionList = this.abdomenActionList
              if(index == 5) this.nowActionList = this.legActionList
              })
          })
        }

        Column() {
          ForEach(this.nowActionList, (item: Action, index) => {
            exerciseItem({
              action: item
            })
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

    Column() {
          ForEach(this.nowActionList, (item: Action, index) => {
            exerciseItem({
              action: item
            })
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

@ComponentV2
struct trainingPartItem {
  @Param isSelected: boolean = false
  @Param trainingPartName: string = ''

  build() {
    Row() {
      Column().height('100%').width(5).backgroundColor(this.isSelected ? '#007dfe' : '#fff5f5f5').margin({right: 12})
      Text(this.trainingPartName)
        .fontColor(this.isSelected ? '#007dfe' : Color.Black)
        .fontSize(16)
    }
    .height(50)
    .width(85)
  }
}

@ComponentV2
struct exerciseItem {
  @Param action: Action = new Action

  build() {
    Row() {
      Video({
        src: $rawfile(this.action.IntroductionVideo),
      })
        .width(120)
        .height(70)
        .autoPlay(true)
        .borderRadius(10)
        .controls(false)
        .loop(false)
      // Image($r(this.action.IntroductionVideo))
      //   .height(70)
      //   .borderRadius(10)
      Column() {
        Text(this.action.ActionName)
        Text(this.action.Note)
          .fontSize(16)
          .fontColor('#66006600')
      }
      .height('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(HorizontalAlign.Start)
      .margin({left: 10})
    }
    .width('100%')
    .height(80)
    .padding(10)
  }
}
