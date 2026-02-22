import { RequestUtil } from '@ohos/common'
import { EnvConfig } from '../constants/EnvConfig'

export interface OrderItem {
  id: number
  orderId: number
  goodsId: number
  goodsName: string
  goodsImage: string
  price: string
  quantity: number
  color: string
  size: string
}

export interface OrderInfo {
  id: number
  orderNo: string
  userId: string
  totalAmount: string
  status: string
  statusText: string
  createdAt: string
  paymentTime?: string
  shipmentTime?: string
  completedTime?: string
  receiverName: string
  receiverPhone: string
  receiverAddress: string
  remark?: string
  items: OrderItem[]
}

export interface OrderListResponse {
  orderList: OrderInfo[]
  totalPages: number
  totalElements: number
  currentPage: number
}

/**
 * 创建订单（从购物车已选商品）
 */
export const createOrder = async (params: {
  userId: string,
  receiverName?: string,
  receiverPhone?: string,
  receiverAddress?: string,
  remark?: string
}): Promise<{ orderId: number, orderNo: string, totalAmount: string }> => {
  const res = await RequestUtil.post<{ orderId: number, orderNo: string, totalAmount: string }>(
    `${EnvConfig.baseUrl}/order/create`,
    params
  )
  return res
}

/**
 * 查询订单列表
 */
export const queryOrderList = async (params: {
  userId: string,
  status?: string, // ALL, PENDING_PAYMENT, PENDING_SHIPMENT, PENDING_RECEIPT, COMPLETED, CANCELLED
  page?: number,
  size?: number
}): Promise<OrderListResponse> => {
  const res = await RequestUtil.post<OrderListResponse>(
    `${EnvConfig.baseUrl}/order/list`,
    {
      userId: params.userId,
      status: params.status || 'ALL',
      page: params.page || 0,
      size: params.size || 10
    }
  )
  return res
}

/**
 * 查询订单详情
 */
export const queryOrderDetail = async (userId: string, orderId: number): Promise<OrderInfo> => {
  const res = await RequestUtil.post<OrderInfo>(
    `${EnvConfig.baseUrl}/order/detail`,
    { userId, orderId }
  )
  return res
}

/**
 * 取消订单
 */
export const cancelOrder = async (userId: string, orderId: number): Promise<string> => {
  const res = await RequestUtil.post<string>(
    `${EnvConfig.baseUrl}/order/cancel`,
    { userId, orderId }
  )
  return res
}

/**
 * 确认收货
 */
export const confirmOrder = async (userId: string, orderId: number): Promise<string> => {
  const res = await RequestUtil.post<string>(
    `${EnvConfig.baseUrl}/order/confirm`,
    { userId, orderId }
  )
  return res
}

/**
 * 删除订单
 */
export const deleteOrder = async (userId: string, orderId: number): Promise<string> => {
  const res = await RequestUtil.post<string>(
    `${EnvConfig.baseUrl}/order/delete`,
    { userId, orderId }
  )
  return res
}

/**
 * 支付订单
 */
export const payOrder = async (userId: string, orderId: number): Promise<string> => {
  const res = await RequestUtil.post<string>(
    `${EnvConfig.baseUrl}/order/pay`,
    { userId, orderId }
  )
  return res
}
