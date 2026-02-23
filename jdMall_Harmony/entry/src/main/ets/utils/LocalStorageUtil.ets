import dataPreferences from '@ohos.data.preferences'
import { common } from '@kit.AbilityKit'

// 登录信息接口
export interface LoginInfo {
  token: string
  account: string
  displayName: string
  points: number
  credit: number
  loginTime: number
}

export interface TokenCheckInfo {
  token: string
  loginTime: number
}

// Preferences API接口定义
interface PreferencesApi {
  putSync(key: string, value: string | number | boolean): void
  getSync(key: string, defaultValue: string | number | boolean): string | number | boolean
  deleteSync(key: string): void
  flush(): Promise<void>
}

// 全局Preferences实例
let preferencesInstance: PreferencesApi | null = null
const PREFERENCE_NAME = 'auth_prefs'

// 登录信息持久化存储
export class AuthStorage {
  // 初始化Preferences - 需要先在主线程调用此方法
  static async init(context: Object): Promise<void> {
    if (preferencesInstance) return

    try {
      const prefs = (await dataPreferences.getPreferences(context as common.BaseContext, PREFERENCE_NAME)) as PreferencesApi
      preferencesInstance = prefs
    } catch (err) {
      console.error('Init AuthStorage failed:', err)
      throw new Error('Init AuthStorage failed')
    }
  }

  // 登录信息持久化存储
  static async saveLoginInfo(data: LoginInfo): Promise<void> {
    if (!preferencesInstance) {
      throw new Error('AuthStorage not initialized')
    }

    try {
      preferencesInstance.putSync('userToken', data.token)
      preferencesInstance.putSync('userAccount', data.account)
      preferencesInstance.putSync('userDisplayName', data.displayName)
      preferencesInstance.putSync('userPoints', data.points)
      preferencesInstance.putSync('userCredit', data.credit)
      preferencesInstance.putSync('loginTime', Date.now())
      await preferencesInstance.flush()
    } catch (err) {
      console.error('Save login info failed:', err)
      throw new Error('Save login info failed')
    }
  }

  // 读取登录信息
  static async getLoginInfo(): Promise<LoginInfo | null> {
    if (!preferencesInstance) {
      throw new Error('AuthStorage not initialized')
    }

    try {
      const token = preferencesInstance.getSync('userToken', '') as string
      if (!token) return null

      return {
        token,
        account: preferencesInstance.getSync('userAccount', '') as string,
        displayName: preferencesInstance.getSync('userDisplayName', '') as string,
        points: preferencesInstance.getSync('userPoints', 0) as number,
        credit: preferencesInstance.getSync('userCredit', 0) as number,
        loginTime: preferencesInstance.getSync('loginTime', 0) as number
      }
    } catch (err) {
      console.error('Get login info failed:', err)
      return null
    }
  }

  // 清除登录信息（注销）
  static async clearLoginInfo(): Promise<void> {
    if (!preferencesInstance) {
      throw new Error('AuthStorage not initialized')
    }

    try {
      preferencesInstance.deleteSync('userToken')
      preferencesInstance.deleteSync('userAccount')
      preferencesInstance.deleteSync('userDisplayName')
      preferencesInstance.deleteSync('userPoints')
      preferencesInstance.deleteSync('userCredit')
      preferencesInstance.deleteSync('loginTime')
      await preferencesInstance.flush()
    } catch (err) {
      console.error('Clear login info failed:', err)
      throw new Error('Clear login info failed')
    }
  }

  // 检查token是否有效
  static isTokenValid(loginInfo: TokenCheckInfo): boolean {
    if (!loginInfo.token) return false
    const EXPIRY_TIME = 30 * 24 * 60 * 60 * 1000
    const elapsed = Date.now() - loginInfo.loginTime
    return elapsed < EXPIRY_TIME
  }
}

export default AuthStorage
