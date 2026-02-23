import { CommodityList, FloatingBackTop, StepperComponent, StyleConstants } from "@ohos/common"
import { ImageKnifeView } from '@ohos/common'
import { AppUtil, DisplayUtil, ToastUtil, WindowUtil } from "@pura/harmony-utils"
import router from '@ohos.router'
import {
  clearCart,
  GoodsInfo,
  queryCartGoodsList,
  removeCartItem,
  removeCartItems,
  selectAllItems,
  selectStoreItems,
  StoreGoodsInfo,
  updateCartItem
} from '../../service/cartService'

@Component
export struct Cart {
  @State totalInfoHeight: number = 0 //58,0
  @State showBackTop: boolean = false
  @State cartStoreGoodsList: StoreGoodsInfo[] = []
  @State totalAmount: number = 0
  @State selectedCount: number = 0
  @State allSelected: boolean = false
  @StorageProp('userAccount') @Watch('onUserChange') userAccount: string = 'guest'

  @StorageProp('safeBottom') safeBottom: number = 0

  private scrollScroller: Scroller = new Scroller()
  private probablyLikeScroller = new Scroller()

  goodsItemWidth = (DisplayUtil.getWidth() - 30) / 2

  aboutToAppear() {
    this.queryCartGoods()
  }

  onUserChange() {
    // 用户登录状态变化时重新加载购物车
    this.queryCartGoods()
  }

  build() {
    Stack() {
      Column() {
        this.AddressHeader()
        Scroll(this.scrollScroller) {
          Column() {
            if (this.cartStoreGoodsList.length > 0) {
              this.CartGoodsList()
            } else {
              this.EmptyCart()
            }
            this.ProbablyLike()
          }
        }
        .edgeEffect(EdgeEffect.Spring)
        .friction(0.6)
        .scrollBar(BarState.Off)
        .width(StyleConstants.FULL_WIDTH)
        .height(`calc(100% - (${40 + this.totalInfoHeight + this.getUIContext().px2vp(AppUtil.getStatusBarHeight())}vp))`)

        this.TotalInfo()
      }
      .backgroundColor('#F1F1F1')
      .width(StyleConstants.FULL_WIDTH)
      .height(StyleConstants.FULL_HEIGHT)

      this.BackTop()
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
  }

  @Builder
  AddressHeader() {
    Column() {
      Row() {
        Text('购物车')
          .fontColor(Color.Black)
          .fontWeight(FontWeight.Medium)
          .fontSize(StyleConstants.FONT_SIZE_TWENTY)
        Blank()
        Text('清空')
          .fontSize(12)
          .fontColor('#E53935')
          .onClick(() => {
            this.handleClearCart()
          })
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      }
      .height(40)
      .width(StyleConstants.FULL_WIDTH)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Start)
      .padding({left: 12})
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(40 + this.getUIContext().px2vp(AppUtil.getStatusBarHeight()))
    .padding({top: this.getUIContext().px2vp(AppUtil.getStatusBarHeight())})
  }

  @Builder
  StoreInfo(info: StoreGoodsInfo) {
    Row() {
      Column() {
        Image(info.select ? $r('app.media.selector_check_true') : $r('app.media.selector_check_false'))
          .width(18)
          .height(18)
          .onClick(() => {
            const next = !info.select
            this.toggleStoreSelect(info, next)
          })
      }
      .width(45)
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.End)
      .height(StyleConstants.FULL_HEIGHT)

      Image($r('app.media.ic_store'))
        .width(20)
        .height(20)
      Text(info.storeName)
        .fontColor(Color.Black)
        .fontSize(StyleConstants.FONT_SIZE_SIXTEEN)
        .margin({left: 6})
      Image($r('app.media.ic_arrow_right'))
        .width(20)
        .height(20)
    }
    .backgroundColor(Color.White)
    .height(32)
    .alignItems(VerticalAlign.Bottom)
    .margin({left: 10, right: 10})
    .width(`calc(100% - 20vp)`)
    .border({radius: { topLeft: 10, topRight: 10 }})
  }

