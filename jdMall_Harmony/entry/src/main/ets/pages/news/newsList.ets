import router from '@ohos.router'
import { StyleConstants } from '@ohos/common'
import { ImageKnifeView } from '@ohos/common'
import { ToastUtil } from '@pura/harmony-utils'
import { queryNewsList, ArticleInfo, QueryNewsParams } from '../../service/newsService'

interface TabItem {
  key: string
  label: string
}

interface RouterParams {
  id: number
}

@Entry
@Component
struct NewsList {
  @StorageProp('safeTop') safeTop: number = 0
  @StorageProp('safeBottom') safeBottom: number = 0

  @State articleList: ArticleInfo[] = []
  @State currentTab: string = 'ALL'
  @State isLoading: boolean = false
  @State isLoadingMore: boolean = false
  @State currentPage: number = 0
  @State hasMore: boolean = true
  @State totalElements: number = 0

  private scroller: Scroller = new Scroller()
  private readonly PAGE_SIZE: number = 10

  private tabs: TabItem[] = [
    { key: 'ALL', label: '全部' } as TabItem,
    { key: 'INDUSTRY', label: '行业动态' } as TabItem,
    { key: 'TECH', label: '技术趋势' } as TabItem
  ]

  aboutToAppear() {
    this.loadArticles(true)
  }

  private loadArticles(reset: boolean) {
    if (reset) {
      this.currentPage = 0
      this.hasMore = true
      this.articleList = []
    }
    if (!this.hasMore && !reset) {
      return
    }
    if (reset) {
      this.isLoading = true
    } else {
      this.isLoadingMore = true
    }

    const params: QueryNewsParams = {
      category: this.currentTab,
      page: this.currentPage,
      size: this.PAGE_SIZE
    }

    queryNewsList(params)
      .then(result => {
        if (reset) {
          this.articleList = result.list
        } else {
          this.articleList = this.articleList.concat(result.list)
        }
        this.hasMore = result.hasMore
        this.totalElements = result.totalElements
        this.currentPage = result.currentPage + 1
        this.isLoading = false
        this.isLoadingMore = false
      })
      .catch(() => {
        this.isLoading = false
        this.isLoadingMore = false
        ToastUtil.showToast('加载失败，请重试')
      })
  }

  private switchTab(key: string) {
    if (this.currentTab === key) {
      return
    }
    this.currentTab = key
    this.scroller.scrollTo({ xOffset: 0, yOffset: 0 })
    this.loadArticles(true)
  }

  private getCategoryLabel(category: string): string {
    if (category === 'INDUSTRY') {
      return '行业动态'
    }
    if (category === 'TECH') {
      return '技术趋势'
    }
    return '资讯'
  }

  private getCategoryColor(category: string): string {
    if (category === 'INDUSTRY') {
      return '#FF6600'
    }
    if (category === 'TECH') {
      return '#0072E6'
    }
    return '#999999'
  }

  private formatViewCount(count: number): string {
    if (count >= 10000) {
      const w = count / 10000
      return `${w.toFixed(1)}万 阅读`
    }
    return `${count} 阅读`
  }

  @Builder
  Header() {
    Row() {
      Image($r('app.media.ic_back_top'))
        .width(24)
        .height(24)
        .margin({ left: 16 })
        .onClick(() => router.back())

      Text('资讯')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Row().width(24).height(24).margin({ right: 16 })
    }
    .width('100%')
    .height(44)
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
    .padding({ top: 0 })
  }

  @Builder
  TabBar() {
    Row() {
      ForEach(this.tabs, (tab: TabItem) => {
        Column() {
          Text(tab.label)
            .fontSize(15)
            .fontWeight(this.currentTab === tab.key ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTab === tab.key ? '#E53935' : '#666666')

          Divider()
            .width(24)
            .height(2)
            .color('#E53935')
            .opacity(this.currentTab === tab.key ? 1 : 0)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => this.switchTab(tab.key))
      })
    }
    .width('100%')
    .height(44)
    .backgroundColor(Color.White)
  }

  @Builder
  ArticleCard(article: ArticleInfo) {
    Column() {
      Row({ space: 12 }) {
        // thumbnail
        ImageKnifeView({
          loadSrc: article.imageUrl,
          objectFit: ImageFit.Cover,
          borderOption: { radius: 6 },
          placeholderSrc: $r('app.media.default')
        })
          .width(100)
          .height(70)
          .flexShrink(0)

        // right content
        Column() {
          // category tag + title
          Row({ space: 6 }) {
            Text(this.getCategoryLabel(article.category))
              .fontSize(10)
              .fontColor(Color.White)
              .backgroundColor(this.getCategoryColor(article.category))
              .borderRadius(2)
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })

            Text(article.title)
              .fontSize(14)
              .fontColor('#1A1A1A')
              .fontWeight(FontWeight.Medium)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)

          Blank()

          // meta info
          Row() {
            Text(article.source)
              .fontSize(11)
              .fontColor('#999999')

            Blank()

            Text(this.formatViewCount(article.viewCount))
              .fontSize(11)
              .fontColor('#BBBBBB')
              .margin({ right: 8 })

            Text(article.publishedAt)
              .fontSize(11)
              .fontColor('#BBBBBB')
          }
          .width('100%')
        }
        .layoutWeight(1)
        .height(70)
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .alignItems(VerticalAlign.Top)

      Divider().color('#F5F5F5').width('calc(100% - 32vp)').margin({ left: 16 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .onClick(() => {
      const params: RouterParams = { id: article.id }
      router.pushUrl({ url: 'pages/news/newsDetail', params: params })
    })
  }

  @Builder
  LoadMoreFooter() {
    if (this.isLoadingMore) {
      Row() {
        LoadingProgress()
          .width(20)
          .height(20)
          .color('#E53935')
          .margin({ right: 8 })
        Text('加载中...')
          .fontSize(13)
          .fontColor('#999999')
      }
      .width('100%')
      .height(50)
      .justifyContent(FlexAlign.Center)
    } else if (!this.hasMore && this.articleList.length > 0) {
      Text('已经到底啦~')
        .fontSize(13)
        .fontColor('#BBBBBB')
        .width('100%')
        .height(50)
        .textAlign(TextAlign.Center)
    }
  }

  @Builder
  EmptyView() {
    Column() {
      Text('📰')
        .fontSize(48)
        .margin({ bottom: 12 })
      Text('暂无资讯')
        .fontSize(15)
        .fontColor('#999999')
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      // status bar padding
      Row().height(this.safeTop).width('100%').backgroundColor(Color.White)

      this.Header()

      // tab separator
      Divider().color('#EEEEEE').height(1)

      this.TabBar()

      Divider().color('#EEEEEE').height(1)

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#E53935')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.articleList.length === 0) {
        this.EmptyView()
      } else {
        Scroll(this.scroller) {
          Column() {
            ForEach(this.articleList, (article: ArticleInfo) => {
              this.ArticleCard(article)
            })

            this.LoadMoreFooter()
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .friction(0.6)
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
        .onDidScroll(() => {
          const offset = this.scroller.currentOffset().yOffset
          const totalHeight = this.articleList.length * 100
          if (offset > totalHeight - 400 && this.hasMore && !this.isLoadingMore) {
            this.loadArticles(false)
          }
        })
      }

      Row().height(this.safeBottom).width('100%').backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
