import { RequestUtil, EnvConfig, isSuccess } from '@ohos/common'

export interface CouponInfo {
  id: number
  name: string
  amount: number
  type: string          // NO_THRESHOLD | THRESHOLD
  minOrderAmount: number
  status: string        // UNUSED | USED | EXPIRED
  expireAt: string
}

export const queryCouponList = async (userId: string, status?: string): Promise<CouponInfo[]> => {
  const res = await RequestUtil.post<CouponInfo[]>(
    `${EnvConfig.baseUrl}/coupon/list`,
    status ? { userId: userId, status: status } : { userId: userId }
  )
  if (isSuccess(res.code)) {
    return res.data || []
  }
  throw new Error(res.msg || '查询红包列表失败')
}

export const receiveCoupon = async (userId: string): Promise<CouponInfo> => {
  const res = await RequestUtil.post<CouponInfo>(
    `${EnvConfig.baseUrl}/coupon/receive`,
    { userId: userId }
  )
  if (isSuccess(res.code)) {
    return res.data
  }
  throw new Error(res.msg || '领取红包失败')
}

export const queryAvailableCoupons = async (userId: string, orderAmount: number): Promise<CouponInfo[]> => {
  const res = await RequestUtil.post<CouponInfo[]>(
    `${EnvConfig.baseUrl}/coupon/available`,
    { userId: userId, orderAmount: orderAmount }
  )
  if (isSuccess(res.code)) {
    return res.data || []
  }
  throw new Error(res.msg || '查询可用红包失败')
}
