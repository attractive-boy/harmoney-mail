import { StyleConstants } from '@ohos/common'
import { ToastUtil } from '@pura/harmony-utils'
import router from '@ohos.router'
import { AddressInfo, addAddress, updateAddress } from '../../service/addressService'

interface RouteParams {
  mode: string
  addressJson?: string
}

@Entry
@Component
struct AddressEdit {
  @StorageProp('safeTop') safeTop: number = 0
  @StorageProp('safeBottom') safeBottom: number = 0
  @StorageProp('userAccount') userAccount: string = 'guest'

  @State editMode: boolean = false
  @State editId: number = 0
  @State formName: string = ''
  @State formPhone: string = ''
  @State formRegion: string = ''
  @State formDetail: string = ''
  @State formIsDefault: boolean = false
  @State formLabel: string = ''
  @State isSubmitting: boolean = false

  private labelOptions: string[] = ['学校', '家', '公司', '购物', '秒送/外卖', '自定义']

  aboutToAppear() {
    const params = router.getParams() as RouteParams
    this.editMode = params?.mode === 'edit'
    if (this.editMode && params?.addressJson) {
      try {
        const addr = JSON.parse(params.addressJson) as AddressInfo
        this.editId = addr.id
        this.formName = addr.name
        this.formPhone = addr.phone
        this.formRegion = addr.region
        this.formDetail = addr.detail
        this.formIsDefault = addr.isDefault
        this.formLabel = addr.label || ''
      } catch (e) {
        // ignore parse error
      }
    }
  }

  private async handleSubmit() {
    if (!this.formName.trim()) {
      ToastUtil.showToast('请填写收货人姓名')
      return
    }
    if (!this.formPhone.trim()) {
      ToastUtil.showToast('请填写手机号')
      return
    }
    if (!this.formRegion.trim()) {
      ToastUtil.showToast('请填写省市区')
      return
    }
    if (!this.formDetail.trim()) {
      ToastUtil.showToast('请填写详细地址')
      return
    }

    this.isSubmitting = true
    const userId = this.userAccount || 'guest'

    try {
      if (this.editMode) {
        await updateAddress({
          id: this.editId,
          userId: userId,
          name: this.formName.trim(),
          phone: this.formPhone.trim(),
          region: this.formRegion.trim(),
          detail: this.formDetail.trim(),
          isDefault: this.formIsDefault,
          label: this.formLabel || undefined
        })
      } else {
        await addAddress({
          userId: userId,
          name: this.formName.trim(),
          phone: this.formPhone.trim(),
          region: this.formRegion.trim(),
          detail: this.formDetail.trim(),
          isDefault: this.formIsDefault,
          label: this.formLabel || undefined
        })
      }
      this.isSubmitting = false
      router.back()
    } catch (e) {
      this.isSubmitting = false
      ToastUtil.showToast(this.editMode ? '保存失败' : '新增失败')
    }
  }

  build() {
    Column() {
      // Navigation bar
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor('#333333')
          .width(44)
          .textAlign(TextAlign.Center)
          .onClick(() => router.back())

        Text(this.editMode ? '修改收货地址' : '新增收货地址')
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 44 })
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(44 + this.safeTop)
      .padding({ top: this.safeTop })
      .backgroundColor(Color.White)
      .alignItems(VerticalAlign.Center)

      // Form content
      Scroll() {
        Column() {
          Row().width(StyleConstants.FULL_WIDTH).height(12)

          // Form card
          Column() {
            // 收货人
            Row() {
              Text('收货人')
                .fontSize(14)
                .fontColor('#333333')
                .width(72)

              TextInput({ placeholder: '请填写收货人姓名', text: this.formName })
                .fontSize(14)
                .fontColor('#333333')
                .placeholderColor('#BBBBBB')
                .layoutWeight(1)
                .backgroundColor(Color.Transparent)
                .padding({ left: 0 })
                .onChange((val: string) => { this.formName = val })
            }
            .width(StyleConstants.FULL_WIDTH)
            .height(50)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)

            Row().width(StyleConstants.FULL_WIDTH).height(0.5).backgroundColor('#F0F0F0')

            // 手机号
            Row() {
              Text('手机号')
                .fontSize(14)
                .fontColor('#333333')
                .width(72)

              TextInput({ placeholder: '请填写手机号', text: this.formPhone })
                .fontSize(14)
                .fontColor('#333333')
                .placeholderColor('#BBBBBB')
                .layoutWeight(1)
                .backgroundColor(Color.Transparent)
                .padding({ left: 0 })
                .type(InputType.PhoneNumber)
                .onChange((val: string) => { this.formPhone = val })
            }
            .width(StyleConstants.FULL_WIDTH)
            .height(50)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)

            Row().width(StyleConstants.FULL_WIDTH).height(0.5).backgroundColor('#F0F0F0')

            // 省市区
            Row() {
              Text('省市区')
                .fontSize(14)
                .fontColor('#333333')
                .width(72)

              TextInput({ placeholder: '如"北京市朝阳区"', text: this.formRegion })
                .fontSize(14)
                .fontColor('#333333')
                .placeholderColor('#BBBBBB')
                .layoutWeight(1)
                .backgroundColor(Color.Transparent)
                .padding({ left: 0 })
                .onChange((val: string) => { this.formRegion = val })
            }
            .width(StyleConstants.FULL_WIDTH)
            .height(50)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)

