import { router } from '@kit.ArkUI'

@Entry
@ComponentV2
struct AddActionPage {
  @Local actionName: string = ''
  @Local actionType: string = '胸'
  @Local actionDescription: string = ''
  @Local isUpload: boolean = false

  private trainingPartList: string[] = ['胸', '背', '肩', '手臂', '腹部', '腿']
  private select: number = 0

  private showPicker() {
    this.getUIContext().showTextPickerDialog({
      range: this.trainingPartList,
      selected: this.select,
      disappearTextStyle: { color: '#65000000', font: { size: 15, weight: FontWeight.Lighter } },
      textStyle: { color: Color.Black, font: { size: 20, weight: FontWeight.Normal } },
      selectedTextStyle: { color: Color.Black, font: { size: 24, weight: FontWeight.Bold } },
      onAccept: (value: TextPickerResult) => {
        this.select = value.index
        this.actionType = value.value as string
      }
    })
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_chevron_left'))
          .height(30)
          .onClick(() => {
            router.back()
          })
        Text('创建动作')
        Image($r('app.media.ic_plus_square'))
          .height(30)
          .fillColor("#ffeeeeee")
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 30, right: 30 })

      Column() {
        TextInput({
          placeholder: '请输入动作名称',
          text: $$this.actionName
        })
          .backgroundColor(Color.White)
          .height(60)
          .width('100%')
          .borderRadius({ topLeft: 10, topRight: 10 })

        Row() {
          Text('动作分类')
          Blank()
          Text(this.actionType)
          Image($r('app.media.ic_chevron_right'))
            .height(20)
            .fillColor('#52000000')
            .margin({ left: 10 })
        }
        .width('100%')
        .height(60)
        .backgroundColor(Color.White)
        .padding(20)
        .onClick(() => this.showPicker())

        Row() {
          Text('动作视频')
          Blank()
          Text(this.isUpload ? '已上传' : '可选')
            .fontColor(this.isUpload ? Color.Black : '#52000000')
          Image($r('app.media.ic_chevron_right'))
            .height(20)
            .fillColor('#52000000')
            .margin({ left: 10 })
        }
        .width('100%')
        .height(60)
        .backgroundColor(Color.White)
        .padding(20)
        .borderRadius({ bottomLeft: 10, bottomRight: 10 })
        .onClick(() => {
          this.isUpload = !this.isUpload
          router.pushUrl({ url: "pages/Test" })
        })
      }
      .margin({ top: 20 })

      TextArea({
        placeholder: '\n                    请输入动作描述',
        text: $$this.actionDescription
      })
        .backgroundColor(Color.White)
        .margin({ top: 20 })
        .height(80)

      Blank()

      Button('创建动作')
        .width('100%')
        .onClick(() => {
          router.pushUrl({ url: "pages/MainPage3" })
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor("#ffeeeeee")
    .padding(20)
  }
}
