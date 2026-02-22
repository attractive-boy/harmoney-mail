import router from '@ohos.router'
import { StyleConstants } from '@ohos/common'
import { ToastUtil } from '@pura/harmony-utils'
import { registerAccount } from '../../service/authService'

@Entry
@Component
export struct Register {
  @State account: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State isSubmitting: boolean = false
  @StorageProp('safeTop') safeTop: number = 0

  build() {
    Column() {
      this.Header()
      this.Form()
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(StyleConstants.FULL_HEIGHT)
    .backgroundColor('#F7F7F7')
  }

  @Builder
  Header() {
    Row() {
      Text('返回')
        .fontSize(14)
        .fontColor('#666666')
        .onClick(() => router.back())

      Blank()
      Text('注册')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.Black)
      Blank()
      Text('')
        .width(40)
    }
    .width(StyleConstants.FULL_WIDTH)
    .height(50 + this.safeTop)
    .padding({ left: 12, right: 12, top: this.safeTop })
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.White)
  }

  @Builder
  Form() {
    Column() {
      Text('手机号或邮箱注册')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 20, bottom: 10 })

      Column() {
        TextInput({ text: this.account, placeholder: '请输入手机号或邮箱' })
          .height(44)
          .fontSize(14)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => this.account = value)

        TextInput({ text: this.password, placeholder: '请输入密码(至少8位, 含字母和数字)' })
          .height(44)
          .fontSize(14)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .type(InputType.Password)
          .margin({ top: 12 })
          .onChange((value: string) => this.password = value)

        TextInput({ text: this.confirmPassword, placeholder: '请再次输入密码' })
          .height(44)
          .fontSize(14)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .type(InputType.Password)
          .margin({ top: 12 })
          .onChange((value: string) => this.confirmPassword = value)
      }
      .width('100%')

      Button() {
        Text(this.isSubmitting ? '注册中...' : '注册')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
      }
      .width('100%')
      .height(48)
      .margin({ top: 24 })
      .backgroundColor($r('app.color.theme_color'))
      .borderRadius(24)
      .shadow({
        radius: 16,
        color: 'rgba(230, 0, 18, 0.3)',
        offsetX: 0,
        offsetY: 4
      })
      .enabled(!this.isSubmitting)
      .opacity(this.isSubmitting ? 0.6 : 1.0)
      .stateStyles({
        normal: {
          .scale({ x: 1.0, y: 1.0 })
        },
        pressed: {
          .scale({ x: 0.98, y: 0.98 })
        }
      })
      .onClick(() => this.onSubmit())

      Text('密码至少8位，且同时包含字母与数字')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 10 })

      Text('已有账号？去登录')
        .fontSize(12)
        .fontColor('#666666')
        .margin({ top: 10 })
        .onClick(() => router.pushUrl({ url: 'pages/auth/login' }))
    }
    .width('calc(100% - 40vp)')
    .margin({ left: 20, right: 20, top: 10 })
  }

  private async onSubmit(): Promise<void> {
    const account = this.account.trim()
    const password = this.password
    const confirm = this.confirmPassword

    if (!account) {
      ToastUtil.showToast('请输入手机号或邮箱')
      return
    }
    if (!this.isValidAccount(account)) {
      ToastUtil.showToast('手机号或邮箱格式不正确')
      return
    }
    if (!password) {
      ToastUtil.showToast('请输入密码')
      return
    }
    if (!this.isValidPassword(password)) {
      ToastUtil.showToast('密码至少8位且包含字母和数字')
      return
    }
    if (password !== confirm) {
      ToastUtil.showToast('两次输入密码不一致')
      return
    }

    this.isSubmitting = true
    try {
      const data = await registerAccount({ account, password })
      AppStorage.setOrCreate('userToken', data.token || '')
      AppStorage.setOrCreate('userAccount', data.account || account)
      AppStorage.setOrCreate('userDisplayName', data.nickname || data.account || account)
      AppStorage.setOrCreate('userPoints', data.points ?? 0)
      AppStorage.setOrCreate('userCredit', data.credit ?? 0)
      AppStorage.setOrCreate('authRefreshTick', Date.now())
      ToastUtil.showToast('注册成功')
      router.back()
    } catch (error) {
      ToastUtil.showToast('注册失败，请稍后重试')
    } finally {
      this.isSubmitting = false
    }
  }

  private isValidAccount(value: string): boolean {
    if (value.includes('@')) {
      return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
    }
    return /^1\d{10}$/.test(value)
  }

  private isValidPassword(value: string): boolean {
    return /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$/.test(value)
  }
}
