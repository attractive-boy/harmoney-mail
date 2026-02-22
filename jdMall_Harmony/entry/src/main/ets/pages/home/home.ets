import { RefreshComponent, getRefreshStatusText, StyleConstants, CommodityList, FloatingBackTop, DataSource, ImageKnifeView } from '@ohos/common'
import { DisplayUtil, LogUtil, WindowUtil } from '@pura/harmony-utils'
import router from '@ohos.router'
import { queryHomePageInfo, TabInfo, BannerInfo, NineMenuInfo, HomePageInfo } from '../../service/homeService'

interface StrategyOption {
  label: string
  value: string
}

@Component
export struct Home {
  @State searchHeaderHeight: number = 80 //min-40, max 80

  @State isRefreshing: boolean = false
  @State promptText: string = "下拉刷新"

  @State adUrl: string = ''
  @State tabsCurrentIndex: number = 0
  @State tabList: TabInfo[] = []
  @State selectedStrategy: string = 'smart'
  @State refreshSeed: number = 0
  @State showBackTop: boolean[] = []

  @StorageProp('safeTop') safeTop: number = 0
  @StorageProp('safeBottom') safeBottom: number = 0

  private tabsController = new TabsController()
  private scrollScroller: Scroller = new Scroller()

  private waterFlowScrollerList: Scroller[] = [new Scroller(),new Scroller(),new Scroller(),new Scroller(),new Scroller()]

  private swiperData = new DataSource<BannerInfo>([])
  private nineMenuList = new DataSource<NineMenuInfo>([])
  private nineMenuList2 = new DataSource<NineMenuInfo>([])

  goodsItemWidth = (DisplayUtil.getWidth() - 30) / 2
  private strategyOptions: StrategyOption[] = [
    { label: '智能推荐', value: 'smart' },
    { label: '销量最高', value: 'topSales' },
    { label: '评价最优', value: 'topRated' },
    { label: '新品上架', value: 'newArrival' }
  ]

  aboutToAppear() {
    this.queryInfo()
  }


