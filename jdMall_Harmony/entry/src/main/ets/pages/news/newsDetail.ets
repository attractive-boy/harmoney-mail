import router from '@ohos.router'
import { StyleConstants } from '@ohos/common'
import { ImageKnifeView } from '@ohos/common'
import { ToastUtil } from '@pura/harmony-utils'
import { queryNewsDetail, ArticleDetail } from '../../service/newsService'

interface RouterParams {
  id: number
}

@Entry
@Component
struct NewsDetail {
  @StorageProp('safeTop') safeTop: number = 0
  @StorageProp('safeBottom') safeBottom: number = 0

  @State article: ArticleDetail | null = null
  @State isLoading: boolean = true
  @State navBarBg: number = 0   // 0=transparent → 255=white (alpha)

  private scroller: Scroller = new Scroller()
  private articleId: number = 0

  aboutToAppear() {
    const params = router.getParams() as RouterParams
    if (params && params.id) {
      this.articleId = params.id
    }
    this.loadDetail()
  }

  private loadDetail() {
    this.isLoading = true
    queryNewsDetail(this.articleId)
      .then(detail => {
        this.article = detail
        this.isLoading = false
      })
      .catch(() => {
        this.isLoading = false
        ToastUtil.showToast('加载失败，请重试')
      })
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
    return '#888888'
  }

  private formatViewCount(count: number): string {
    if (count >= 10000) {
      return `${(count / 10000).toFixed(1)}万阅读`
    }
    return `${count}阅读`
  }

  private splitContent(content: string): string[] {
    return content.split('\n\n')
  }

  @Builder
  NavBar() {
    Row() {
      Row() {
        Image($r('app.media.ic_back_top'))
          .width(20)
          .height(20)
          .fillColor(this.navBarBg > 200 ? '#1A1A1A' : Color.White)
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor(this.navBarBg > 200 ? Color.Transparent : 'rgba(0,0,0,0.3)')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ left: 16 })
      .onClick(() => router.back())

      Blank()
    }
    .width('100%')
    .height(44 + this.safeTop)
    .padding({ top: this.safeTop })
    .backgroundColor(`rgba(255,255,255,${this.navBarBg / 255})`)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  ArticleContent() {
    Column() {
      if (this.article !== null) {
        // category badge + title
        Column({ space: 10 }) {
          Row({ space: 8 }) {
            Text(this.getCategoryLabel(this.article!.category))
              .fontSize(11)
              .fontColor(Color.White)
              .backgroundColor(this.getCategoryColor(this.article!.category))
              .borderRadius(3)
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })

            Text(this.article!.source)
              .fontSize(12)
              .fontColor('#999999')
          }
          .alignItems(VerticalAlign.Center)

          Text(this.article!.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .lineHeight(30)
            .width('100%')

          // meta row
          Row() {
            Text(this.article!.publishedAt)
              .fontSize(12)
              .fontColor('#AAAAAA')

            Text('·')
              .fontSize(12)
              .fontColor('#CCCCCC')
              .margin({ left: 8, right: 8 })

            Text(this.formatViewCount(this.article!.viewCount))
              .fontSize(12)
              .fontColor('#AAAAAA')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 16 })
        .backgroundColor(Color.White)

        // divider
        Divider().color('#F0F0F0').height(8).backgroundColor('#F0F0F0')

        // content paragraphs
        Column({ space: 0 }) {
          ForEach(this.splitContent(this.article!.content), (para: string) => {
            if (para.startsWith('▌')) {
              // section header
              Row() {
                Text(para)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#1A1A1A')
                  .width('100%')
                  .padding({ left: 12, right: 16, top: 16, bottom: 8 })
              }
              .width('100%')
              .border({ width: { left: 3 }, color: '#E53935', style: BorderStyle.Solid })
            } else if (para.startsWith('-')) {
              // list item line
              Text(para)
                .fontSize(14)
                .fontColor('#333333')
                .lineHeight(24)
                .width('100%')
                .padding({ left: 20, right: 16, top: 4, bottom: 4 })
            } else {
              Text(para)
                .fontSize(15)
                .fontColor('#333333')
                .lineHeight(26)
                .width('100%')
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            }
          })

          Row().height(32)
        }
        .width('100%')
        .backgroundColor(Color.White)
        .margin({ top: 0 })
      }
    }
    .width('100%')
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#E53935')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F5F5F5')
      } else if (this.article !== null) {
        Scroll(this.scroller) {
          Column() {
            // header image (full width)
            ImageKnifeView({
              loadSrc: this.article!.imageUrl,
              objectFit: ImageFit.Cover,
              placeholderSrc: $r('app.media.default')
            })
              .width('100%')
              .height(220)

            this.ArticleContent()

            Row().height(this.safeBottom + 20)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .friction(0.6)
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')
        .onDidScroll(() => {
          const offset = this.scroller.currentOffset().yOffset
          const alpha = Math.min(255, (offset / 150) * 255)
          this.navBarBg = alpha
        })
      }

      // floating navbar on top
      this.NavBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
