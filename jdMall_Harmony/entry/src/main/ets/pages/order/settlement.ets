import { StyleConstants } from '@ohos/common'
import { AppUtil, ToastUtil } from '@pura/harmony-utils'
import router from '@ohos.router'
import { GoodsInfo, queryCartGoodsList, StoreGoodsInfo } from '../../service/cartService'
import { createOrder, CreateOrderResult, CreateOrderParams } from '../../service/orderService'
import { AddressInfo, queryAddressList } from '../../service/addressService'

interface RouteParams {
  orderId: number
  orderNo: string
}

@Entry
@Component
export struct Settlement {
  @State cartStoreGoodsList: StoreGoodsInfo[] = []
  @State totalAmount: number = 0
  @State selectedCount: number = 0
  @State isLoading: boolean = false
  @StorageProp('userAccount') userAccount: string = 'guest'
  @StorageProp('safeBottom') safeBottom: number = 0
  @StorageProp('safeTop') safeTop: number = 0

  // 收货信息
  @State receiverName: string = ''
  @State receiverPhone: string = ''
  @State receiverAddress: string = ''
  @State remark: string = ''
  @State currentAddressId: number = 0

  // 号码保护开关
  @State phoneProtected: boolean = true

  aboutToAppear() {
    this.querySettlementInfo()
    this.loadDefaultAddress()
  }

  onPageShow() {
    const json = AppStorage.get('selectedAddressJson') as string
    if (json) {
      try {
        const addr = JSON.parse(json) as AddressInfo
        this.receiverName = addr.name
        this.receiverPhone = addr.phone
        this.receiverAddress = addr.region + ' ' + addr.detail
        this.currentAddressId = addr.id
      } catch (e) {
        // ignore parse error
      }
      AppStorage.setOrCreate('selectedAddressJson', '')
    }
  }

  private loadDefaultAddress() {
    const userId = this.userAccount || 'guest'
    queryAddressList(userId).then(list => {
      const defaultAddr = list.find(a => a.isDefault)
      const addr = defaultAddr || (list.length > 0 ? list[0] : null)
      if (addr) {
        this.receiverName = addr.name
        this.receiverPhone = addr.phone
        this.receiverAddress = addr.region + ' ' + addr.detail
        this.currentAddressId = addr.id
      }
    }).catch(() => {})
  }

  querySettlementInfo() {
    queryCartGoodsList(this.userAccount).then(list => {
      if (!list || list.length === 0) {
        ToastUtil.showToast('购物车中没有已选商品')
        return
      }

      this.cartStoreGoodsList = list
      this.calculateTotals()
    }).catch(() => {
      ToastUtil.showToast('加载商品信息失败')
    })
  }

  private calculateTotals() {
    let total = 0
    let count = 0

    for (const store of this.cartStoreGoodsList) {
      for (const goods of store.goodsList) {
        if (goods.select) {
          const price = this.parsePrice(goods.price)
          total += price * goods.num
          count += goods.num
        }
      }
    }

    this.totalAmount = total
    this.selectedCount = count
  }

  private getFinalAmount(): number {
    return this.totalAmount
  }

  private parsePrice(price: string | number | undefined): number {
    if (typeof price === 'number') {
      return price
    }
    if (typeof price === 'string') {
      return parseFloat(price) || 0
    }
    return 0
  }

  private getPriceString(price: string | number | undefined): string {
    return this.parsePrice(price).toFixed(2)
  }

  private getMaskedPhone(phone: string): string {
    if (phone && phone.length >= 7) {
      return phone.substring(0, 3) + '****' + phone.substring(7)
    }
    return phone
  }

  private async submitOrder() {
    if (!this.receiverName.trim()) {
      ToastUtil.showToast('请添加收货地址')
      return
    }
    if (!this.receiverPhone.trim()) {
      ToastUtil.showToast('请添加收货地址')
      return
    }
    if (!this.receiverAddress.trim()) {
      ToastUtil.showToast('请添加收货地址')
      return
    }
    if (this.selectedCount === 0) {
      ToastUtil.showToast('请选择要购买的商品')
      return
    }

    const params: CreateOrderParams = {
      userId: this.userAccount,
      receiverName: this.receiverName,
      receiverPhone: this.receiverPhone,
      receiverAddress: this.receiverAddress,
      remark: this.remark
    }

    this.doCreateOrder(params)
  }

