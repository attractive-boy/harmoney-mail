import { isSuccess, RequestUtil, EnvConfig } from "@ohos/common"
import { ToastUtil } from '@pura/harmony-utils'

export const queryCartGoodsList = async (userId: string) => {
  const res = await RequestUtil.post<StoreGoodsInfo[]>(`${EnvConfig.baseUrl}/cart/queryCartGoodsList`, { userId })
  if (isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  return res.data
}

export interface AddToCartPayload {
  userId: string
  goodsId: string
  num: number
  color?: string
  size?: string
  selected?: boolean
  saved?: boolean
  favorite?: boolean
  compare?: boolean
  storeCode?: string
  storeName?: string
}

export interface CartAddResult {
  itemId: number
  num: number
}

export const addToCart = async (payload: AddToCartPayload) => {
  const res = await RequestUtil.post<CartAddResult>(`${EnvConfig.baseUrl}/cart/add`, payload)
  if (isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  return res.data
}

export interface UpdateCartItemPayload {
  userId: string
  itemId: number
  num?: number
  selected?: boolean
  saved?: boolean
  favorite?: boolean
  compare?: boolean
}

export const updateCartItem = async (payload: UpdateCartItemPayload) => {
  const res = await RequestUtil.post<Record<string, never>>(`${EnvConfig.baseUrl}/cart/updateItem`, payload)
  if (isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  return res.data
}

export const removeCartItem = async (userId: string, itemId: number) => {
  const res = await RequestUtil.post<Record<string, never>>(`${EnvConfig.baseUrl}/cart/removeItem`, { userId, itemId })
  if (isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  return res.data
}

export const removeCartItems = async (userId: string, itemIds: number[]) => {
  const res = await RequestUtil.post<Record<string, never>>(`${EnvConfig.baseUrl}/cart/removeItems`, { userId, itemIds })
  if (isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  return res.data
}

export const selectStoreItems = async (userId: string, storeCode: string, selected: boolean) => {
  const res = await RequestUtil.post<Record<string, never>>(`${EnvConfig.baseUrl}/cart/selectStore`, { userId, storeCode, selected })
  if (isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  return res.data
}

export const selectAllItems = async (userId: string, selected: boolean) => {
  const res = await RequestUtil.post<Record<string, never>>(`${EnvConfig.baseUrl}/cart/selectAll`, { userId, selected })
  if (isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  return res.data
}

export const clearCart = async (userId: string) => {
  const res = await RequestUtil.post<Record<string, never>>(`${EnvConfig.baseUrl}/cart/clear`, { userId })
  if (isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  return res.data
}

export interface GoodsInfo {
  id: number
  code: string
  imgUrl: string
  description: string
  price: string
  color: string
  size: string
  num: number
  select: boolean
  saved: boolean
  favorite: boolean
  compare: boolean
}

export interface StoreGoodsInfo {
  storeName: string
  storeCode: string
  h5url: string
  select: boolean
  goodsList: GoodsInfo[]
}
