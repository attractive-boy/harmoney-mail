import { StyleConstants } from '@ohos/common'
import { AppUtil, ToastUtil, WindowUtil } from '@pura/harmony-utils'
import router from '@ohos.router'
import { GoodsInfo, queryCartGoodsList, StoreGoodsInfo } from '../../service/cartService'
import { createOrder, CreateOrderResult, CreateOrderParams } from '../../service/orderService'

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
  
  // 收货信息
  @State receiverName: string = ''
  @State receiverPhone: string = ''
  @State receiverAddress: string = ''
  @State remark: string = ''

  aboutToAppear() {
    this.querySettlementInfo()
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

  private async submitOrder() {
    if (!this.receiverName.trim()) {
      ToastUtil.showToast('请输入收货人名称')
      return
    }
    if (!this.receiverPhone.trim()) {
      ToastUtil.showToast('请输入收货人电话')
      return
    }
    if (!this.receiverAddress.trim()) {
      ToastUtil.showToast('请输入收货地址')
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

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('订单结算')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(56)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#F5F5F5')

      Scroll() {
        Column() {
          // 收货信息
          Column() {
            Text('收货信息')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })

            // 收货人
            Column() {
              Text('收货人')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ bottom: 4 })
              TextInput({ placeholder: '请输入收货人名称', text: this.receiverName })
                .onChange((value: string) => {
                  this.receiverName = value
                })
                .fontSize(14)
                .height(40)
                .padding({ left: 12, right: 12 })
                .backgroundColor(Color.White)
                .border({ width: 1, color: '#EAEAEA' })
                .borderRadius(4)
            }
            .width(StyleConstants.FULL_WIDTH)
            .margin({ bottom: 12 })

            // 电话号码
            Column() {
              Text('联系电话')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ bottom: 4 })
              TextInput({ placeholder: '请输入联系电话', text: this.receiverPhone })
                .onChange((value: string) => {
                  this.receiverPhone = value
                })
                .fontSize(14)
                .height(40)
                .padding({ left: 12, right: 12 })
                .backgroundColor(Color.White)
                .border({ width: 1, color: '#EAEAEA' })
                .borderRadius(4)
                .type(InputType.Number)
            }
            .width(StyleConstants.FULL_WIDTH)
            .margin({ bottom: 12 })

            // 收货地址
            Column() {
              Text('收货地址')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ bottom: 4 })
              TextInput({ placeholder: '请输入收货地址', text: this.receiverAddress })
                .onChange((value: string) => {
                  this.receiverAddress = value
                })
                .fontSize(14)
                .height(40)
                .padding({ left: 12, right: 12 })
                .backgroundColor(Color.White)
                .border({ width: 1, color: '#EAEAEA' })
                .borderRadius(4)
            }
            .width(StyleConstants.FULL_WIDTH)
            .margin({ bottom: 12 })

            // 备注
            Column() {
              Text('订单备注（可选）')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ bottom: 4 })
              TextInput({ placeholder: '请输入订单备注', text: this.remark })
                .onChange((value: string) => {
                  this.remark = value
                })
                .fontSize(14)
                .height(80)
                .padding({ left: 12, right: 12, top: 12, bottom: 12 })
                .backgroundColor(Color.White)
                .border({ width: 1, color: '#EAEAEA' })
                .borderRadius(4)
            }
            .width(StyleConstants.FULL_WIDTH)
          }
          .width(StyleConstants.FULL_WIDTH)
          .padding(12)
          .backgroundColor(Color.White)
          .margin({ bottom: 12 })

          // 订单商品
          Column() {
            Text('订单商品')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })

            ForEach(this.cartStoreGoodsList, (store: StoreGoodsInfo) => {
              Column() {
                Text(store.storeName || '未知店铺')
                  .fontSize(12)
                  .fontColor('#666666')
                  .margin({ bottom: 12 })

                ForEach(store.goodsList, (goods: GoodsInfo) => {
                  if (goods.select) {
                    Row() {
                      Image(goods.imgUrl)
                        .width(60)
                        .height(60)
                        .borderRadius(4)
                        .backgroundColor('#F0F0F0')
                        .margin({ right: 12 })

                      Column() {
                        Text(goods.description)
                          .fontSize(12)
                          .fontColor('#333333')
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .margin({ bottom: 4 })

                        if (goods.color) {
                          Text(`颜色: ${goods.color}`)
                            .fontSize(11)
                            .fontColor('#999999')
                            .margin({ bottom: 2 })
                        }

                        if (goods.size) {
                          Text(`尺寸: ${goods.size}`)
                            .fontSize(11)
                            .fontColor('#999999')
                            .margin({ bottom: 2 })
                        }
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)

                      Column() {
                        Text(`￥${this.getPriceString(goods.price)}`)
                          .fontSize(12)
                          .fontColor('#E53935')
                          .fontWeight(FontWeight.Bold)
                          .margin({ bottom: 4 })

                        Text(`x${goods.num}`)
                          .fontSize(11)
                          .fontColor('#999999')
                      }
                      .alignItems(HorizontalAlign.End)
                    }
                    .width(StyleConstants.FULL_WIDTH)
                    .padding({ bottom: 12 })
                    .margin({ bottom: 12 })
                  }
                }, (goods: GoodsInfo) => goods.id.toString())
              }
              .width(StyleConstants.FULL_WIDTH)
            }, (store: StoreGoodsInfo) => store.storeCode)
          }
          .width(StyleConstants.FULL_WIDTH)
          .padding(12)
          .backgroundColor(Color.White)
          .margin({ bottom: 12 })

          // 费用详情
          Column() {
            Row() {
              Text('商品合计')
                .fontSize(12)
                .fontColor('#666666')
              Blank()
              Text(`￥${this.totalAmount.toFixed(2)}`)
                .fontSize(12)
                .fontColor('#333333')
            }
            .width(StyleConstants.FULL_WIDTH)
            .margin({ bottom: 8 })

            Row() {
              Text('运费')
                .fontSize(12)
                .fontColor('#666666')
              Blank()
              Text('￥0.00')
                .fontSize(12)
                .fontColor('#333333')
            }
            .width(StyleConstants.FULL_WIDTH)
            .margin({ bottom: 12 })
            .padding({ bottom: 12 })

            Divider()
              .margin({ bottom: 12 })

            Row() {
              Text('应付金额')
                .fontSize(14)
                .fontColor('#333333')
                .fontWeight(FontWeight.Bold)
              Blank()
              Text(`￥${this.totalAmount.toFixed(2)}`)
                .fontSize(16)
                .fontColor('#E53935')
                .fontWeight(FontWeight.Bold)
            }
            .width(StyleConstants.FULL_WIDTH)
          }
          .width(StyleConstants.FULL_WIDTH)
          .padding(12)
          .backgroundColor(Color.White)
          .margin({ bottom: 12 })
        }
        .width(StyleConstants.FULL_WIDTH)
        .padding(12)
      }
      .layoutWeight(1)
      .width(StyleConstants.FULL_WIDTH)

      // 提交按钮
      Button(this.isLoading ? '提交中...' : '提交订单')
        .width(`calc(100% - 24vp)`)
        .height(48)
        .margin({ left: 12, right: 12, bottom: this.safeBottom + 12 })
        .backgroundColor(this.selectedCount === 0 || this.isLoading ? '#CCCCCC' : '#E53935')
        .enabled(this.selectedCount > 0 && !this.isLoading)
        .fontColor(Color.White)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .onClick(() => {
          this.submitOrder()
        })
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .backgroundColor('#F5F5F5')
  }
}
