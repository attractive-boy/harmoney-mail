import { EnvConfig, isSuccess, RequestUtil } from '@ohos/common'
import { ToastUtil } from '@pura/harmony-utils'

export interface RegisterRequest {
  account: string
  password: string
}

export interface RegisterResponse {
  id: number
  email?: string
  phone?: string
  account?: string
  token?: string
  nickname?: string
  points?: number
  credit?: number
}

export const registerAccount = async (payload: RegisterRequest): Promise<RegisterResponse> => {
  const res = await RequestUtil.post<RegisterResponse>(`${EnvConfig.baseUrl}/common/register`, payload)
  if (isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  return res.data
}

export interface LoginRequest {
  account: string
  password: string
}

export interface LoginResponse {
  id: number
  email?: string
  phone?: string
  account?: string
  token?: string
  nickname?: string
  points?: number
  credit?: number
}

export const loginAccount = async (payload: LoginRequest): Promise<LoginResponse> => {
  const res = await RequestUtil.post<LoginResponse>(`${EnvConfig.baseUrl}/common/login`, payload)
  if (isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  return res.data
}

export interface ProfileResponse {
  id: number
  email?: string
  phone?: string
  account?: string
  nickname?: string
  points?: number
  credit?: number
}

export const fetchProfile = async (): Promise<ProfileResponse> => {
  const res = await RequestUtil.post<ProfileResponse>(`${EnvConfig.baseUrl}/common/profile`)
  if (isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  return res.data
}
