import { ImageKnifeComponent, ImageKnifeOption } from '@ohos/imageknife'

@Component
export struct ImageKnifeView {
  @Prop loadSrc: string | Resource | PixelMap = ''
  @Prop placeholderSrc: string | Resource | PixelMap = $r('app.media.default')
  @Prop errorholderSrc: string | Resource | PixelMap = $r('app.media.default')
  @Prop objectFit: ImageFit = ImageFit.Fill
  @Prop borderOption: BorderOptions = {}

  @State private option: ImageKnifeOption = new ImageKnifeOption()

  build() {
    ImageKnifeComponent({ imageKnifeOption: this.getOption() })
  }

  private getOption(): ImageKnifeOption {
    this.option.loadSrc = this.loadSrc
    this.option.placeholderSrc = this.placeholderSrc
    this.option.errorholderSrc = this.errorholderSrc
    this.option.objectFit = this.objectFit
    this.option.border = this.borderOption
    return this.option
  }
}