            Row().width(StyleConstants.FULL_WIDTH).height(0.5).backgroundColor('#F0F0F0')

            // 详细地址
            Row() {
              Text('详细地址')
                .fontSize(14)
                .fontColor('#333333')
                .width(72)

              TextInput({ placeholder: '门牌号、楼层等', text: this.formDetail })
                .fontSize(14)
                .fontColor('#333333')
                .placeholderColor('#BBBBBB')
                .layoutWeight(1)
                .backgroundColor(Color.Transparent)
                .padding({ left: 0 })
                .onChange((val: string) => { this.formDetail = val })
            }
            .width(StyleConstants.FULL_WIDTH)
            .height(50)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
          }
          .width('calc(100% - 24vp)')
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ left: 12, right: 12 })

          Row().width(StyleConstants.FULL_WIDTH).height(12)

          // Default toggle card
          Column() {
            Row() {
              Column() {
                Text('设为默认地址')
                  .fontSize(14)
                  .fontColor('#333333')
                Text('下单时会优先使用该地址')
                  .fontSize(12)
                  .fontColor('#999999')
                  .margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Toggle({ type: ToggleType.Switch, isOn: this.formIsDefault })
                .selectedColor('#E53935')
                .onChange((isOn: boolean) => { this.formIsDefault = isOn })
            }
            .width(StyleConstants.FULL_WIDTH)
            .height(60)
            .padding({ left: 16, right: 16 })
            .alignItems(VerticalAlign.Center)
          }
          .width('calc(100% - 24vp)')
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ left: 12, right: 12 })

          Row().width(StyleConstants.FULL_WIDTH).height(12)

          // Label card
          Column() {
            Row() {
              Text('标签')
                .fontSize(14)
                .fontColor('#333333')
            }
            .width(StyleConstants.FULL_WIDTH)
            .padding({ left: 16, right: 16, top: 12, bottom: 10 })

            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.labelOptions, (label: string) => {
                Text(label)
                  .fontSize(13)
                  .fontColor(this.formLabel === label ? Color.White : '#999999')
                  .backgroundColor(this.formLabel === label ? '#E53935' : Color.Transparent)
                  .border({ width: 1, color: this.formLabel === label ? '#E53935' : '#CCCCCC', radius: 4 })
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .margin({ right: 10, bottom: 10 })
                  .onClick(() => {
                    this.formLabel = this.formLabel === label ? '' : label
                  })
              }, (label: string) => label)
            }
            .width(StyleConstants.FULL_WIDTH)
            .padding({ left: 16, right: 16, bottom: 8 })
          }
          .width('calc(100% - 24vp)')
          .backgroundColor(Color.White)
          .borderRadius(8)
          .margin({ left: 12, right: 12 })

          Row().width(StyleConstants.FULL_WIDTH).height(20)
        }
        .width(StyleConstants.FULL_WIDTH)
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .scrollBar(BarState.Off)

      // Confirm button
      Row() {
        Button(this.isSubmitting ? '提交中...' : '确认')
          .width('calc(100% - 32vp)')
          .height(48)
          .backgroundColor(this.isSubmitting ? '#CCCCCC' : '#E53935')
          .enabled(!this.isSubmitting)
          .fontColor(Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(8)
          .onClick(() => { this.handleSubmit() })
      }
      .width(StyleConstants.FULL_WIDTH)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 + this.safeBottom })
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.Center)
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .backgroundColor('#F5F5F5')
  }
}
