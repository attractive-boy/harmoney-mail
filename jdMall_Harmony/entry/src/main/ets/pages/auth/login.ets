import router from '@ohos.router'
import { StyleConstants } from '@ohos/common'
import { ToastUtil } from '@pura/harmony-utils'
import { loginAccount } from '../../service/authService'
import AuthStorage, { LoginInfo } from '../../utils/LocalStorageUtil'

@Entry
@Component
export struct Login {
  @State account: string = ''
  @State password: string = ''
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
      Text('登录')
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
      Text('手机号或邮箱登录')
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

        TextInput({ text: this.password, placeholder: '请输入密码' })
          .height(44)
          .fontSize(14)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .padding({ left: 12, right: 12 })
          .type(InputType.Password)
          .margin({ top: 12 })
          .onChange((value: string) => this.password = value)
      }
      .width('100%')

      Button() {
        Text(this.isSubmitting ? '登录中...' : '登录')
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

      Text('没有账号？去注册')
        .fontSize(12)
        .fontColor('#666666')
        .margin({ top: 12 })
        .onClick(() => router.pushUrl({ url: 'pages/auth/register' }))
    }
    .width('calc(100% - 40vp)')
    .margin({ left: 20, right: 20, top: 10 })
  }

  private async onSubmit(): Promise<void> {
    const account = this.account.trim()
    const password = this.password

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

    this.isSubmitting = true
    try {
      const data = await loginAccount({ account, password })
      const token = data.token || ''
      const displayName = data.nickname || data.account || account
      const points = data.points ?? 0
      const credit = data.credit ?? 0

      // 保存到AppStorage（用于当前会话）
      AppStorage.setOrCreate('userToken', token)
      AppStorage.setOrCreate('userAccount', data.account || account)
      AppStorage.setOrCreate('userDisplayName', displayName)
      AppStorage.setOrCreate('userPoints', points)
      AppStorage.setOrCreate('userCredit', credit)
      AppStorage.setOrCreate('authRefreshTick', Date.now())

      // 保存到本地存储（用于下次启动自动登录）
      const loginInfo: LoginInfo = {
        token,
        account: data.account || account,
        displayName,
        points,
        credit,
        loginTime: Date.now()
      }
      await AuthStorage.saveLoginInfo(loginInfo)

      ToastUtil.showToast('登录成功')
      router.back()
    } catch (error) {
      ToastUtil.showToast('登录失败，请检查账号或密码')
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
}
