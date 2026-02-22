import router from '@ohos.router'
import { StyleConstants } from '@ohos/common'
import { ImageKnifeView } from '@ohos/common'
import { AppUtil, ToastUtil } from '@pura/harmony-utils'
import {
  queryOrderList,
  cancelOrder,
  payOrder,
  confirmOrder,
  deleteOrder,
  OrderInfo,
  OrderItem,
  QueryOrderListParams
} from '../../service/orderService'

// Tab项接口
interface TabItem {
  key: string
  label: string
}

@Entry
@Component
export struct OrderList {
  @State orderList: OrderInfo[] = []
  @State currentTab: string = 'ALL'
  @State isLoading: boolean = false
  @State userId: string = 'guest'
  @State currentPage: number = 0
  @State hasMore: boolean = true

  @StorageProp('safeTop') safeTop: number = 0
  @StorageProp('safeBottom') safeBottom: number = 0

  private scroller: Scroller = new Scroller()

  private tabs: TabItem[] = [
    { key: 'ALL', label: '全部' } as TabItem,
    { key: 'PENDING_PAYMENT', label: '待付款' } as TabItem,
    { key: 'PENDING_SHIPMENT', label: '待发货' } as TabItem,
    { key: 'PENDING_RECEIPT', label: '待收货' } as TabItem,
    { key: 'COMPLETED', label: '已完成' } as TabItem
  ]

  aboutToAppear() {
    const storedUser = AppStorage.Get<string>('userAccount')
    this.userId = storedUser ? storedUser : 'guest'
    
    // 从路由参数获取初始tab
    const params = router.getParams() as Record<string, string>
    if (params?.status) {
      this.currentTab = params.status
    }
    
    this.loadOrders()
  }