  private doCreateOrder(params: CreateOrderParams) {
    this.isLoading = true
    const promise: Promise<CreateOrderResult> = createOrder(params)
    promise
      .then((result: CreateOrderResult) => {
        this.isLoading = false
        if (result) {
          ToastUtil.showToast('订单创建成功')
          const routeParams: RouteParams = {
            orderId: result.orderId,
            orderNo: result.orderNo
          }
          router.pushUrl({
            url: 'pages/order/orderDetail',
            params: routeParams
          })
        }
      })
      .catch(() => {
        this.isLoading = false
        ToastUtil.showToast('订单创建失败')
      })
  }

  @Builder
  AddressSection() {
    Column() {
      Row() {
        Text('默认')
          .fontSize(10)
          .fontColor(Color.White)
          .backgroundColor('#E53935')
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .borderRadius(2)
          .margin({ right: 4 })

        Text('家')
          .fontSize(10)
          .fontColor(Color.White)
          .backgroundColor('#4CAF50')
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .borderRadius(2)
          .margin({ right: 8 })

        Text(this.receiverAddress || '请添加收货地址')
          .fontSize(15)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Image($r('app.media.ic_arrow_right'))
          .width(14)
          .height(14)
          .fillColor('#999999')
          .margin({ left: 8 })
      }
      .width(StyleConstants.FULL_WIDTH)
      .padding({ left: 16, right: 16, top: 14, bottom: 8 })
      .alignItems(VerticalAlign.Center)

      Row() {
        Text(this.receiverName)
          .fontSize(14)
          .fontColor('#333333')
          .margin({ right: 12 })

        Text(this.getMaskedPhone(this.receiverPhone))
          .fontSize(14)
          .fontColor('#999999')
      }
      .width(StyleConstants.FULL_WIDTH)
      .padding({ left: 16, right: 16, bottom: 14 })

      Row()
        .width(StyleConstants.FULL_WIDTH)
        .height(1)
        .backgroundColor('#F0F0F0')

      Row()
        .width(StyleConstants.FULL_WIDTH)
        .height(3)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [['#E53935', 0], ['#FF8A80', 0.5], ['#E53935', 1]]
        })
    }
    .width(StyleConstants.FULL_WIDTH)
    .backgroundColor(Color.White)
    .onClick(() => {
      router.pushUrl({ url: 'pages/mine/address', params: { fromSettlement: 'true' } })
    })
  }

  @Builder
  InvoiceSection() {
    Row() {
      Text('发票')
        .fontSize(14)
        .fontColor('#333333')

      Blank()

      Text('数电普票(不开发票-个人) >')
        .fontSize(13)
        .fontColor('#999999')
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  PhoneProtectSection() {
    Row() {
      Text('号码保护（隐藏收件人真实号码）')
        .fontSize(14)
        .fontColor('#333333')

      Text(' ⓘ')
        .fontSize(14)
        .fontColor('#999999')

      Blank()

      Toggle({ type: ToggleType.Switch, isOn: this.phoneProtected })
        .selectedColor('#E53935')
        .onChange((isOn: boolean) => {
          this.phoneProtected = isOn
        })
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Stack() {
      // Main content
      Column() {
        // 导航栏
        Row() {
          Text('←')
            .fontSize(20)
            .fontColor('#333333')
            .width(40)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              router.back()
            })

          Text('确认订单')
            .fontSize(18)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .margin({ right: 40 })
        }
        .width(StyleConstants.FULL_WIDTH)
        .height(44 + this.safeTop)
        .padding({ top: this.safeTop, left: 16, right: 16 })
        .backgroundColor(Color.White)
        .alignItems(VerticalAlign.Center)

        Scroll() {
          Column() {
            // 地址区域
            this.AddressSection()

            Row()
              .width(StyleConstants.FULL_WIDTH)
              .height(10)
              .backgroundColor('#F5F5F5')

            // 店铺商品区域
            ForEach(this.cartStoreGoodsList, (store: StoreGoodsInfo) => {
              Column() {
                // 店铺头部行
                Row() {
                  Image($r('app.media.ic_store'))
                    .width(16)
                    .height(16)
                    .fillColor('#333333')
                    .margin({ right: 6 })

                  Text(store.storeName || '未知店铺')
                    .fontSize(14)
                    .fontColor('#333333')
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)

                  Image($r('app.media.ic_arrow_right'))
                    .width(14)
                    .height(14)
                    .fillColor('#999999')
                }
                .width(StyleConstants.FULL_WIDTH)
                .height(44)
                .padding({ left: 16, right: 16 })
                .alignItems(VerticalAlign.Center)

                Row()
                  .width(StyleConstants.FULL_WIDTH)
                  .height(0.5)
                  .backgroundColor('#F0F0F0')

                // 商品列表
                ForEach(store.goodsList, (goods: GoodsInfo) => {
                  if (goods.select) {
                    Column() {
                      // 商品行
                      Row() {
                        Image(goods.imgUrl)
                          .width(90)
                          .height(90)
                          .borderRadius(4)
                          .backgroundColor('#F5F5F5')
                          .objectFit(ImageFit.Cover)
                          .margin({ right: 12 })

                        Column() {
                          Text(goods.description)
                            .fontSize(14)
                            .fontColor('#333333')
                            .maxLines(2)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .lineHeight(20)
                            .margin({ bottom: 4 })

                          if (goods.color || goods.size) {
                            Text(`${goods.color ? goods.color : ''}${goods.color && goods.size ? ' | ' : ''}${goods.size ? goods.size : ''}`)
                              .fontSize(12)
                              .fontColor('#999999')
                              .margin({ bottom: 4 })
                          }

                          Blank()

                          Row() {
                            Text(`¥${this.getPriceString(goods.price)}`)
                              .fontSize(16)
                              .fontColor('#E53935')
                              .fontWeight(FontWeight.Bold)

                            Blank()

                            Text(`x${goods.num}`)
                              .fontSize(14)
                              .fontColor('#999999')
                          }
                          .width(StyleConstants.FULL_WIDTH)
                        }
                        .layoutWeight(1)
                        .height(90)
                        .alignItems(HorizontalAlign.Start)
                      }
                      .width(StyleConstants.FULL_WIDTH)
                      .padding({ left: 16, right: 16, top: 12, bottom: 8 })

                      // 服务标签行
                      Row() {
                        Text('支持7天无理由退货')
                          .fontSize(11)
                          .fontColor('#E53935')
                          .backgroundColor('#FFF0F0')
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                          .borderRadius(2)
                          .margin({ right: 8 })

                        Text('7天价保')
                          .fontSize(11)
                          .fontColor('#E53935')
                          .backgroundColor('#FFF0F0')
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                          .borderRadius(2)
                      }
                      .width(StyleConstants.FULL_WIDTH)
                      .padding({ left: 16, right: 16, bottom: 12 })

                      Row()
                        .width(StyleConstants.FULL_WIDTH)
                        .height(0.5)
                        .backgroundColor('#F0F0F0')

                      // 配送行
                      Row() {
                        Text('配送')
                          .fontSize(14)
                          .fontColor('#999999')

                        Blank()

                        Column() {
                          Row() {
                            Text('快递运输')
                              .fontSize(14)
                              .fontColor('#333333')

                            Image($r('app.media.ic_arrow_right'))
                              .width(12)
                              .height(12)
                              .fillColor('#999999')
                              .margin({ left: 2 })
                          }
                          .alignItems(VerticalAlign.Center)

                          Text('预计今天发货')
                            .fontSize(12)
                            .fontColor('#999999')
                            .margin({ top: 2 })
                        }
                        .alignItems(HorizontalAlign.End)
                      }
                      .width(StyleConstants.FULL_WIDTH)
                      .height(52)
                      .padding({ left: 16, right: 16 })
                      .alignItems(VerticalAlign.Center)
                    }
                    .width(StyleConstants.FULL_WIDTH)
                  }
                }, (goods: GoodsInfo) => goods.id.toString())
              }
              .width(StyleConstants.FULL_WIDTH)
              .backgroundColor(Color.White)
            }, (store: StoreGoodsInfo) => store.storeCode)

            Row()
              .width(StyleConstants.FULL_WIDTH)
              .height(10)
              .backgroundColor('#F5F5F5')

            // 价格明细区域
            Column() {
              Row() {
                Text('商品金额')
                  .fontSize(14)
                  .fontColor('#666666')

                Blank()

                Text(`¥${this.totalAmount.toFixed(2)}`)
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width(StyleConstants.FULL_WIDTH)
              .height(48)
              .padding({ left: 16, right: 16 })
              .alignItems(VerticalAlign.Center)

              Row()
                .width(StyleConstants.FULL_WIDTH)
                .height(0.5)
                .backgroundColor('#F0F0F0')

              Row() {
                Text('运费')
                  .fontSize(14)
                  .fontColor('#666666')

                Blank()

                Text('¥0.00')
                  .fontSize(14)
                  .fontColor('#333333')
              }
              .width(StyleConstants.FULL_WIDTH)
              .height(48)
              .padding({ left: 16, right: 16 })
              .alignItems(VerticalAlign.Center)

              Row()
                .width(StyleConstants.FULL_WIDTH)
                .height(0.5)
                .backgroundColor('#F0F0F0')

              Row() {
                Text('礼品卡(京东卡/E卡)')
                  .fontSize(14)
                  .fontColor('#666666')

                Blank()

                Text('无可用 >')
                  .fontSize(14)
                  .fontColor('#999999')
              }
              .width(StyleConstants.FULL_WIDTH)
              .height(48)
              .padding({ left: 16, right: 16 })
              .alignItems(VerticalAlign.Center)

              Row()
                .width(StyleConstants.FULL_WIDTH)
                .height(0.5)
                .backgroundColor('#F0F0F0')

              // 合计行
              Row() {
                Blank()

                Text('合计：')
                  .fontSize(14)
                  .fontColor('#333333')

                Text(`¥${this.getFinalAmount().toFixed(2)}`)
                  .fontSize(16)
                  .fontColor('#E53935')
                  .fontWeight(FontWeight.Bold)
              }
              .width(StyleConstants.FULL_WIDTH)
              .height(48)
              .padding({ left: 16, right: 16 })
              .alignItems(VerticalAlign.Center)
            }
            .width(StyleConstants.FULL_WIDTH)
            .backgroundColor(Color.White)

            Row()
              .width(StyleConstants.FULL_WIDTH)
              .height(10)
              .backgroundColor('#F5F5F5')

            // 发票区域
            this.InvoiceSection()

            Row()
              .width(StyleConstants.FULL_WIDTH)
              .height(10)
              .backgroundColor('#F5F5F5')

            // 号码保护区域
            this.PhoneProtectSection()

            // 底部留白
            Row()
              .width(StyleConstants.FULL_WIDTH)
              .height(16)
              .backgroundColor('#F5F5F5')
          }
          .width(StyleConstants.FULL_WIDTH)
        }
        .layoutWeight(1)
        .width(StyleConstants.FULL_WIDTH)
        .backgroundColor('#F5F5F5')

        // 底部支付栏
        Row() {
          Row() {
            Text('¥')
              .fontSize(14)
              .fontColor('#E53935')
              .margin({ bottom: 2 })

            Text(this.getFinalAmount().toFixed(2).split('.')[0])
              .fontSize(24)
              .fontColor('#E53935')
              .fontWeight(FontWeight.Bold)

            Text('.' + this.getFinalAmount().toFixed(2).split('.')[1])
              .fontSize(14)
              .fontColor('#E53935')
              .margin({ bottom: 2 })
          }
          .margin({ left: 16 })
          .alignItems(VerticalAlign.Bottom)

          Blank()

          Button(this.isLoading ? '提交中...' : '在线支付')
            .width(140)
            .height(44)
            .backgroundColor(this.selectedCount === 0 || this.isLoading ? '#CCCCCC' : '#E53935')
            .enabled(this.selectedCount > 0 && !this.isLoading)
            .fontColor(Color.White)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .borderRadius(22)
            .margin({ right: 16 })
            .onClick(() => {
              this.submitOrder()
            })
        }
        .width(StyleConstants.FULL_WIDTH)
        .height(64 + this.safeBottom)
        .backgroundColor(Color.White)
        .padding({ bottom: this.safeBottom })
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetY: -2 })
        .alignItems(VerticalAlign.Center)
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(StyleConstants.FULL_HEIGHT)
      .backgroundColor('#F5F5F5')

    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
  }
}
