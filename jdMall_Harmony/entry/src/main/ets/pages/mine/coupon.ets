import { StyleConstants } from '@ohos/common'
import { ToastUtil } from '@pura/harmony-utils'
import router from '@ohos.router'
import { CouponInfo, queryCouponList, receiveCoupon } from '../../service/couponService'

@Entry
@Component
struct Coupon {
  @StorageProp('safeTop') safeTop: number = 0
  @StorageProp('safeBottom') safeBottom: number = 0
  @StorageProp('userAccount') userAccount: string = ''

  @State currentTab: number = 0
  @State couponList: CouponInfo[] = []
  @State isLoading: boolean = false

  private tabLabels: string[] = ['未使用', '已使用', '已过期']
  private statusMap: string[] = ['UNUSED', 'USED', 'EXPIRED']

  aboutToAppear() {
    this.loadCoupons()
  }

  private loadCoupons() {
    this.isLoading = true
    const userId = this.userAccount || 'guest'
    const status = this.statusMap[this.currentTab]
    queryCouponList(userId, status)
      .then(list => {
        this.couponList = list
        this.isLoading = false
      })
      .catch(() => {
        this.isLoading = false
        ToastUtil.showToast('加载失败，请重试')
      })
  }

  private formatDate(dateStr: string): string {
    if (!dateStr) {
      return ''
    }
    return dateStr.substring(0, 10)
  }

  private formatAmount(amount: number): string {
    return amount % 1 === 0 ? amount.toFixed(0) : amount.toFixed(2)
  }

  private receiveCouponAction() {
    const userId = this.userAccount || 'guest'
    receiveCoupon(userId)
      .then(() => {
        ToastUtil.showToast('领取成功')
        this.currentTab = 0
        this.loadCoupons()
      })
      .catch(() => {
        ToastUtil.showToast('领取失败，请重试')
      })
  }

  @Builder
  CouponCard(coupon: CouponInfo) {
    Row() {
      // Left gradient amount block
      Column() {
        Text('¥')
          .fontSize(12)
          .fontColor(Color.White)
          .margin({ bottom: 0 })
        Text(this.formatAmount(coupon.amount))
          .fontSize(26)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
      }
      .width(80)
      .height(StyleConstants.FULL_HEIGHT)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [['#E53935', 0.0], ['#FF6B35', 1.0]]
      })
      .borderRadius({ topLeft: 8, bottomLeft: 8, topRight: 0, bottomRight: 0 })
      .opacity(coupon.status === 'UNUSED' ? 1.0 : 0.45)

      // Right info section
      Column() {
        Text(coupon.name)
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 4 })

        Text(coupon.type === 'NO_THRESHOLD' ? '无门槛，限购物使用' : `满¥${coupon.minOrderAmount}元可用`)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ bottom: 4 })

        Text(`有效期至 ${this.formatDate(coupon.expireAt)}`)
          .fontSize(12)
          .fontColor('#999999')

        Row() {
          Text(coupon.status === 'UNUSED' ? '立即使用' : (coupon.status === 'USED' ? '已使用' : '已过期'))
            .fontSize(12)
            .fontColor(coupon.status === 'UNUSED' ? '#E53935' : '#CCCCCC')
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .border({
              radius: 12,
              width: 1,
              color: coupon.status === 'UNUSED' ? '#E53935' : '#CCCCCC'
            })
        }
        .margin({ top: 8 })
        .onClick(() => {
          if (coupon.status === 'UNUSED') {
            router.pushUrl({ url: 'pages/order/settlement' })
          }
        })
      }
      .layoutWeight(1)
      .height(StyleConstants.FULL_HEIGHT)
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('calc(100% - 24vp)')
    .height(110)
    .backgroundColor(coupon.status === 'UNUSED' ? Color.White : '#FAFAFA')
    .borderRadius(8)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: 2 })
    .margin({ left: 12, right: 12, bottom: 12 })
    .clip(true)
  }

  build() {
    Column() {
      // NavBar
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .width(44)
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back()
          })

        Text('红包')
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

      // Tab bar
      Row() {
        ForEach(this.tabLabels, (label: string, index: number) => {
          Column() {
            Text(label)
              .fontSize(15)
              .fontColor(this.currentTab === index ? '#E53935' : '#666666')
              .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Normal)

            Row()
              .width(24)
              .height(2)
              .backgroundColor(this.currentTab === index ? '#E53935' : Color.Transparent)
              .borderRadius(1)
              .margin({ top: 6 })
          }
          .layoutWeight(1)
          .height(44)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.currentTab = index
            this.loadCoupons()
          })
        }, (label: string) => label)
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(44)
      .backgroundColor(Color.White)
      .border({ width: { bottom: 0.5 }, color: '#F0F0F0' })

      // Coupon list
      Scroll() {
        Column() {
          if (this.isLoading) {
            LoadingProgress()
              .height(40)
              .width(40)
              .color('#E53935')
              .margin({ top: 60 })
          } else if (this.couponList.length === 0) {
            Column() {
              Text('暂无红包')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 8 })
            }
            .width(StyleConstants.FULL_WIDTH)
            .margin({ top: 80 })
            .alignItems(HorizontalAlign.Center)
          } else {
            ForEach(this.couponList, (coupon: CouponInfo) => {
              this.CouponCard(coupon)
            }, (coupon: CouponInfo) => coupon.id.toString())
          }
        }
        .width(StyleConstants.FULL_WIDTH)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 12, bottom: 80 })
      }
      .layoutWeight(1)
      .width(StyleConstants.FULL_WIDTH)
      .backgroundColor('#F5F5F5')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      // Bottom receive bar
      Row() {
        Button('领取红包')
          .width('calc(100% - 32vp)')
          .height(48)
          .backgroundColor('#E53935')
          .fontColor(Color.White)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(24)
          .onClick(() => {
            this.receiveCouponAction()
          })
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(64 + this.safeBottom)
      .padding({ bottom: this.safeBottom, left: 16, right: 16 })
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.Center)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)', offsetY: -2 })
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .backgroundColor('#F5F5F5')
  }
}
