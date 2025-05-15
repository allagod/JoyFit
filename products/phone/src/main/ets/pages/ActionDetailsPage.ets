import { Action } from 'exercise'
import { router } from '@kit.ArkUI'

interface paraObj {
  action: Action
}



@Entry
@ComponentV2
struct ActionDetailsPage {
  @Local isCreatingAudio: boolean = false
  @Local maskOpacity: number = 0
  @Local text1: string = ''
  @Local text2: string = ''
  @Local text3: string = ''
  @Local isPlaying: boolean = false
  @Local isCreated: boolean = false


  private action: Action = new Action()
  private actionMainTrainingPart: string = ''

  aboutToAppear(): void {
    const params = router.getParams() as paraObj
    this.action = params.action
    if(this.action.MainTrainingPart == 'Chest') this.actionMainTrainingPart = '胸部'
    if(this.action.MainTrainingPart == 'Back') this.actionMainTrainingPart = '背部'
    if(this.action.MainTrainingPart == 'Abdomen') this.actionMainTrainingPart = '腹部'
    if(this.action.MainTrainingPart == 'Shoulders') this.actionMainTrainingPart = '肩部'
    if(this.action.MainTrainingPart == 'Arms') this.actionMainTrainingPart = '手臂'
    if(this.action.MainTrainingPart == 'Leg') this.actionMainTrainingPart = '腿部'
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Image($r('app.media.ic_chevron_left'))
            .height(30)
            .onClick(() => {
              router.back()
            })
          Text('动作库').fontColor(Color.White)
          Image($r('app.media.ic_plus_square'))
            .height(30)
            .fillColor(Color.White)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({left: 30, right: 30, bottom: 10})

        Video({
          src: $rawfile(this.action.IntroductionVideo),
        })
          .width('100%')
          .height(250)
          .autoPlay(true)
          .controls(false)
          .loop(true)

        Text(this.action.ActionName).width('100%').fontSize(26).fontWeight(FontWeight.Bold).margin({top: 20, left: 30})

        Row() {
          Text('部位：').fontColor('#9a000000')
          Text(this.actionMainTrainingPart).margin({left: 10})
        }.margin({top: 20, left: 30}).width('100%')
        Text('要点：').margin({top: 20, left: 30}).width('100%').fontColor('#9a000000')
        Text(this.action.Description)
          .margin({top: 10, left: 30, right: 30})

        Blank()

        //Image($r('app.media.ic_wave')).height(180)

        if(!this.isCreated)
        Column() {
          Text('生成AI智能语音指导').fontColor(Color.White).fontSize(18).fontWeight(FontWeight.Bold)
        }
        .backgroundColor("#0bbe86")
        .padding({top: 10, bottom: 10, left: 20, right: 20})
        .borderRadius(20)
        .onClick(() => {
          this.isCreatingAudio = !this.isCreatingAudio
          this.maskOpacity = 1
        })

        else
          Image($r('app.media.ic_wave')).height(180)

      }.width('100%').height('100%')

      Column() {
        Column() {
          Text('自定义语音风格')
            .fontSize(18)
          Column() {
            Row() {
              Text('音色：        ')
              TextInput({
                placeholder: '如：播音女声',
                text: $$this.text1
              })
                .backgroundColor(Color.White)
                .width(150)
            }
            Row() {
              Text('指导程度：')
              TextInput({
                placeholder: '如：细致、粗略',
                text: $$this.text2
              })
                .backgroundColor(Color.White)
                .width(150)
            }
            Row() {
              Text('情感：        ')
              TextInput({
                placeholder: '如：激昂、平缓',
                text: $$this.text3
              })
                .backgroundColor(Color.White)
                .width(150)
            }
          }.justifyContent(FlexAlign.Start).width('100%').margin({top: 15})

          Blank()

          Button('完成')
            .width('33%')
            .onClick(() => {
              this.isCreatingAudio = !this.isCreatingAudio
              this.maskOpacity = 0
              this.isCreated = !this.isCreated
            })
        }
        .backgroundColor(Color.White)
        .height(300)
        .width(280)
        .borderRadius(20)
        .padding(20)
        .margin({top: 150})
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#ce000000')
      .zIndex(this.isCreatingAudio ? 5 : -1)
      //.justifyContent(FlexAlign.Center)
      .opacity(this.maskOpacity)
      .animation({
        duration: 300
      })
      // .onClick(() => {
      //   this.isCreatingAudio = !this.isCreatingAudio
      //   this.maskOpacity = 0
      // })
    }

  }
}
