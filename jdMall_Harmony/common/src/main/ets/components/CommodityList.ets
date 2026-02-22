import router from '@ohos.router'
import { LogUtil } from '@pura/harmony-utils'
import { StyleConstants } from '../../../../Index'
import { CommodityInfo, queryGoodsListByPage, trackEvent, searchGoods, GoodsPageInfo } from '../service/common'
import { DataSource } from '../utils/DataSource'
import { LoadMoreFooter } from './LoadMoreFooter'
import { ImageKnifeView } from './ImageKnifeView'

@Component
export struct CommodityList {
  @Watch('onCategoryChange')
  @Prop categoryCode: string = '01'
  @Prop itemWidth: number = 0
  @Prop strategy: string = 'smart'
  @Watch('onSortChange')
  @Prop sort: string = ''
  @Watch('onSearchKeywordChange')
  @Prop searchKeyword: string = ''
  @Prop isSearch: boolean = false

  @State currentPage: number = 1
  @State isLoading: boolean = true
  @State hasNext: boolean = true

  scrollController?: Scroller
  onScrollIndexCall?: (first: number) => void

  private dataSource = new DataSource<CommodityInfo>([])
  private impressionSet: Set<string> = new Set()

  constructor(scrollController: Scroller, onScrollIndexCall: (first: number) => void) {
    super()
    this.scrollController = scrollController
    this.onScrollIndexCall = onScrollIndexCall
  }

  aboutToAppear() {
    this.queryGoodsList(1)
  }

  onCategoryChange(propName: string) {
    if (propName === 'categoryCode') {
      this.currentPage = 1
      this.hasNext = true
      this.impressionSet.clear()
      this.dataSource.setData([])
      this.queryGoodsList(1)
    }
  }

  onSortChange(propName: string) {
    if (propName === 'sort') {
      this.currentPage = 1
      this.hasNext = true
      this.dataSource.setData([])
      this.queryGoodsList(1)
    }
  }

  onSearchKeywordChange(propName: string) {
    if (propName === 'searchKeyword' && this.isSearch) {
      this.currentPage = 1
      this.hasNext = true
      this.impressionSet.clear()
      this.dataSource.setData([])
      this.queryGoodsList(1)
    }
  }

  build() {
    WaterFlow({scroller: this.scrollController, footer: this.footer()}) {
      LazyForEach(this.dataSource, (item: CommodityInfo) => {
        FlowItem() {
         this.GoodsItem(item)
        }
        .width(StyleConstants.FULL_WIDTH)
        .onAppear(() => {
          this.trackImpression(item)
        })
      }, (item:CommodityInfo) => item.id)
    }
    .columnsTemplate('1fr 1fr')
    .rowsGap(10)
    .columnsGap(10)
    .padding({left: 10, right: 10})
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .nestedScroll({
      scrollForward: NestedScrollMode.PARENT_FIRST,
      scrollBackward: NestedScrollMode.SELF_FIRST
    })
    .onScrollIndex((first)=> {
      if(this.onScrollIndexCall) this.onScrollIndexCall(first)
    })
    .onReachEnd(() => {
      if(!this.isLoading && this.hasNext) {
        this.queryGoodsList(this.currentPage + 1)
      }
    })
  }

  @Builder
  footer() {
    LoadMoreFooter({isLoading: this.isLoading, hasNextPage: this.hasNext})
  }

