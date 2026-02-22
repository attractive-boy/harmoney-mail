import { EnvConfig, isSuccess, RequestUtil } from '@ohos/common'
import { ToastUtil } from '@pura/harmony-utils'

export interface GoodsDetailInfo {
  goods: GoodsInfo
}

export interface GoodsInfo {
  id: number
  imgUrl: string
  description: string
  price: string
  tag?: string
  des1?: string
  des2?: string
  storeName?: string
  storeRating?: number
  storeLevel?: string
  shipping?: string
  salesCount?: number
  rating?: number
}

export interface StoreGoodsInfo {
  goodsList: GoodsInfo[]
}

export const queryGoodsDetail = async (goodsId: string): Promise<GoodsDetailInfo> => {
  const res = await RequestUtil.post<GoodsDetailInfo>(`${EnvConfig.baseUrl}/detail/queryGoodsDetail`, { goodsId })
  if (isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  return res.data
}

export const queryStoreGoodsList = async (goodsId: string): Promise<StoreGoodsInfo> => {
  const res = await RequestUtil.post<StoreGoodsInfo>(`${EnvConfig.baseUrl}/detail/queryStoreGoodsList`, { goodsId })
  if (isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  return res.data
}
