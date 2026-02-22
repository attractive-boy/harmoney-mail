import router from '@ohos.router'
import { StyleConstants } from '@ohos/common'
import { ImageKnifeView } from '@ohos/common'
import { ToastUtil } from '@pura/harmony-utils'
import { addToCart } from '../../service/cartService'
import { queryGoodsDetail, queryStoreGoodsList, GoodsInfo } from '../../service/detailService'

@Entry
@Component
export struct Detail {
  @StorageProp('safeTop') safeTop: number = 0
  @StorageProp('safeBottom') safeBottom: number = 0

  @State goodsId: string = ''
  @State goods: GoodsInfo | null = null
  @State storeGoods: GoodsInfo[] = []
  @State isLoading: boolean = true
  @State loadError: string = ''
  @State currentImageIndex: number = 0

  aboutToAppear() {
    const params = router.getParams() as Record<string, string | number>
    const rawId = params?.goodsId
    this.goodsId = rawId === undefined || rawId === null ? '' : rawId.toString()
    if (this.goodsId) {
      this.loadDetail()
      this.loadStoreGoods()
    } else {
      this.isLoading = false
      this.loadError = '未获取到商品信息'
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.Header()
        Scroll() {
          Column() {
            if (this.isLoading) {
              Text('加载中...')
                .fontSize(14)
                .fontColor('#666666')
                .padding(12)
            } else if (this.loadError) {
              Text(this.loadError)
                .fontSize(14)
                .fontColor('#666666')
                .padding(12)
            } else if (this.goods) {
              this.CarouselSection()
              this.PriceSection()
              this.PromoTabsSection()
              this.TitleDescSection()
              this.SpecificationSection()
              this.DeliverySection()
              this.ServiceSection()
              this.QuestionsSection()
              this.StoreSection()
              this.RecommendSection()
            }
          }
          .padding({ bottom: 70 + this.safeBottom })
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(StyleConstants.FULL_HEIGHT)
      .backgroundColor('#F5F5F5')

      this.ActionBar()
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
  }

  @Builder
  Header() {
    Row() {
      Text('←')
        .fontSize(20)
        .fontColor(Color.White)
        .onClick(() => router.back())
      Blank()
      Text('商品详情')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
      Blank()
      Text('分享')
        .fontSize(12)
        .fontColor(Color.White)
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(48 + this.safeTop)
    .padding({ left: 12, right: 12, top: this.safeTop })
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#E53935')
  }

  @Builder
  CarouselSection() {
    Column() {
      Stack() {
        ImageKnifeView({
          loadSrc: this.goods?.imgUrl || '',
          objectFit: ImageFit.Fill
        })
        .width(StyleConstants.FULL_WIDTH)
        .height(280)

        // 顶部标签
        Column() {
          Row() {
            Row() {
              Text('官方验证')
                .fontSize(9)
                .fontColor(Color.White)
                .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                .borderRadius(8)
                .backgroundColor('#FF6A00')
            }
            .margin({ right: 4 })
          }
          Blank()
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 10, top: 10 })
        .width(StyleConstants.FULL_WIDTH)
        .height(280)

        // 右下角计数
        Column() {
          Blank()
          Text(`1/5`)
            .fontSize(10)
            .fontColor(Color.White)
            .padding({ left: 5, right: 5, top: 2, bottom: 2 })
            .backgroundColor('#00000044')
            .borderRadius(10)
            .margin({ right: 10, bottom: 10 })
        }
        .alignItems(HorizontalAlign.End)
        .width(StyleConstants.FULL_WIDTH)
        .height(280)
      }
    }
    .backgroundColor(Color.White)
  }

  @Builder
  PriceSection() {
    if (!this.goods?.price || this.goods.price === '' || this.goods.price === '0') {
      // type=2 的推广类商品，没有价格
      Column() {
        Row() {
          Column() {
            Text('活动商品')
              .fontSize(18)
              .fontColor('#E53935')
              .fontWeight(FontWeight.Bold)
            Text('点击查看活动详情')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          Blank()
          Button('进入活动')
            .fontSize(12)
            .fontColor(Color.White)
            .backgroundColor('#E53935')
            .height(32)
            .padding({ left: 16, right: 16 })
        }
        .padding(12)
        .width(StyleConstants.FULL_WIDTH)
        .alignItems(VerticalAlign.Center)
      }
      .backgroundColor(Color.White)
    } else {
      Column() {
      // 大价格区域
      Column() {
        Row() {
          Column() {
            Row() {
              Text('￥')
                .fontSize(14)
                .fontColor('#E53935')
                .fontWeight(FontWeight.Bold)
              Text((this.goods?.price || '0').split('.')[0])
                .fontSize(32)
                .fontColor('#E53935')
                .fontWeight(FontWeight.Bold)
              if ((this.goods?.price || '').includes('.')) {
                Text('.' + (this.goods?.price || '0').split('.')[1])
                  .fontSize(18)
                  .fontColor('#E53935')
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 4 })
              }
            }
            .alignItems(VerticalAlign.Center)

            Text('限购3件/账户  46人已购')
              .fontSize(11)
              .fontColor('#999999')
              .margin({ top: 4 })
          }
          Blank()
        }
        .padding(12)
        .width(StyleConstants.FULL_WIDTH)
        .alignItems(VerticalAlign.Center)
      }
      .backgroundColor(Color.White)

      // 促销信息
      Row() {
        Text('🎁')
          .fontSize(14)
          .margin({ right: 6 })
        Text('在线购买 立返购物奖励  >')
          .fontSize(11)
          .fontColor(Color.White)
      }
      .width('100%')
      .height(36)
      .backgroundColor('#4CAF50')
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .margin({ top: 1 })

      // 其他促销标签
      Row() {
        this.PromoBadge('限时优惠')
        this.PromoBadge('门店优惠')
        this.PromoBadge('假一赔三')
      }
      .padding(10)
      .width(StyleConstants.FULL_WIDTH)
      .backgroundColor(Color.White)
      .margin({ top: 1 })
      }
    }
  }

  @Builder
  PromoBadge(text: string) {
    Row() {
      Text(text)
        .fontSize(10)
        .fontColor('#E53935')
    }
    .padding({ left: 6, right: 6, top: 3, bottom: 3 })
    .borderRadius(10)
    .border({ color: '#E53935', width: 0.5 })
    .margin({ right: 6 })
  }


  @Builder
  TitleDescSection() {
    Column() {
      Row() {
        Text(this.goods?.description || 'iPhone 15 Pro')
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .lineHeight(20)
      }
      .alignItems(VerticalAlign.Center)
      .width(StyleConstants.FULL_WIDTH)

      Row() {
        if (this.goods?.tag) {
          this.DescTag(this.goods.tag)
        }
        if (this.goods?.des1) {
          this.DescTag(this.goods.des1)
        }
        if (this.goods?.des2) {
          this.DescTag(this.goods.des2)
        }
      }
      .margin({ top: 8 })
    }
    .padding(12)
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  @Builder
  DescTag(text: string) {
    Text(text)
      .fontSize(10)
      .fontColor(Color.White)
      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      .borderRadius(10)
      .backgroundColor('#E53935')
      .margin({ right: 6 })
  }

  @Builder
  PromoTabsSection() {
    Flex({ wrap: FlexWrap.Wrap }) {
      this.PromoTab('精选', true)
      this.PromoTab('销量最高', false)
      this.PromoTab('评价最优', false)
      this.PromoTab('新品上架', false)
    }
    .padding(12)
    .width(StyleConstants.FULL_WIDTH)
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  @Builder
  PromoTab(text: string, active: boolean) {
    Text(text)
      .fontSize(11)
      .fontColor(active ? Color.White : '#666666')
      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
      .borderRadius(14)
      .backgroundColor(active ? '#E53935' : '#F0F0F0')
  }

  @Builder
  SpecificationSection() {
    Column() {
      Text('商品信息')
        .fontSize(14)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .padding({ left: 12, top: 12, bottom: 8 })

      this.SpecRow('品牌', '苹果')
      this.SpecRow('型号', 'iPhone 15')
      this.SpecRow('成色', '99新')
      this.SpecRow('配置', this.goods?.description || '未知')
      this.SpecRow('售后', '12个月保修')
    }
    .padding({ bottom: 12 })
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  @Builder
  SpecRow(label: string, value: string) {
    Column() {
      Row() {
        Text(label)
          .fontSize(12)
          .fontColor('#999999')
          .width('30%')
        Text(value)
          .fontSize(12)
          .fontColor('#333333')
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      
      Divider()
        .color('#F0F0F0')
    }
    .width('100%')
  }

  @Builder
  DeliverySection() {
    Column() {
      Text('配送信息')
        .fontSize(14)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .padding({ left: 12, top: 12, bottom: 8 })

      this.DeliveryRow('📍', '送至', '北京 朝阳区')
      this.DeliveryRow('🚚', '运费', this.goods?.shipping || '包邮')
    }
    .padding({ bottom: 12 })
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  @Builder
  DeliveryRow(icon: string, label: string, value: string) {
    Column() {
      Row() {
        Text(icon)
          .fontSize(12)
          .margin({ right: 4 })
        Text(label)
          .fontSize(12)
          .fontColor('#999999')
          .width('20%')
        Text(value)
          .fontSize(12)
          .fontColor('#333333')
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      
      Divider()
        .color('#F0F0F0')
    }
    .width('100%')
  }

  @Builder
  ServiceSection() {
    Column() {
      Text('服务保障')
        .fontSize(14)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .padding({ left: 12, top: 12, bottom: 8 })

      Flex({ wrap: FlexWrap.Wrap }) {
        this.ServiceTag('✓ 7天无理由退货')
        this.ServiceTag('✓ 极速退款')
        this.ServiceTag('✓ 官方认证')
        this.ServiceTag('✓ 假一赔三')
        this.ServiceTag('✓ 正品保证')
        this.ServiceTag('✓ 售后支持')
      }
      .padding({ left: 12, right: 12, bottom: 12 })
    }
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  @Builder
  ServiceTag(text: string) {
    Text(text)
      .fontSize(11)
      .fontColor('#666666')
      .padding({ left: 8, right: 8, top: 5, bottom: 5 })
      .borderRadius(4)
      .backgroundColor('#F5F5F5')
  }


  @Builder
  QuestionsSection() {
    Column() {
      Row() {
        Text('问答')
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('查看全部 >')
          .fontSize(11)
          .fontColor('#E53935')
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 8 })

      Column() {
        Text('已买的朋友，感觉怎么样？')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ bottom: 6 })
        Text('续航能力怎么样？')
          .fontSize(12)
          .fontColor('#666666')
      }
      .padding({ left: 12, right: 12, bottom: 12 })
      .width('100%')
    }
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  @Builder
  StoreSection() {
    Column() {
      Row() {
        Row() {
          Text(this.goods?.storeLevel || '钻石级')
            .fontSize(9)
            .fontColor(Color.White)
            .padding({ left: 5, right: 5, top: 1, bottom: 1 })
            .borderRadius(3)
            .backgroundColor('#FFB81C')
            .margin({ right: 6 })

          Text(this.goods?.storeName || '爱回收严选手机旗舰店')
            .fontSize(13)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)

        Row() {
          Text('进店')
            .fontSize(11)
            .fontColor('#E53935')
        }
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(4)
        .border({ color: '#E53935', width: 0.5 })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 12, bottom: 8 })
      .alignItems(VerticalAlign.Center)

      Row() {
        this.StoreRating('评分', (this.goods?.storeRating || 4.8).toFixed(1))
        this.StoreRating('物流', '8.7')
        this.StoreRating('售后', '9.6')
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 8 })

      Row() {
        this.StoreTag('✓ 官方认证')
        this.StoreTag('✓ 7天退货')
        this.StoreTag('✓ ' + (this.goods?.shipping || '包邮'))
      }
      .width('100%')
      .padding({ left: 12, right: 12, bottom: 12 })
    }
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  @Builder
  StoreTag(text: string) {
    Text(text)
      .fontSize(11)
      .fontColor('#555555')
      .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      .backgroundColor('#F5F5F5')
      .borderRadius(4)
      .margin({ right: 8 })
  }

  @Builder
  StoreRating(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(11)
        .fontColor('#666666')
      Text(value)
        .fontSize(12)
        .fontColor('#333333')
        .margin({ top: 2 })
    }
    .margin({ right: 12 })
  }

  @Builder
  RecommendSection() {
    Column() {
      Text('推荐列表')
        .fontSize(14)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .padding({ left: 12, top: 4, bottom: 4 })
      Grid() {
        ForEach(this.storeGoods, (item: GoodsInfo) => {
          GridItem() {
            Column() {
              ImageKnifeView({
                loadSrc: item.imgUrl,
                objectFit: ImageFit.Fill
              })
              .width('100%')
              .height(140)
              Text(item.description || '')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontSize(12)
                .fontColor('#666666')
                .margin({ top: 8 })
              Text(`￥${item.price || ''}`)
                .fontSize(14)
                .fontColor('#E53935')
                .fontWeight(FontWeight.Medium)
                .margin({ top: 6 })
            }
            .padding(8)
            .backgroundColor(Color.White)
            .borderRadius(6)
          }
        }, (item: GoodsInfo) => item.id.toString())
      }
      .columnsTemplate('1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    }
    .backgroundColor('#F5F5F5')
    .margin({ top: 8 })
  }

  @Builder
  ActionBar() {
    Row() {
      Column() {
        Text('👤')
          .fontSize(16)
        Text('客服')
          .fontSize(10)
          .fontColor('#666666')
          .margin({ top: 2 })
      }
      .width(50)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text('🏪')
          .fontSize(16)
        Text('店铺')
          .fontSize(10)
          .fontColor('#666666')
          .margin({ top: 2 })
      }
      .width(50)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column() {
        Text('♡')
          .fontSize(18)
      }
      .width(50)
      .justifyContent(FlexAlign.Center)

      // 判断是否有价格
      if (!this.goods?.price || this.goods.price === '' || this.goods.price === '0') {
        // 推广类商品，只显示"进入活动"按钮
        Button() {
          Text('进入活动页面')
            .fontSize(14)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
        .height(40)
        .backgroundColor('#E53935')
        .borderRadius(20)
        .layoutWeight(1)
        .margin({ left: 10, right: 10 })
        .onClick(() => {
          ToastUtil.showToast('跳转到活动页面')
        })
      } else {
        // 普通商品，显示加购和立即购买
        Button() {
          Text('加入购物车')
            .fontSize(12)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
        .height(36)
        .backgroundColor('#FF9F2E')
        .borderRadius(4)
        .layoutWeight(1)
        .margin({ left: 6, right: 4 })
        .onClick(() => {
          this.handleAddToCart(false)
        })

        Button() {
          Text('立即购买')
            .fontSize(12)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
        .height(36)
        .backgroundColor('#E53935')
        .borderRadius(4)
        .layoutWeight(1)
        .margin({ left: 4, right: 6 })
        .onClick(() => {
          this.handleAddToCart(true)
        })
      }
    }
    .width('100%')
    .height(48 + this.safeBottom)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 8, right: 8, bottom: this.safeBottom })
    .backgroundColor(Color.White)
    .shadow({ radius: 8, color: '#00000020', offsetY: -2 })
    .zIndex(999)
  }

  private loadDetail() {
    this.isLoading = true
    this.loadError = ''
    queryGoodsDetail(this.goodsId).then(res => {
      this.goods = res?.goods || null
      if (!this.goods) {
        this.loadError = '商品不存在或已下架'
      }
    }).catch(() => {
      this.loadError = '商品加载失败'
    }).finally(() => {
      this.isLoading = false
    })
  }

  private loadStoreGoods() {
    queryStoreGoodsList(this.goodsId).then(res => {
      this.storeGoods = res?.goodsList || []
    }).catch(() => {
      this.storeGoods = []
    })
  }

  private handleAddToCart(buyNow: boolean) {
    if (!this.goodsId) {
      ToastUtil.showToast('商品信息缺失')
      return
    }
    const userId = AppStorage.Get<string>('userAccount') || 'guest'
    addToCart({
      userId: userId,
      goodsId: this.goodsId,
      num: 1,
      color: '默认',
      size: '默认',
      selected: true,
      storeCode: 'default',
      storeName: this.goods?.storeName || '官方自营'
    }).then(() => {
      ToastUtil.showToast(buyNow ? '已加入购物车，前往结算' : '已加入购物车')
      if (buyNow) {
        AppStorage.SetOrCreate<number>('tabIndex', 2)
        router.pushUrl({ url: 'pages/Index' })
      }
    })
  }
}
