import { LogUtil, ToastUtil } from '@pura/harmony-utils'
import { EnvConfig } from '../constants/EnvConstants'
import { sleep } from '../utils'
import { isSuccess, RequestUtil } from '../utils/request'

export const queryGoodsListByPage = async(code: string, pageNo: number, pageSize: number, strategy?: string, sort?: string) => {
  const res = await RequestUtil.post<GoodsPageInfo>(`${EnvConfig.baseUrl}/common/queryGoodsListByPage`, { code, pageNo, pageSize, strategy, sort })
  if(isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  await sleep(pageNo == 1 ? 0 : 800)
  return res.data
}

export const searchGoods = async(keyword: string, pageNo: number = 1, pageSize: number = 15, sort?: string) => {
  const res = await RequestUtil.post<GoodsPageInfo>(`${EnvConfig.baseUrl}/common/searchGoods`, { keyword, pageNo, pageSize, sort })
  if(isSuccess(res.code) && res.msg) {
    ToastUtil.showToast(res.msg)
  }
  await sleep(pageNo == 1 ? 0 : 800)
  return res.data
}

export interface TrackEventPayload {
  goodsId: string
  event: string
}

export const trackEvent = async(payload: TrackEventPayload) => {
  try {
    await RequestUtil.post(`${EnvConfig.baseUrl}/common/trackEvent`, payload)
  } catch (error) {
  }
}

export interface GoodsPageInfo {
  goodsList: CommodityInfo[]
  totalCount: number
  totalPageCount: number
}

export interface CommodityInfo{
  id: string
  imgUrl: string
  description?: string
  tag?: string
  des1?: string
  des2?: string
  type: string
  price?: string
  h5url?: string
}