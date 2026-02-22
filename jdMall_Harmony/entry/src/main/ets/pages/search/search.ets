import router from '@ohos.router'
import { StyleConstants, CommodityList } from '@ohos/common'
import { DisplayUtil, ToastUtil } from '@pura/harmony-utils'

@Entry
@Component
export struct SearchPage {
  @StorageProp('safeTop') safeTop: number = 0

  @State searchKeyword: string = ''
  @State sortOption: string = ''
  @State searchHistory: string[] = []
  @State isSearching: boolean = false
  private searchScroller: Scroller = new Scroller()

  aboutToAppear() {
    this.loadSearchHistory()
  }

  build() {
    Column() {
      this.SearchHeader()
      
      if (this.isSearching) {
        CommodityList({
          searchKeyword: this.searchKeyword,
          scrollController: this.searchScroller,
          itemWidth: (DisplayUtil.getWidth() - 30) / 2,
          sort: this.sortOption,
          isSearch: true
        })
      } else {
        this.SearchHistoryView()
      }
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .backgroundColor('#F5F5F5')
  }

  @Builder
  SearchHeader() {
    Column() {
      Row() {
        Text('←')
          .fontSize(18)
          .fontColor(Color.White)
          .onClick(() => router.back())
        
        TextInput({ placeholder: '搜索商品', text: this.searchKeyword })
          .onChange((value) => {
            this.searchKeyword = value
          })
          .onSubmit(() => {
            this.performSearch()
          })
          .width('calc(100% - 70vp)')
          .height(36)
          .margin({ left: 10, right: 10 })
          .padding({ left: 10, right: 10 })
          .backgroundColor(Color.White)
          .borderRadius(18)

        if (this.searchKeyword) {
          Text('✕')
            .fontSize(14)
            .fontColor('#999999')
            .onClick(() => {
              this.searchKeyword = ''
              this.isSearching = false
              this.sortOption = ''
            })
        }
      }
      .width(StyleConstants.FULL_WIDTH)
      .height(50)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#E53935')

      if (this.isSearching) {
        this.SortSelector()
      }
    }
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

  @Builder
  SearchHistoryView() {
    Column() {
      Column() {
        Text('搜索历史')
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 10 })

        if (this.searchHistory.length > 0) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.searchHistory, (item: string, index: number) => {
              Row() {
                Text(item)
                  .fontSize(11)
                  .fontColor('#666666')
                  .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                  .borderRadius(4)
                  .border({ color: '#E0E0E0', width: 0.5 })
                  .onClick(() => {
                    this.searchKeyword = item
                    this.performSearch()
                  })
              }
              .margin({ right: 8, bottom: 8 })
            }, (item: string, index: number) => index.toString())
          }
          .width(StyleConstants.FULL_WIDTH)

          Row() {
            Text('清空历史')
              .fontSize(11)
              .fontColor('#E53935')
              .onClick(() => {
                this.searchHistory = []
                this.saveSearchHistory()
                ToastUtil.showToast('已清空搜索历史')
              })
          }
          .width(StyleConstants.FULL_WIDTH)
          .margin({ top: 12 })
        } else {
          Text('暂无搜索历史')
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .padding(12)
      .width(StyleConstants.FULL_WIDTH)
      .backgroundColor(Color.White)
      .margin({ top: 12 })
    }
    .padding({ left: 12, right: 12, top: 12 })
  }

  private performSearch() {
    if (!this.searchKeyword.trim()) {
      ToastUtil.showToast('请输入搜索词')
      return
    }

    this.isSearching = true
    
    // 保存搜索历史
    if (this.searchHistory.indexOf(this.searchKeyword) === -1) {
      this.searchHistory.unshift(this.searchKeyword)
      if (this.searchHistory.length > 10) {
        this.searchHistory.pop()
      }
      this.saveSearchHistory()
    }
  }

  private loadSearchHistory() {
    const appStorage = AppStorage.Get<string>('searchHistory')
    if (appStorage) {
      try {
        this.searchHistory = JSON.parse(appStorage)
      } catch (e) {
        this.searchHistory = []
      }
    }
  }

  private saveSearchHistory() {
    AppStorage.SetOrCreate<string>('searchHistory', JSON.stringify(this.searchHistory))
  }
}
