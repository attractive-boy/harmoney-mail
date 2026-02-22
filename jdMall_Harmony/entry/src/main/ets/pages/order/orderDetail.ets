import router from '@ohos.router'
import { StyleConstants } from '@ohos/common'
import { ImageKnifeView } from '@ohos/common'
import { AppUtil, ToastUtil } from '@pura/harmony-utils'
import {
  queryOrderDetail,
  cancelOrder,
  payOrder,
  confirmOrder,
  deleteOrder,
  OrderInfo,
  OrderItem
} from '../../service/orderService'

@Entry
@Component
export struct OrderDetail {
  @State orderInfo: OrderInfo | null = null
  @State isLoading: boolean = true
  @State userId: string = 'guest'
  @State orderId: number = 0

  @StorageProp('safeTop') safeTop: number = 0
  @StorageProp('safeBottom') safeBottom: number = 0

  private scroller: Scroller = new Scroller()

  aboutToAppear() {
    const storedUser = AppStorage.Get<string>('userAccount')
    this.userId = storedUser ? storedUser : 'guest'
    
    const params = router.getParams() as Record<string, number>
    this.orderId = params?.orderId || 0
    
    if (this.orderId > 0) {
      this.loadOrderDetail()
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.Header()
        
        if (this.isLoading) {
          Column() {
            Text('加载中...')
              .fontSize(14)
              .fontColor('#999999')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.orderInfo === null) {
          Column() {
            Text('订单不存在')
              .fontSize(14)
              .fontColor('#999999')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll(this.scroller) {
            Column() {
              this.StatusSection()
              this.AddressSection()
              this.GoodsSection()
              this.InfoSection()
            }
            .padding({ bottom: this.safeBottom + 70 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(StyleConstants.FULL_HEIGHT)
      .backgroundColor('#F5F5F5')
      
      if (this.orderInfo !== null) {
        this.ActionBar()
      }
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
  }

  @Builder
  Header() {
    Row() {
      Text('←')
        .fontSize(20)
        .fontColor(Color.Black)
        .onClick(() => router.back())
        .padding({ left: 12, right: 12 })
      
      Text('订单详情')
        .fontSize(18)
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Medium)
      
      Blank()
    }
    .width('100%')
    .height(50 + this.safeTop)
    .padding({ top: this.safeTop })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }

  @Builder
  StatusSection() {
    if (this.orderInfo !== null) {
      Column() {
        Text(this.orderInfo.statusText)
          .fontSize(18)
          .fontColor('#E53935')
          .fontWeight(FontWeight.Medium)
      
      // 订单时间线
      Column() {
        if (this.orderInfo.status === 'PENDING_PAYMENT') {
          this.TimelineItem('订单已创建', this.formatTime(this.orderInfo.createdAt), true)
        } else if (this.orderInfo.status === 'CANCELLED') {
          this.TimelineItem('订单已取消', '', true)
          this.TimelineItem('订单已创建', this.formatTime(this.orderInfo.createdAt), false)
        } else {
          if (this.orderInfo.status === 'COMPLETED') {
            this.TimelineItem('订单已完成', this.formatTime(this.orderInfo.completedTime || ''), true)
            this.TimelineItem('确认收货', '', false)
            this.TimelineItem('商品已发货', this.formatTime(this.orderInfo.shipmentTime || ''), false)
            this.TimelineItem('付款成功', this.formatTime(this.orderInfo.paymentTime || ''), false)
          } else if (this.orderInfo.status === 'PENDING_RECEIPT') {
            this.TimelineItem('商品已发货', this.formatTime(this.orderInfo.shipmentTime || ''), true)
            this.TimelineItem('付款成功', this.formatTime(this.orderInfo.paymentTime || ''), false)
          } else if (this.orderInfo.status === 'PENDING_SHIPMENT') {
            this.TimelineItem('付款成功', this.formatTime(this.orderInfo.paymentTime || ''), true)
          }
          this.TimelineItem('订单已创建', this.formatTime(this.orderInfo.createdAt), false)
        }
      }
      .padding({ top: 20 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .margin({ bottom: 8 })
    }
  }

  @Builder
  TimelineItem(title: string, time: string, isActive: boolean) {
    Row() {
      Column() {
        Circle({ width: 8, height: 8 })
          .fill(isActive ? '#E53935' : '#CCCCCC')
        
        if (time !== '') {
          Divider()
            .width(1)
            .height(30)
            .color('#EEEEEE')
            .margin({ top: 4 })
        }
      }
      .width(8)
      
      Column() {
        Text(title)
          .fontSize(13)
          .fontColor(isActive ? '#333333' : '#999999')
          .fontWeight(isActive ? FontWeight.Medium : FontWeight.Normal)
        
        if (time !== '') {
          Text(time)
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
      }
      .layoutWeight(1)
      .padding({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  AddressSection() {
    if (this.orderInfo !== null) {
      Column() {
        Row() {
        Column() {
          Row() {
            Text(this.orderInfo.receiverName)
              .fontSize(15)
              .fontColor('#333333')
              .fontWeight(FontWeight.Medium)
            
            Text(this.orderInfo.receiverPhone)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ left: 16 })
          }
          
          Text(this.orderInfo.receiverAddress)
            .fontSize(13)
            .fontColor('#666666')
            .margin({ top: 8 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        
        Text('📍')
          .fontSize(24)
          .margin({ left: 12 })
      }
      .width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .margin({ bottom: 8 })
    }
  }

  @Builder
  GoodsSection() {
    if (this.orderInfo !== null) {
      Column() {
        Text('商品信息')
          .fontSize(15)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .padding(12)
        
        Divider().color('#EEEEEE')
        
        ForEach(this.orderInfo.items, (item: OrderItem) => {
          Row() {
            ImageKnifeView({
            loadSrc: item.goodsImage,
            objectFit: ImageFit.Cover,
            borderOption: { radius: 4 }
          })
            .width(70)
            .height(70)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/detail/detail',
                params: { id: item.goodsId }
              })
            })
          
          Column() {
            Text(item.goodsName)
              .fontSize(14)
              .fontColor('#333333')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            
            Text(`${item.color} ${item.size}`)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 6 })
            
            Row() {
              Text(`￥${item.price}`)
                .fontSize(15)
                .fontColor('#E53935')
                .fontWeight(FontWeight.Medium)
              
              Blank()
              
              Text(`x${item.quantity}`)
                .fontSize(13)
                .fontColor('#666666')
            }
            .width('100%')
            .margin({ top: 6 })
          }
          .layoutWeight(1)
          .padding({ left: 12 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
          .padding(12)
          
          Divider().color('#F5F5F5')
        })
        
        Row() {
          Text('合计')
          .fontSize(14)
          .fontColor('#333333')
        
        Blank()
        
        Text(`￥${this.orderInfo.totalAmount}`)
          .fontSize(16)
          .fontColor('#E53935')
          .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FAFAFA')
      }
      .width('100%')
      .backgroundColor(Color.White)
      .margin({ bottom: 8 })
    }
  }

  @Builder
  InfoSection() {
    if (this.orderInfo !== null) {
      Column() {
        Text('订单信息')
          .fontSize(15)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .padding(12)
      
      Divider().color('#EEEEEE')
      
      this.InfoRow('订单号', this.orderInfo.orderNo)
      this.InfoRow('创建时间', this.formatTime(this.orderInfo.createdAt))
      
      if (this.orderInfo.paymentTime) {
        this.InfoRow('支付时间', this.formatTime(this.orderInfo.paymentTime))
      }
      
      if (this.orderInfo.shipmentTime) {
        this.InfoRow('发货时间', this.formatTime(this.orderInfo.shipmentTime))
      }
      
      if (this.orderInfo.completedTime) {
        this.InfoRow('完成时间', this.formatTime(this.orderInfo.completedTime))
      }
      
      if (this.orderInfo.remark) {
        this.InfoRow('备注', this.orderInfo.remark)
      }
    }
    .width('100%')
    .backgroundColor(Color.White)
    .margin({ bottom: 8 })
    }
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#999999')
        .width(80)
      
      Text(value)
        .fontSize(13)
        .fontColor('#333333')
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
  }

  @Builder
  ActionBar() {
    if (this.orderInfo !== null) {
      Row() {
        Text(`￥${this.orderInfo.totalAmount}`)
          .fontSize(16)
          .fontColor('#E53935')
          .fontWeight(FontWeight.Bold)
        
        Blank()
      
      if (this.orderInfo.status === 'PENDING_PAYMENT') {
        Button('取消订单')
          .fontSize(14)
          .height(38)
          .backgroundColor(Color.White)
          .fontColor('#666666')
          .border({ width: 1, color: '#DDDDDD', radius: 19 })
          .padding({ left: 20, right: 20 })
          .margin({ left: 8 })
          .onClick(() => this.handleCancelOrder())
        
        Button('立即支付')
          .fontSize(14)
          .height(38)
          .backgroundColor('#E53935')
          .fontColor(Color.White)
          .border({ radius: 19 })
          .padding({ left: 20, right: 20 })
          .margin({ left: 8 })
          .onClick(() => this.handlePayOrder())
      } else if (this.orderInfo.status === 'PENDING_RECEIPT') {
        Button('确认收货')
          .fontSize(14)
          .height(38)
          .backgroundColor('#E53935')
          .fontColor(Color.White)
          .border({ radius: 19 })
          .padding({ left: 20, right: 20 })
          .margin({ left: 8 })
          .onClick(() => this.handleConfirmOrder())
      } else if (this.orderInfo.status === 'COMPLETED' || this.orderInfo.status === 'CANCELLED') {
        Button('删除订单')
          .fontSize(14)
          .height(38)
          .backgroundColor(Color.White)
          .fontColor('#666666')
          .border({ width: 1, color: '#DDDDDD', radius: 19 })
          .padding({ left: 20, right: 20 })
          .margin({ left: 8 })
          .onClick(() => this.handleDeleteOrder())
      }
      }
      .width('100%')
      .height(60 + this.safeBottom)
      .padding({ left: 16, right: 16, bottom: this.safeBottom, top: 10 })
      .backgroundColor(Color.White)
      .shadow({ radius: 8, color: '#10000000', offsetY: -2 })
      .zIndex(999)
    }
    }
  private loadOrderDetail() {
    this.isLoading = true
    queryOrderDetail(this.userId, this.orderId).then(result => {
      this.orderInfo = result
    }).catch(() => {
      ToastUtil.showToast('加载订单详情失败')
    }).finally(() => {
      this.isLoading = false
    })
  }

  private handleCancelOrder() {
    cancelOrder(this.userId, this.orderId).then(() => {
      ToastUtil.showToast('订单已取消')
      this.loadOrderDetail()
    }).catch(() => {
      ToastUtil.showToast('取消失败')
    })
  }

  private handlePayOrder() {
    payOrder(this.userId, this.orderId).then(() => {
      ToastUtil.showToast('支付成功')
      this.loadOrderDetail()
    }).catch(() => {
      ToastUtil.showToast('支付失败')
    })
  }

  private handleConfirmOrder() {
    confirmOrder(this.userId, this.orderId).then(() => {
      ToastUtil.showToast('确认收货成功')
      this.loadOrderDetail()
    }).catch(() => {
      ToastUtil.showToast('操作失败')
    })
  }

  private handleDeleteOrder() {
    deleteOrder(this.userId, this.orderId).then(() => {
      ToastUtil.showToast('订单已删除')
      router.back()
    }).catch(() => {
      ToastUtil.showToast('删除失败')
    })
  }

  private formatTime(time: string): string {
    if (!time) return ''
    return time.replace('T', ' ').substring(0, 19)
  }
}