  @Builder
  CartGoodsList() {
    List() {
      ForEach(this.cartStoreGoodsList, (item: StoreGoodsInfo, parentIndex: number) => {
        ListItemGroup({header: this.StoreInfo(item)}) {
          ForEach(item.goodsList, (goodsItem: GoodsInfo, index: number) => {
            ListItem() {
              Row() {
                Column() {
                  Image(goodsItem.select ? $r('app.media.selector_check_true') : $r('app.media.selector_check_false'))
                    .width(18)
                    .height(18)
                    .onClick(() => {
                      const next = !goodsItem.select
                      this.toggleItemSelect(item, goodsItem, next)
                    })
                }
                .width(45)
                .alignItems(HorizontalAlign.Center)
                .justifyContent(FlexAlign.Center)
                .height(StyleConstants.FULL_HEIGHT)

                Row() {
                  ImageKnifeView({
                    loadSrc: goodsItem.imgUrl,
                    objectFit: ImageFit.Fill,
                    borderOption: {radius: 8}
                  })
                    .height(80)
                    .width(80)
                    .margin({ right: 10 })

                  Column() {
                    Text(goodsItem.description)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .fontColor('#777677')
                      .fontSize(StyleConstants.FONT_SIZE_FOURTEEN)

                    Text(`${goodsItem.color}，${goodsItem.size}，选服务`)
                      .backgroundColor('#F1F1F1')
                      .fontColor('#949596')
                      .fontSize(StyleConstants.FONT_SIZE_TWELVE)
                      .padding({left: 5, right: 5, top: 2, bottom: 2})
                      .border({radius: 12 })
                      .margin({top: 6})

                    Row() {
                      Text(`￥${goodsItem.price}`)
                        .fontWeight(FontWeight.Medium)
                        .fontColor($r('app.color.dot_active_color'))
                        .fontSize(StyleConstants.FONT_SIZE_EIGHTEEN)

                      StepperComponent({
                        initialValue: goodsItem.num,
                        min: 1,
                        max: 9999,
                        step: 1,
                        onChange: (val: number) => {
                          this.updateItemNum(goodsItem, val)
                        }
                      })
                    }
                    .width(StyleConstants.FULL_WIDTH)
                    .justifyContent(FlexAlign.SpaceBetween)
                    .margin({top: 6})

                    Row() {
                      this.StatusChip('暂存', goodsItem.saved, () => {
                        this.toggleItemFlag(goodsItem, 'saved')
                      })
                      this.StatusChip('收藏', goodsItem.favorite, () => {
                        this.toggleItemFlag(goodsItem, 'favorite')
                      })
                      this.StatusChip('对比', goodsItem.compare, () => {
                        this.toggleItemFlag(goodsItem, 'compare')
                      })
                      Blank()
                      Text('删除')
                        .fontSize(11)
                        .fontColor('#E53935')
                        .padding({ right: 6 })
                        .onClick(() => {
                          this.removeSingleItem(goodsItem)
                        })
                    }
                    .width(StyleConstants.FULL_WIDTH)
                    .margin({ top: 8 })
                    .justifyContent(FlexAlign.Start)
                  }
                  .width(`calc(100% - 125vp)`)
                  .padding({left: 6, right: 6})
                  .alignItems(HorizontalAlign.Start)
                  .justifyContent(FlexAlign.Start)
                }
                .layoutWeight(1)
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/detail/detail',
                    params: {
                      goodsId: goodsItem.code
                    }
                  })
                })
              }
              .height(108)
              .width(StyleConstants.FULL_WIDTH)
            }
            .backgroundColor(Color.White)
            .width(`calc(100% - 20vp)`)
            .border({radius: { bottomLeft: index + 1 == item.goodsList.length ? 10 : 0, bottomRight: index + 1 == item.goodsList.length ? 10 : 0 }})
            .margin({left: 10, right: 10, bottom: index + 1 != item.goodsList.length ? 0 : (parentIndex + 1 !=  this.cartStoreGoodsList.length ? 12 : 0)})

          },(goodsItem: GoodsInfo) => goodsItem.id.toString())
        }
        .width(StyleConstants.FULL_WIDTH)
      },(item: StoreGoodsInfo) => item.storeCode)
    }
    .width(StyleConstants.FULL_WIDTH)
  }

  @Builder
  ProbablyLike() {
    Column() {
      Image($r('app.media.probably_like'))
        .objectFit(ImageFit.Fill)
        .height(42)
        .width(StyleConstants.FULL_WIDTH)

      CommodityList({
        categoryCode: "probablyLike",
        scrollController: this.probablyLikeScroller,
        itemWidth: this.goodsItemWidth,
        onScrollIndexCall: (first => {
          this.showBackTop = first > 5
        })
      })
    }
  }

  @Builder
  TotalInfo() {
    Row() {
      Row() {
        Image(this.allSelected ? $r('app.media.selector_check_true') : $r('app.media.selector_check_false'))
          .width(18)
          .height(18)
        Text('全选')
          .fontSize(12)
          .fontColor('#333333')
          .margin({ left: 6 })
      }
      .width(80)
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.toggleSelectAll(!this.allSelected)
      })

      Column() {
        Text(`合计 ￥${this.totalAmount.toFixed(2)}`)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#E53935')
        Text(`已选${this.selectedCount}件`)
          .fontSize(11)
          .fontColor('#999999')
          .margin({ top: 2 })
      }
      .layoutWeight(1)

      Text('删除')
        .fontSize(12)
        .fontColor('#666666')
        .margin({ right: 10 })
        .onClick(() => {
          this.removeSelectedItems()
        })

      Button() {
        Text(`去结算(${this.selectedCount})`)
          .fontSize(12)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .height(36)
      .backgroundColor(this.selectedCount === 0 ? '#CCCCCC' : '#E53935')
      .borderRadius(18)
      .padding({ left: 12, right: 12 })
      .enabled(this.selectedCount > 0)
      .onClick(() => {
        if (this.selectedCount > 0) {
          router.pushUrl({
            url: 'pages/order/settlement'
          })
        } else {
          ToastUtil.showToast('请选择要购买的商品')
        }
      })
    }
    .height(50 + this.safeBottom)
    .width(StyleConstants.FULL_WIDTH)
    .padding({ left: 12, right: 12, bottom: this.safeBottom })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
    .border({ width: { bottom: 1, top: 1 }, color: '#EAEAEA' })
  }

  @Builder
  StatusChip(text: string, active: boolean, onClick: () => void) {
    Text(text)
      .fontSize(10)
      .fontColor(active ? Color.White : '#666666')
      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      .borderRadius(10)
      .backgroundColor(active ? '#E53935' : '#F1F1F1')
      .margin({ right: 6 })
      .onClick(onClick)
  }

  @Builder
  EmptyCart() {
    Column() {
      Text('购物车空空如也')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 30 })
      Text('去挑点喜欢的吧')
        .fontSize(12)
        .fontColor('#BBBBBB')
        .margin({ top: 6, bottom: 20 })
    }
    .width(StyleConstants.FULL_WIDTH)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  BackTop() {
    FloatingBackTop({
      location: ({ x: '85%', y: '80%' }),
      display: (this.showBackTop ? Visibility.Visible : Visibility.None),
      onClickFun: (() => {
        this.probablyLikeScroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 200, curve: Curve.Friction  } })
        this.scrollScroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 400, curve: Curve.Friction  } })
      })
    })
  }

  queryCartGoods() {
    queryCartGoodsList(this.userAccount).then(list => {
      this.cartStoreGoodsList = list || []
      this.updateTotals()
    })
  }

  private handleClearCart() {
    clearCart(this.userAccount).then(() => {
      this.cartStoreGoodsList = []
      this.updateTotals()
      ToastUtil.showToast('购物车已清空')
    })
  }

  private updateTotals() {
    let total = 0
    let count = 0
    let allSelected = true
    let hasItem = false
    this.cartStoreGoodsList.forEach(store => {
      let storeSelected = true
      store.goodsList.forEach(item => {
        hasItem = true
        if (item.select) {
          count += item.num
          const price = Number(item.price || 0)
          total += price * item.num
        } else {
          allSelected = false
          storeSelected = false
        }
      })
      store.select = store.goodsList.length > 0 && storeSelected
      if (!store.select) {
        allSelected = false
      }
    })
    if (!hasItem) {
      allSelected = false
    }
    this.totalAmount = total
    this.selectedCount = count
    this.allSelected = allSelected
  }

  private toggleItemSelect(store: StoreGoodsInfo, item: GoodsInfo, selected: boolean) {
    item.select = selected
    updateCartItem({ userId: this.userAccount, itemId: item.id, selected: selected }).catch(() => {
      item.select = !selected
    }).finally(() => {
      this.updateTotals()
    })
  }

  private toggleStoreSelect(store: StoreGoodsInfo, selected: boolean) {
    store.select = selected
    store.goodsList.forEach(item => {
      item.select = selected
    })
    selectStoreItems(this.userAccount, store.storeCode, selected).catch(() => {
      store.select = !selected
      store.goodsList.forEach(item => {
        item.select = !selected
      })
    }).finally(() => {
      this.updateTotals()
    })
  }

  private toggleSelectAll(selected: boolean) {
    this.allSelected = selected
    this.cartStoreGoodsList.forEach(store => {
      store.select = selected
      store.goodsList.forEach(item => {
        item.select = selected
      })
    })
    selectAllItems(this.userAccount, selected).catch(() => {
      this.allSelected = !selected
      this.cartStoreGoodsList.forEach(store => {
        store.select = !selected
        store.goodsList.forEach(item => {
          item.select = !selected
        })
      })
    }).finally(() => {
      this.updateTotals()
    })
  }

  private updateItemNum(item: GoodsInfo, num: number) {
    item.num = num
    updateCartItem({ userId: this.userAccount, itemId: item.id, num: num }).finally(() => {
      this.updateTotals()
    })
  }

  private toggleItemFlag(item: GoodsInfo, flag: 'saved' | 'favorite' | 'compare') {
    if (flag === 'saved') {
      item.saved = !item.saved
      updateCartItem({ userId: this.userAccount, itemId: item.id, saved: item.saved })
      return
    }
    if (flag === 'favorite') {
      item.favorite = !item.favorite
      updateCartItem({ userId: this.userAccount, itemId: item.id, favorite: item.favorite })
      return
    }
    item.compare = !item.compare
    updateCartItem({ userId: this.userAccount, itemId: item.id, compare: item.compare })
  }

  private removeSingleItem(item: GoodsInfo) {
    removeCartItem(this.userAccount, item.id).then(() => {
      this.cartStoreGoodsList.forEach(store => {
        store.goodsList = store.goodsList.filter(g => g.id !== item.id)
      })
      this.cartStoreGoodsList = this.cartStoreGoodsList.filter(store => store.goodsList.length > 0)
      this.updateTotals()
    })
  }

  private removeSelectedItems() {
    const ids: number[] = []
    this.cartStoreGoodsList.forEach(store => {
      store.goodsList.forEach(item => {
        if (item.select) {
          ids.push(item.id)
        }
      })
    })
    if (ids.length === 0) {
      ToastUtil.showToast('请选择要删除的商品')
      return
    }
    removeCartItems(this.userAccount, ids).then(() => {
      this.cartStoreGoodsList.forEach(store => {
        store.goodsList = store.goodsList.filter(item => !item.select)
      })
      this.cartStoreGoodsList = this.cartStoreGoodsList.filter(store => store.goodsList.length > 0)
      this.updateTotals()
    })
  }

}
