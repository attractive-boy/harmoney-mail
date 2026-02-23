import axios, { AxiosRequestConfig, AxiosResponse, InternalAxiosRequestConfig } from '@ohos/axios'
import router from '@ohos.router'
import { AppUtil, LogUtil, ToastUtil } from '@pura/harmony-utils'
import { BaseResponse } from './types'

const instance = axios.create({
  timeout: 30000, // 30秒超时
  headers: {
    'Content-Type': 'application/json;charset=UTF-8',
    'Accept': 'application/json'
  }
});

instance.defaults.headers.post['Access-Control-Allow-Origin'] = '*';
instance.defaults.headers.post['Access-Control-Allow-Credentials'] = 'true';

instance.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = AppStorage.get('userToken') as string
  if (token && config.headers) {
    config.headers['Authorization'] = `Bearer ${token}`
  }
  if (config.headers) {
    config.headers['Platform'] = 'harmony'
  }

  return config
},
  (error: ESObject) => {
    return Promise.reject(error)
  }
)

instance.interceptors.response.use((response: AxiosResponse) => {

  if (AppUtil.getAppProvisionType() == "debug" || AppUtil.debug()) {
    LogUtil.info([
      `--------- [axios] req url: ${response.config.url}`,
      `--------- [axios] req method: ${response.config.method}`,
      `--------- [axios] req data:${response.config.data}`,
      `--------- [axios] res data:`, response.data
    ])
  }

  // 业务成功处理
  if (isSuccess(response.data.code)) {
    return response.data
  }

  // 业务错误处理
  handleBusinessError(response.data.code, response.data.msg)
  return Promise.reject(response.data)
},
  (error: ESObject) => {
    if (error.code) {
      handleNetworkError(error.code)
    }
    if (error.response?.status) {
      handleHttpError(error.response.status)
    }
    return Promise.reject(error)
  }
)

// 错误处理函数
function handleBusinessError(code: number, message: string): void {
  switch (code) {
    case 401:
      // token过期，清除并跳转到登录页
      clearAuthState()
      redirectToLogin()
      break;
    case 403:
      // 权限不足
      console.error('权限不足:', message);
      break;
    default:
      console.error('业务错误:', message);
    ToastUtil.showShort(message)
  }
}

function handleNetworkError(code: string): void {
  const errorMap: Record<string, string> = {
    'ECONNABORTED': '请求超时，请检查网络连接',
    'ERR_NETWORK': '网络错误，请检查网络设置',
    'ERR_CANCEL': '请求已取消'
  };

  const message = errorMap[code] || `网络错误: ${code}`
  LogUtil.error('--------- [axios] network error:',message)
}

function handleHttpError(status: number): void {
  const errorMap: Record<number, string> = {
    400: '请求参数错误',
    401: '未授权，请重新登录',
    403: '拒绝访问',
    404: '请求资源不存在',
    500: '服务器内部错误',
    502: '网关错误',
    503: '服务不可用',
    504: '网关超时'
  };

  const message = errorMap[status] || `HTTP错误: ${status}`;
  LogUtil.error('--------- [axios] http error:',message)

  if (status === 401) {
    clearAuthState()
    redirectToLogin()
  }
}

function clearAuthState(): void {
  AppStorage.setOrCreate('userToken', '')
  AppStorage.setOrCreate('userAccount', '')
  AppStorage.setOrCreate('userDisplayName', '')
  AppStorage.setOrCreate('userPoints', 0)
  AppStorage.setOrCreate('userCredit', 0)
  AppStorage.setOrCreate('authRefreshTick', Date.now())
}

function redirectToLogin(): void {
  try {
    router.pushUrl({ url: 'pages/auth/login' })
  } catch (error) {
    LogUtil.error('--------- [axios] router push error:', JSON.stringify(error || {}))
  }
}

function isSuccess(code: string | number): boolean {
  return ['0', 0, '200', 200].includes(code);
}

function formatErrorMessage(err: ESObject): string {
  if (err.message) {
    return err.message
  }
  if (err.code === 'ECONNABORTED') {
    return '请求超时 - 检查网络连接或后端服务地址'
  }
  if (err.code === 'ERR_NETWORK') {
    return '网络错误 - 无法连接到服务器(192.168.5.10:8091)'
  }
  if (err.response?.status === 404) {
    return 'API不存在 - 检查后端服务'
  }
  if (err.response?.status === 500) {
    return '服务器出错'
  }
  return '网络错误: ' + (err.code || '未知错误')
}

class RequestUtil {
  static get<T = ESObject>(url: string, config?: AxiosRequestConfig): Promise<BaseResponse<T>> {
    return instance.get<T, BaseResponse<T>>(url, config)
      .then((res) => res)
      .catch((err: ESObject) => {
        const errorMsg = formatErrorMessage(err)
        return Promise.reject(new Error(errorMsg))
      });
  }

  static post<T = ESObject>(url: string, data?: ESObject, config?: AxiosRequestConfig): Promise<BaseResponse<T>> {
    return instance.post<T, BaseResponse<T>>(url, data, config)
      .then(res => res)
      .catch((err: ESObject) => {
        const errorMsg = formatErrorMessage(err)
        return Promise.reject(new Error(errorMsg))
      });
  }

  static put<T = ESObject>(url: string, data?: ESObject, config?: AxiosRequestConfig): Promise<BaseResponse<T>> {
    return instance.put<T, BaseResponse<T>>(url, data, config)
      .then(res => res)
      .catch((err: ESObject) => {
        const errorMsg = formatErrorMessage(err)
        return Promise.reject(new Error(errorMsg))
      });
  }

  static delete<T = ESObject>(url: string, config?: AxiosRequestConfig): Promise<BaseResponse<T>> {
    return instance.delete<T, BaseResponse<T>>(url, config)
      .then(res => res)
      .catch((err: ESObject) => {
        const errorMsg = formatErrorMessage(err)
        return Promise.reject(new Error(errorMsg))
      });
  }
}

export { RequestUtil, isSuccess }