  @Builder
  GoodsItem(item: CommodityInfo) {
    Column() {
      ImageKnifeView({
        loadSrc: item.imgUrl,
        objectFit: ImageFit.Fill,
        borderOption: {radius: {topLeft: 8, topRight: 8}}
      })
        .width(StyleConstants.FULL_WIDTH)
        .height(this.getUIContext().px2vp(this.itemWidth))

      Column(){
        Text(item.description)
          .maxLines(2)
          .textOverflow({overflow: TextOverflow.Ellipsis})
          .fontSize(StyleConstants.FONT_SIZE_FOURTEEN)
          .fontColor($r('app.color.goods_description'))

        Text(`￥${item.price}`)
          .fontSize(StyleConstants.FONT_SIZE_TWELVE)
          .fontColor($r('app.color.goods_price'))
          .margin({top: 8})
      }
      .padding({top: 10, left:6, right:6, bottom: 12})
      .width(StyleConstants.FULL_WIDTH)
      .alignItems(HorizontalAlign.Start)
      .visibility(item.type == '1' ? Visibility.Visible: Visibility.None)

      Column(){
        Text(item.tag)
          .fontSize(StyleConstants.FONT_SIZE_FOURTEEN)
          .fontColor(Color.White)
          .borderRadius(18)
          .padding({left: 8, right: 8, top: 2, bottom: 2})
          .linearGradient({
            direction: GradientDirection.Right,
            colors: [['#D2554F', 0.2],['#D47273', 0.6], ['#D79098', 0.2]]
          })
        Text(item.des1).fontSize(StyleConstants.FONT_SIZE_FOURTEEN).fontColor('#EC5F5A').margin({top: 4})
        Text(item.des2).fontSize(StyleConstants.FONT_SIZE_FOURTEEN).fontColor('#9E9F9E').margin({top: 4})
        Text('点击进入').fontSize(StyleConstants.FONT_SIZE_TWELVE).fontColor('#EC5F5A').margin({top: 4})
      }
      .width(StyleConstants.FULL_WIDTH)
      .padding({top: 10, left:6, right: 6, bottom: 12})
      .alignItems(HorizontalAlign.Start)
      .visibility(item.type == '2' ? Visibility.Visible: Visibility.None)
    }
    .width(StyleConstants.FULL_WIDTH)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .onClick(() => {
      this.trackClick(item)
      if (item?.id) {
        router.pushUrl({ url: 'pages/detail/detail', params: { goodsId: item.id } })
      }
    })
  }

  private resetAndQuery() {
    this.currentPage = 1
    this.hasNext = true
    this.impressionSet.clear()
    this.dataSource.setData([])
    this.queryGoodsList(1)
  }

  private trackImpression(item: CommodityInfo) {
    if (!item?.id) {
      return
    }
    if (this.impressionSet.has(item.id)) {
      return
    }
    this.impressionSet.add(item.id)
    trackEvent({ goodsId: item.id, event: 'impression' })
  }

  private trackClick(item: CommodityInfo) {
    if (!item?.id) {
      return
    }
    trackEvent({ goodsId: item.id, event: 'click' })
  }



  queryGoodsList(pageNo: number) {
    this.isLoading = true
    
    if (this.isSearch && this.searchKeyword) {
      // 搜索模式
      searchGoods(this.searchKeyword, pageNo, 15, this.sort).then((pageInfo: GoodsPageInfo) => {
        this.isLoading = false
        if(pageNo == 1) {
          this.dataSource.setData(pageInfo.goodsList || [])
        } else {
          this.dataSource.addNewItems(pageInfo.goodsList || [])
        }
        this.hasNext = pageNo < pageInfo.totalPageCount
        this.currentPage = pageNo
      }).catch((error: Error) => {
        this.isLoading = false
        LogUtil.error('Search error:', error.message)
      })
    } else {
      // 分类模式
      queryGoodsListByPage(this.categoryCode, pageNo, 15, this.strategy, this.sort).then((pageInfo: GoodsPageInfo) => {
        this.isLoading = false
        if(pageNo == 1) {
          this.dataSource.setData(pageInfo.goodsList || [])
        } else {
          this.dataSource.addNewItems(pageInfo.goodsList || [])
        }
        this.hasNext = pageNo < pageInfo.totalPageCount
        this.currentPage = pageNo
      }).catch((error: Error) => {
        this.isLoading = false
        LogUtil.error('Query error:', error.message)
      })
    }
  }
}