  build() {
    Refresh({ refreshing: $$this.isRefreshing, builder: this.refreshComponent() }) {
      Stack() {
        this.FoldableHeader()
        Scroll(this.scrollScroller) {
          Column() {
            this.SwiperComponent()
            this.AdvComponent()
            this.MenuSlider()
            this.StrategyBar()
            this.TabsContentList()
          }
          .width(StyleConstants.FULL_WIDTH)
          .padding({top: this.searchHeaderHeight + this.safeTop})
        }
        .edgeEffect(EdgeEffect.Spring)
        .friction(0.6)
        .scrollBar(BarState.Off)
        .backgroundColor('#F6F0F7')
        .width(StyleConstants.FULL_WIDTH)
        .height(StyleConstants.FULL_HEIGHT)

        this.BackTop()
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(StyleConstants.FULL_HEIGHT)
    }
    .pullToRefresh(true)
    .refreshOffset(96)
    .onStateChange((refreshStatus: RefreshStatus) => {this.promptText = getRefreshStatusText(refreshStatus)})
    .onOffsetChange(offset => {
      WindowUtil.setWindowSystemBarProperties({statusBarContentColor: offset > this.safeTop ? '#000000':'#FFFFFF'})
    })
    .onRefreshing(() => {
      setTimeout(() => {
        this.promptText = '刷新成功'
        this.isRefreshing = false
      }, 2000)
    })
  }

  @Builder
  refreshComponent() {
    RefreshComponent({promptText: this.promptText, progressOffsetTop: this.safeTop})
  }

  @Builder
  FoldableHeader() {
    Stack() {
      Row() {
        Image($r('app.media.ic_pet'))
          .width(32).height(32)
          .margin({left: 16})
        Blank()
        Image($r('app.media.ic_scan'))
          .width(28).height(28)
          .margin({right: 16})
      }
      .width('100%')
      .position({x: 0, y: this.safeTop})
      Row() {
        Row() {
          Image($r('app.media.ic_search'))
            .width(20).height(20)
            .margin({left: 8})
          Text('搜索商品')
            .margin({
              left: 6,
              right: 6
            })
            .fontSize(StyleConstants.FONT_SIZE_SIXTEEN)
            .fontColor('#8F9093')
            .textAlign(TextAlign.Center)
          Blank()
          Image($r('app.media.ic_camera'))
            .width(20).height(20)
            .margin({right: 8})
        }
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .height(32)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .onClick(() => {
          router.pushUrl({ url: 'pages/search/search' })
        })
      }
      .padding({left: 16, right: 16})
      .position({x: 0, y: 40 + this.safeTop})
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(this.searchHeaderHeight + this.safeTop)
    .backgroundColor($r('app.color.common_header_bg'))
    .position({x: 0, y: 0})
    .zIndex(1)
  }

  @Builder
  SwiperComponent() {
    Column() {
      Column() {
        Swiper() {
          LazyForEach(this.swiperData, (item: BannerInfo) => {
            ImageKnifeView({
              loadSrc: item.imgUrl,
              objectFit: ImageFit.Fill
            }).width(StyleConstants.FULL_WIDTH).height(150)
          }, (item: string) => item)
        }
        .borderRadius(6)
        .cachedCount(2)
        .index(0)
        .autoPlay(true)
        .interval(6000)
        .loop(true)
        .duration(500)
        .itemSpace(0)
        .indicator( // 设置圆点导航点样式
          new DotIndicator()
            .itemWidth(8)
            .itemHeight(8)
            .selectedItemWidth(8)
            .selectedItemHeight(8)
            .color($r('app.color.dot_color'))
            .selectedColor($r('app.color.dot_active_color'))
            .maxDisplayCount(9)
        )
        .curve(Curve.Linear)
      }
      .width(StyleConstants.FULL_WIDTH)
      .padding({left:12, top: 14, right: 12, bottom: 2})
      .backgroundColor(Color.White)
      .borderRadius({topLeft: 8, topRight: 8})
    }
    .width(StyleConstants.FULL_WIDTH)
    .backgroundColor('#EA3931')
  }

  @Builder
  AdvComponent() {
    ImageKnifeView({
      loadSrc: this.adUrl,
      objectFit: ImageFit.Fill
    })
      .height(78)
      .width(StyleConstants.FULL_WIDTH)
      .backgroundColor(Color.White)
  }

  @Builder
  MenuSlider() {
    Swiper() {
      Grid() {
        LazyForEach(this.nineMenuList, (item: NineMenuInfo) => {
          GridItem() {
            Column() {
              ImageKnifeView({
                loadSrc: item.menuIcon,
                objectFit: ImageFit.Fill
              }).width(40).height(40)
              Text(item.menuName)
                .margin({top: 4})
                .fontSize(12)
                .fontColor('#4B4B4B')
            }
          }
        }, (item: NineMenuInfo) => item.menuCode)
      }
      .padding({bottom: 26})
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr')

      Grid() {
        LazyForEach(this.nineMenuList2, (item: NineMenuInfo) => {
          GridItem() {
            Column() {
              ImageKnifeView({
                loadSrc: item.menuIcon,
                objectFit: ImageFit.Fill
              }).width(40).height(40)
              Text(item.menuName)
                .margin({top: 4})
                .fontSize(12)
                .fontColor('#4B4B4B')
            }
          }
        }, (item: NineMenuInfo) => item.menuCode)
      }
      .padding({bottom: 26})
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr')
    }
    .height(168)
    .width(StyleConstants.FULL_WIDTH)
    .index(0)
    .autoPlay(false)
    .loop(false)
    .backgroundColor(Color.White)
    .itemSpace(0)
    .indicator( // 设置圆点导航点样式
      new DotIndicator()
        .itemWidth(6)
        .itemHeight(6)
        .selectedItemWidth(6)
        .selectedItemHeight(6)
        .color($r('app.color.dot_color'))
        .selectedColor($r('app.color.dot_active_color'))
    )
    .curve(Curve.Linear)
  }

  @Builder
  StrategyBar() {
    Row() {
      ForEach(this.strategyOptions, (item: StrategyOption) => {
        Text(item.label)
          .fontSize(12)
          .fontColor(this.selectedStrategy === item.value ? Color.White : '#5E5F62')
          .padding({left: 10, right: 10, top: 6, bottom: 6})
          .borderRadius(14)
          .backgroundColor(this.selectedStrategy === item.value ? '#EC5F5A' : '#F2F2F2')
          .onClick(() => {
            if (this.selectedStrategy !== item.value) {
              this.selectedStrategy = item.value
              this.refreshSeed = this.refreshSeed + 1
            }
          })
          .margin({right: 8})
      })
    }
    .width(StyleConstants.FULL_WIDTH)
    .padding({left: 12, right: 12, top: 10, bottom: 10})
    .backgroundColor(Color.White)
  }

  @Builder
  TabBarBuilder(title:string, index:number){
    Column(){
      Text(title)
        .fontSize(StyleConstants.FONT_SIZE_SIXTEEN)
        .fontColor(this.tabsCurrentIndex == index ? $r('app.color.tab_active_color') : $r('app.color.tab_txt_color'))
    }
    .justifyContent(FlexAlign.Center)
    .width(StyleConstants.FULL_WIDTH)
    .height(50)
    .onClick(()=>{
      this.tabsCurrentIndex = index
      this.tabsController.changeIndex(this.tabsCurrentIndex)
    })
  }

  @Builder
  TabsContentList() {
    Tabs({ barPosition: BarPosition.Start, controller: this.tabsController }) {
      ForEach(this.tabList, (item: TabInfo, index: number) => {
        TabContent() {
          if (this.refreshSeed % 2 === 0) {
            CommodityList({
              categoryCode: item.code,
              scrollController: this.waterFlowScrollerList[index],
              itemWidth: this.goodsItemWidth,
              strategy: this.selectedStrategy,
              onScrollIndexCall: (first => { this.showBackTop[index] = first > 2 })
            })
          } else {
            CommodityList({
              categoryCode: item.code,
              scrollController: this.waterFlowScrollerList[index],
              itemWidth: this.goodsItemWidth,
              strategy: this.selectedStrategy,
              onScrollIndexCall: (first => { this.showBackTop[index] = first > 2 })
            })
          }
        }.tabBar(this.TabBarBuilder(item.name, index))
      })
    }
    .barHeight(50)
    .vertical(false)
    .height(StyleConstants.FULL_HEIGHT)
  }

  @Builder
  BackTop() {
    FloatingBackTop({
      location: ({ x: '85%', y: '90%' }),
      display: (this.showBackTop[this.tabsCurrentIndex] ? Visibility.Visible : Visibility.None),
      onClickFun: (() => {
        // LogUtil.info([
        //   'waterFlowScrollerList',
        //   this.waterFlowScrollerList
        // ])
        this.waterFlowScrollerList.forEach(scroller => {
          scroller.scrollTo({xOffset: 0, yOffset: 0, animation: { duration: 200, curve: Curve.Friction }})
        })
        this.scrollScroller.scrollTo({xOffset: 0, yOffset: 0, animation: { duration: 400, curve: Curve.Friction }})
      })
    })
  }

  queryInfo() {
    LogUtil.info(['[home] queryInfo start'])
    queryHomePageInfo().then((info: HomePageInfo) => {
      LogUtil.info(['[home] queryInfo success', JSON.stringify(info || {})])
      this.adUrl = info.adUrl
      this.swiperData.setData(info.bannerList || [])
      this.nineMenuList.setData(info.nineMenuList?.filter((_, index)=> index < 10))
      this.nineMenuList2.setData(info.nineMenuList?.filter((_, index)=> index >= 10))

      const tabLen = (info.tabList || []).length
      this.showBackTop = new Array(tabLen).fill(false)
      this.tabList = info.tabList || []
    }).catch((error: ESObject) => {
      LogUtil.error(['[home] queryInfo failed', JSON.stringify(error || {})])
    })
  }


}
