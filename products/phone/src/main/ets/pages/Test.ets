import {
  PhotoPickerComponent,
  PickerController,
  PickerOptions,
  DataType,
  BaseItemInfo,
  ItemInfo,
  PhotoBrowserInfo,
  ItemType,
  ClickType,
  MaxCountType,
  PhotoBrowserRange,
  ReminderMode,
} from '@ohos.file.PhotoPickerComponent';
import photoAccessHelper from '@ohos.file.photoAccessHelper';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct PhotoPickerComponentDemo {
  pickerOptions: PickerOptions = new PickerOptions();

  @State pickerController: PickerController = new PickerController();
  @State selectUris: Array<string> = [];
  @State currentUri: string = '';
  @State isBrowserShow: boolean = false;

  aboutToAppear() {
    this.pickerOptions = {
      MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_VIDEO_TYPE,
      maxSelectNumber: 5,
      maxSelectedReminderMode: ReminderMode.TOAST,
      isSearchSupported: true,
      isPhotoTakingSupported: true,
    };
  }

  private onItemClicked(itemInfo: ItemInfo, clickType: ClickType): boolean {
    if (!itemInfo?.uri) return false;

    if (itemInfo.itemType === ItemType.CAMERA) {
      return true;
    }

    if (clickType === ClickType.SELECTED) {
      this.selectUris.push(itemInfo.uri);
    } else {
      this.selectUris = this.selectUris.filter((item) => item !== itemInfo.uri);
    }
    this.pickerOptions.preselectedUris = [...this.selectUris];
    return true;
  }

  private onEnterPhotoBrowser(_: PhotoBrowserInfo): boolean {
    this.isBrowserShow = true;
    return true;
  }

  private onExitPhotoBrowser(_: PhotoBrowserInfo): boolean {
    this.isBrowserShow = false;
    return true;
  }

  private onPickerControllerReady(): void {
    // 暂无处理逻辑，留空
  }

  private onPhotoBrowserChanged(browserItemInfo: BaseItemInfo): boolean {
    this.currentUri = browserItemInfo.uri ?? '';
    return true;
  }

  private onSelectedItemsDeleted(_: Array<BaseItemInfo>): void {
    // 暂无处理逻辑，留空
  }

  private onExceedMaxSelected(_: MaxCountType): void {
    // 暂无处理逻辑，留空
  }

  private onCurrentAlbumDeleted(): void {
    // 暂无处理逻辑，留空
  }

  build() {
    Flex({
      direction: FlexDirection.Column,
      alignItems: ItemAlign.Start,
    }) {
      PhotoPickerComponent({
        pickerOptions: this.pickerOptions,
        pickerController: this.pickerController,
        onItemClicked: this.onItemClicked.bind(this),
        onEnterPhotoBrowser: this.onEnterPhotoBrowser.bind(this),
        onExitPhotoBrowser: this.onExitPhotoBrowser.bind(this),
        onPickerControllerReady: this.onPickerControllerReady.bind(this),
        onPhotoBrowserChanged: this.onPhotoBrowserChanged.bind(this),
        onSelectedItemsDeleted: this.onSelectedItemsDeleted.bind(this),
        onExceedMaxSelected: this.onExceedMaxSelected.bind(this),
        onCurrentAlbumDeleted: this.onCurrentAlbumDeleted.bind(this),
      })

      if (this.isBrowserShow) {
        Row() {
          ForEach(this.selectUris, (uri) => {
            Image(uri)
              .size({ width: 50, height: 50 })
              .borderWidth(uri === this.currentUri ? 1 : 0)
              .borderColor(uri === this.currentUri ? 'red' : '')
              .onClick(() => {
                if (uri !== this.currentUri) {
                  this.pickerController.setData(DataType.SET_SELECTED_URIS, this.selectUris);
                  this.pickerController.setPhotoBrowserItem(uri, PhotoBrowserRange.ALL);
                }
              });
          }, (uri) => uri) // 不用 `JSON.stringify`，uri 本身可以作为 key
        }
        .alignSelf(ItemAlign.Center)
        .margin(this.selectUris.length ? 10 : 0)
      } else {
        Row() {
          Button('确定').width('50%')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .onClick(() => router.back())
      }
    }
  }
}