  build() {
    Column() {
      this.Header()
      this.TabBar()
      
      if (this.isLoading && this.orderList.length === 0) {
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.orderList.length === 0) {
        this.EmptyView()
      } else {
        Scroll(this.scroller) {
          Column() {
            ForEach(this.orderList, (order: OrderInfo) => {
              this.OrderCard(order)
            }, (order: OrderInfo) => order.id.toString())
            
            if (this.hasMore) {
              Text('加载更多...')
                .fontSize(12)
                .fontColor('#999999')
                .padding(12)
                .width('100%')
                .textAlign(TextAlign.Center)
            } else if (this.orderList.length > 0) {
              Text('没有更多了')
                .fontSize(12)
                .fontColor('#CCCCCC')
                .padding(12)
                .width('100%')
                .textAlign(TextAlign.Center)
            }
          }
          .padding({ bottom: this.safeBottom + 12 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .backgroundColor('#F5F5F5')
  }

  @Builder
  Header() {
    Row() {
      Text('←')
        .fontSize(20)
        .fontColor(Color.Black)
        .onClick(() => router.back())
        .padding({ left: 12, right: 12 })
      
      Text('我的订单')
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
  TabBar() {
    Row() {
      ForEach(this.tabs, (tab: TabItem) => {
        Column() {
          Text(tab.label)
            .fontSize(14)
            .fontColor(this.currentTab === tab.key ? '#E53935' : '#666666')
            .fontWeight(this.currentTab === tab.key ? FontWeight.Medium : FontWeight.Normal)
          
          if (this.currentTab === tab.key) {
            Divider()
              .width(20)
              .height(2)
              .color('#E53935')
              .margin({ top: 4 })
          }
        }
        .layoutWeight(1)
        .padding({ top: 12, bottom: 8 })
        .onClick(() => {
          if (this.currentTab !== tab.key) {
            this.currentTab = tab.key
            this.currentPage = 0
            this.orderList = []
            this.hasMore = true
            this.loadOrders()
          }
        })
      })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .margin({ bottom: 8 })
  }

  @Builder
  OrderCard(order: OrderInfo) {
    Column() {
      // 订单头部
      Row() {
        Text(`订单号: ${order.orderNo}`)
          .fontSize(12)
          .fontColor('#666666')
        
        Blank()
        
        Text(order.statusText)
          .fontSize(12)
          .fontColor('#E53935')
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FAFAFA')

      // 商品列表
      ForEach(order.items, (item: OrderItem) => {
        Row() {
          ImageKnifeView({
            loadSrc: item.goodsImage,
            objectFit: ImageFit.Cover,
            borderOption: { radius: 4 }
          })
            .width(60)
            .height(60)
          
          Column() {
            Text(item.goodsName)
              .fontSize(13)
              .fontColor('#333333')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            
            Text(`${item.color} ${item.size}`)
              .fontSize(11)
              .fontColor('#999999')
              .margin({ top: 4 })
            
            Row() {
              Text(`￥${item.price}`)
                .fontSize(13)
                .fontColor('#E53935')
                .fontWeight(FontWeight.Medium)
              
              Blank()
              
              Text(`x${item.quantity}`)
                .fontSize(12)
                .fontColor('#666666')
            }
            .width('100%')
            .margin({ top: 4 })
          }
          .layoutWeight(1)
          .padding({ left: 10 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(12)
      })

      Divider()
        .color('#EEEEEE')

      // 订单底部
      Row() {
        Text(`合计: ￥${order.totalAmount}`)
          .fontSize(14)
          .fontColor('#E53935')
          .fontWeight(FontWeight.Medium)
        
        Blank()
        
        Row() {
          // 根据订单状态显示不同按钮
          if (order.status === 'PENDING_PAYMENT') {
            Button('取消订单')
              .fontSize(12)
              .height(28)
              .backgroundColor(Color.White)
              .fontColor('#666666')
              .border({ width: 1, color: '#DDDDDD', radius: 14 })
              .margin({ left: 8 })
              .onClick(() => this.handleCancelOrder(order))
            
            Button('立即支付')
              .fontSize(12)
              .height(28)
              .backgroundColor('#E53935')
              .fontColor(Color.White)
              .border({ radius: 14 })
              .margin({ left: 8 })
              .onClick(() => this.handlePayOrder(order))
          } else if (order.status === 'PENDING_RECEIPT') {
            Button('确认收货')
              .fontSize(12)
              .height(28)
              .backgroundColor('#E53935')
              .fontColor(Color.White)
              .border({ radius: 14 })
              .margin({ left: 8 })
              .onClick(() => this.handleConfirmOrder(order))
          } else if (order.status === 'COMPLETED' || order.status === 'CANCELLED') {
            Button('删除订单')
              .fontSize(12)
              .height(28)
              .backgroundColor(Color.White)
              .fontColor('#666666')
              .border({ width: 1, color: '#DDDDDD', radius: 14 })
              .margin({ left: 8 })
              .onClick(() => this.handleDeleteOrder(order))
          }
          
          Button('查看详情')
            .fontSize(12)
            .height(28)
            .backgroundColor(Color.White)
            .fontColor('#666666')
            .border({ width: 1, color: '#DDDDDD', radius: 14 })
            .margin({ left: 8 })
            .onClick(() => this.goToDetail(order))
        }
      }
      .width('100%')
      .padding(12)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ left: 12, right: 12, top: 8 })
  }

  @Builder
  EmptyView() {
    Column() {
      Text('暂无订单')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 50 })
      
      Text('去购物车看看吧')
        .fontSize(12)
        .fontColor('#CCCCCC')
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  private loadOrders() {
    if (this.isLoading) return
    
    this.isLoading = true
    queryOrderList({
      userId: this.userId,
      status: this.currentTab,
      page: this.currentPage,
      size: 10
    } as QueryOrderListParams).then(result => {
      if (this.currentPage === 0) {
        this.orderList = result.orderList
      } else {
        this.orderList = this.orderList.concat(result.orderList)
      }
      this.hasMore = (this.currentPage + 1) < result.totalPages
    }).catch((err: Error) => {
      ToastUtil.showToast('加载订单失败')
    }).finally(() => {
      this.isLoading = false
    })
  }

  private handleCancelOrder(order: OrderInfo) {
    cancelOrder(this.userId, order.id).then(() => {
      ToastUtil.showToast('订单已取消')
      this.currentPage = 0
      this.orderList = []
      this.loadOrders()
    }).catch((err: Error) => {
      ToastUtil.showToast('取消失败')
    })
  }

  private handlePayOrder(order: OrderInfo) {
    payOrder(this.userId, order.id).then(() => {
      ToastUtil.showToast('支付成功')
      this.currentPage = 0
      this.orderList = []
      this.loadOrders()
    }).catch(() => {
      ToastUtil.showToast('支付失败')
    })
  }

  private handleConfirmOrder(order: OrderInfo) {
    confirmOrder(this.userId, order.id).then(() => {
      ToastUtil.showToast('确认收货成功')
      this.currentPage = 0
      this.orderList = []
      this.loadOrders()
    }).catch(() => {
      ToastUtil.showToast('操作失败')
    })
  }

  private handleDeleteOrder(order: OrderInfo) {
    deleteOrder(this.userId, order.id).then(() => {
      ToastUtil.showToast('订单已删除')
      this.orderList = this.orderList.filter(o => o.id !== order.id)
    }).catch(() => {
      ToastUtil.showToast('删除失败')
    })
  }

  private goToDetail(order: OrderInfo) {
    router.pushUrl({
      url: 'pages/order/orderDetail',
      params: {
        orderId: order.id
      }
    })
  }
}
