import { StyleConstants } from '@ohos/common'
import { ToastUtil } from '@pura/harmony-utils'
import router from '@ohos.router'
import {
  AddressInfo,
  queryAddressList,
  deleteAddress,
  setDefaultAddress
} from '../../service/addressService'

interface RouteParams {
  fromSettlement?: string
}

@Entry
@Component
struct Address {
  @StorageProp('safeTop') safeTop: number = 0
  @StorageProp('safeBottom') safeBottom: number = 0
  @StorageProp('userAccount') userAccount: string = 'guest'

  @State addressList: AddressInfo[] = []
  @State isLoading: boolean = false
  @State fromSettlement: boolean = false

  aboutToAppear() {
    const params = router.getParams() as RouteParams
    this.fromSettlement = params?.fromSettlement === 'true'
    this.loadAddressList()
  }

  onPageShow() {
    this.loadAddressList()
  }

  private loadAddressList() {
    const userId = this.userAccount || 'guest'
    this.isLoading = true
    queryAddressList(userId).then(list => {
      this.addressList = list
      this.isLoading = false
    }).catch(() => {
      this.isLoading = false
      ToastUtil.showToast('加载地址失败')
    })
  }

  private handleSetDefault(addr: AddressInfo) {
    if (addr.isDefault) return
    const userId = this.userAccount || 'guest'
    setDefaultAddress(userId, addr.id).then(() => {
      this.loadAddressList()
    }).catch(() => {
      ToastUtil.showToast('设置失败')
    })
  }

  private handleDelete(addr: AddressInfo) {
    const userId = this.userAccount || 'guest'
    deleteAddress(userId, addr.id).then(() => {
      this.loadAddressList()
    }).catch(() => {
      ToastUtil.showToast('删除失败')
    })
  }

  private handleEdit(addr: AddressInfo) {
    router.pushUrl({
      url: 'pages/mine/addressEdit',
      params: { mode: 'edit', addressJson: JSON.stringify(addr) }
    })
  }

  private handleSelect(addr: AddressInfo) {
    AppStorage.setOrCreate('selectedAddressJson', JSON.stringify(addr))
    router.back()
  }

  @Builder
  AddressCard(addr: AddressInfo) {
    Column() {
      // Top row: name, phone, tags
      Row() {
        if (addr.isDefault) {
          Text('●')
            .fontSize(18)
            .fontColor('#E53935')
            .margin({ right: 8 })
        }
        Text(addr.name)
          .fontSize(15)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .margin({ right: 10 })

        Text(addr.phone)
          .fontSize(14)
          .fontColor('#666666')
          .layoutWeight(1)

        if (addr.isDefault) {
          Text('默认')
            .fontSize(11)
            .fontColor('#E53935')
            .border({ width: 1, color: '#E53935', radius: 2 })
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .margin({ right: 4 })
        }

        if (addr.label) {
          Text(addr.label)
            .fontSize(11)
            .fontColor(Color.White)
            .backgroundColor('#4CAF50')
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .borderRadius(2)
        }
      }
      .width(StyleConstants.FULL_WIDTH)
      .padding({ left: 14, right: 14, top: 14, bottom: 8 })
      .alignItems(VerticalAlign.Center)

      // Address line
      Text(`${addr.region} ${addr.detail}`)
        .fontSize(13)
        .fontColor('#666666')
        .width(StyleConstants.FULL_WIDTH)
        .padding({ left: addr.isDefault ? 40 : 14, right: 14, bottom: 10 })
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // Separator
      Row()
        .width(StyleConstants.FULL_WIDTH)
        .height(0.5)
        .backgroundColor('#F0F0F0')

      // Action row
      Row() {
        // Left: set default checkbox
        Row() {
          Text(addr.isDefault ? '✓' : '□')
            .fontSize(14)
            .fontColor(addr.isDefault ? '#E53935' : '#999999')
            .margin({ right: 4 })
          Text(addr.isDefault ? '已默认' : '设为默认')
            .fontSize(13)
            .fontColor(addr.isDefault ? '#E53935' : '#999999')
        }
        .onClick(() => this.handleSetDefault(addr))

        Blank()

        if (!this.fromSettlement) {
          Row() {
            Text('删除')
              .fontSize(13)
              .fontColor('#999999')
              .onClick(() => this.handleDelete(addr))

            Text('|')
              .fontSize(13)
              .fontColor('#E0E0E0')
              .margin({ left: 12, right: 12 })

            Text('修改')
              .fontSize(13)
              .fontColor('#999999')
              .onClick(() => this.handleEdit(addr))
          }
          .alignItems(VerticalAlign.Center)
        }
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(40)
      .padding({ left: 14, right: 14 })
      .alignItems(VerticalAlign.Center)
    }
    .width('calc(100% - 24vp)')
    .backgroundColor(Color.White)
    .borderRadius(8)
    .border({
      width: addr.isDefault ? 1.5 : 1,
      color: addr.isDefault ? '#E53935' : '#E0E0E0',
      radius: 8
    })
    .margin({ left: 12, right: 12, bottom: 12 })
    .onClick(() => {
      if (this.fromSettlement) {
        this.handleSelect(addr)
      }
    })
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

        Text('收货地址')
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

      // Content
      Scroll() {
        Column() {
          Row().width(StyleConstants.FULL_WIDTH).height(12)

          if (this.isLoading) {
            Text('加载中...')
              .fontSize(14)
              .fontColor('#999999')
              .width(StyleConstants.FULL_WIDTH)
              .textAlign(TextAlign.Center)
              .margin({ top: 40 })
          } else if (this.addressList.length === 0) {
            Text('暂无收货地址')
              .fontSize(14)
              .fontColor('#999999')
              .width(StyleConstants.FULL_WIDTH)
              .textAlign(TextAlign.Center)
              .margin({ top: 40 })
          } else {
            ForEach(this.addressList, (addr: AddressInfo) => {
              this.AddressCard(addr)
            }, (addr: AddressInfo) => addr.id.toString())
          }

          Row().width(StyleConstants.FULL_WIDTH).height(12)
        }
        .width(StyleConstants.FULL_WIDTH)
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .scrollBar(BarState.Off)

      // Bottom add button (non-selection mode)
      if (!this.fromSettlement) {
        Row() {
          Button('新增收货地址')
            .width('calc(100% - 32vp)')
            .height(48)
            .backgroundColor('#E53935')
            .fontColor(Color.White)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .borderRadius(8)
            .onClick(() => {
              router.pushUrl({ url: 'pages/mine/addressEdit', params: { mode: 'add' } })
            })
        }
        .width(StyleConstants.FULL_WIDTH)
        .padding({ left: 16, right: 16, top: 12, bottom: 12 + this.safeBottom })
        .backgroundColor(Color.White)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .backgroundColor('#F5F5F5')
  }
}
