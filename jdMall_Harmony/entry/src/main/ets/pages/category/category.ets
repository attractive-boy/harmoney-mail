import { StyleConstants, CommodityList } from "@ohos/common"
import { ImageKnifeView } from "@ohos/common"
import { AppUtil, LogUtil, DisplayUtil } from "@pura/harmony-utils"
import router from '@ohos.router'
import {
  CategoryInfo,
  queryCategoryList,
  queryGroupCategoryList,
  SecondCategoryInfo, ThirdCategoryInfo
} from "../../service/categoryService"

@Component
export struct Category {
  leftScroller: Scroller = new Scroller()
  horizontalScroller: Scroller = new Scroller()
  groupScroller: Scroller = new Scroller()
  commodityScroller: Scroller = new Scroller()

  private isClick = false

  @State selectedCategoryCode:string = ""
  @State categoryList: CategoryInfo[] = []
  @State selectedSecondCategoryCode: string = ''
  @State groupCategoryList: SecondCategoryInfo[] = []
  @State sortOption: string = ''

  aboutToAppear() {
    this.queryLeftCategoryList()
  }

  build() {
    Column() {
      this.CategoryHeader()
      Row() {
        this.LeftCategory()
        this.GroupList()
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(`calc(100% - (${50 + this.getUIContext().px2vp(AppUtil.getStatusBarHeight())}vp))`)
      .backgroundColor(Color.White)
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
  }

  @Builder
  CategoryHeader() {
    Row() {
      Column() {
        Image($r('app.media.scan'))
          .width(20).height(20)
        Text('扫描')
          .margin({top: 2})
          .fontSize(StyleConstants.FONT_SIZE_TWELVE)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
      Row() {
        Image($r('app.media.ic_search'))
          .width(18).height(18)
          .margin({left: 8})
        Text('搜索商品')
          .margin({
            left: 6,
            right: 6,
            top: 2
          })
          .fontSize(StyleConstants.FONT_SIZE_FOURTEEN)
          .fontColor('#8F9093')
          .textAlign(TextAlign.Center)
      }
      .alignItems(VerticalAlign.Center)
      .height(32)
      .width(`calc(100% - 68vp)`)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .onClick(() => {
        router.pushUrl({ url: 'pages/search/search' })
      })

      Column() {
        Image($r('app.media.ic_message_white'))
          .width(20).height(20)
        Text('消息')
          .margin({top: 2})
          .fontSize(StyleConstants.FONT_SIZE_TWELVE)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(50 + this.getUIContext().px2vp(AppUtil.getStatusBarHeight()) )
    .padding({top: this.getUIContext().px2vp(AppUtil.getStatusBarHeight()), left: 10, right: 10})
    .backgroundColor($r('app.color.common_header_bg'))
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  LeftCategory() {
    List({scroller: this.leftScroller}) {
      ForEach(this.categoryList, (item: CategoryInfo, index: number) => {
        ListItem() {
          Row() {
            Text(item.name)
              .fontSize(StyleConstants.FONT_SIZE_FOURTEEN)
              .fontColor(item.code === this.selectedCategoryCode ? $r('app.color.tab_active_color') : Color.Black)
          }
          .height(62)
          .width(StyleConstants.FULL_WIDTH)
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .backgroundColor('#EAEDEE')
          .onClick(() => {
            this.selectedCategoryCode = item.code
            this.leftScroller.scrollToIndex(index, true, ScrollAlign.CENTER)
          })
        }
      },(item: CategoryInfo) => item.code)
    }
    .scrollBar(BarState.Off)
    .friction(0.6)
    .width('calc(100%/3)')
    .height(StyleConstants.FULL_HEIGHT)
    .backgroundColor(Color.White)
  }

  @Builder
  GroupList() {
    Column() {
      // 分类选择tabs
      List({scroller: this.horizontalScroller}) {
        ForEach(this.groupCategoryList, (item: SecondCategoryInfo, index: number) => {
          ListItem() {
            Row() {
              Text(item.categoryName)
                .fontSize(StyleConstants.FONT_SIZE_FOURTEEN)
                .fontColor(this.selectedSecondCategoryCode == item.categoryCode ? $r('app.color.tab_active_color') : Color.Black)
            }
            .height(32)
            .borderRadius(14)
            .padding({left: 15, right: 15})
            .margin({right: index + 1 != this.groupCategoryList.length ? 8 : 0})
            .backgroundColor(Color.White)
            .borderStyle(BorderStyle.Solid)
            .borderWidth(1)
            .borderColor(this.selectedSecondCategoryCode == item.categoryCode ? $r('app.color.tab_active_color') : Color.White)
            .onClick(() => {
              this.isClick = true
              this.selectedSecondCategoryCode = item.categoryCode
              this.horizontalScroller.scrollToIndex(index, true, ScrollAlign.CENTER)
              this.groupScroller.scrollToIndex(index, true, ScrollAlign.START)
            })
          }
          .height(32)
          .margin({top: 8})
        }, (item: SecondCategoryInfo) => item.categoryCode)
      }
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .friction(0.6)
      .height(48)
      .backgroundColor('#EAEDEE')
      .width(StyleConstants.FULL_WIDTH)

      // 排序条件选择器
      this.SortSelector()

      // 商品列表
      CommodityList({
        categoryCode: this.selectedSecondCategoryCode,
        scrollController: this.commodityScroller,
        itemWidth: (DisplayUtil.getWidth() - 30) / 2,
        sort: this.sortOption
      })
    }
    .width('calc(100% * 2/3)')
    .height(StyleConstants.FULL_HEIGHT)
  }

  @Builder
  SortSelector() {
    Row() {
      this.SortButton('综合', '')
      this.SortButton('价格低', 'priceAsc')
      this.SortButton('价格高', 'priceDesc')
      this.SortButton('销量', 'salesDesc')
      this.SortButton('最新', 'newArrival')
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(40)
    .padding({ left: 10, right: 10 })
    .backgroundColor('#F5F5F5')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  @Builder
  SortButton(text: string, value: string) {
    Column() {
      Text(text)
        .fontSize(11)
        .fontColor(this.sortOption === value ? '#E53935' : '#666666')
        .fontWeight(this.sortOption === value ? FontWeight.Bold : FontWeight.Normal)
    }
    .height(40)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.sortOption = this.sortOption === value ? '' : value
    })
  }

  queryLeftCategoryList() {
    queryCategoryList().then(res => {
      const list = res.categoryList || []
      const preferredOrder = [
        '无线接入',
        '交换机',
        '路由器',
        '防火墙',
        '入侵检测',
        '负载均衡器',
        '技术支持服务',
        '解决方案',
        '行业动态'
      ]
      const byName = new Map(list.map(item => [item.name, item]))
      const orderedList = preferredOrder
        .map(name => byName.get(name))
        .filter((item): item is CategoryInfo => item !== undefined)
      const finalList = orderedList.length > 0 ? orderedList : list
      const defaultCategoryCode = finalList.length ? finalList[0].code : ''
      this.categoryList = finalList
      this.selectedCategoryCode = defaultCategoryCode

      if (defaultCategoryCode) {
        this.queryGroupCategoryInfo(defaultCategoryCode)
      }
    })
  }

  queryGroupCategoryInfo(code: string) {
    queryGroupCategoryList(code).then(info => {
      const groupList = info.secondCateList || []
      this.groupCategoryList = groupList
      this.selectedSecondCategoryCode = groupList.length ? groupList[0].categoryCode : ''
    })
  }

}