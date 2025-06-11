import { router } from '@kit.ArkUI';

@Entry
@ComponentV2
struct AddRecordPage {
  @Local txt: string = '';
  @Local title: string = '';

  // 封装顶部导航栏
  private renderHeader() {
    return Row() {
      Image($r('app.media.ic_chevron_left'))
        .height(30)
        .onClick(() => router.back());

      Text('添加记录')
        .fontSize(18)
        .fontWeight(FontWeight.Medium);

      Text('完成')
        .backgroundColor('#0bbe86')
        .fontColor(Color.White)
        .padding({ top: 5, bottom: 5, left: 10, right: 10 })
        .borderRadius(10)
        .onClick(() => router.back());
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 30, right: 30, bottom: 15 })
    .backgroundColor(Color.White);
  }

  build() {
    Column() {
      this.renderHeader()  // 顶部导航栏

      // 标题输入框（样式统一）
      TextInput({
        placeholder: '请输入该记录标题',
        text: $$this.title
      })
        .margin({ top: 30, left: 20, right: 20 })
        .backgroundColor(Color.White)
        .borderRadius(10)
        .padding(10)

      // 内容输入框（样式统一）
      TextArea({
        placeholder: '记录此刻的感受',
        text: $$this.txt
      })
        .margin({ top: 10, left: 20, right: 20 })
        .backgroundColor(Color.White)
        .borderRadius(10)
        .padding(10)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
