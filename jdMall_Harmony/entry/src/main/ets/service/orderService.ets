import { RequestUtil, EnvConfig, isSuccess } from '@ohos/common'

// 请求参数接口
export interface CreateOrderParams {
  userId: string
  receiverName: string
  receiverPhone: string
  receiverAddress: string
  remark?: string
}

export interface CreateOrderResult {
  orderId: number
  orderNo: string
  totalAmount: string
}

export interface QueryOrderListParams {
  userId: string
  status?: string
  page?: number
  size?: number
}

export interface CancelOrderParams {
  userId: string
  orderId: number
}

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
export const createOrder = async (params: CreateOrderParams): Promise<CreateOrderResult> => {
  const res = await RequestUtil.post<CreateOrderResult>(
    `${EnvConfig.baseUrl}/order/create`,
    params
  )
  if (isSuccess(res.code)) {
    return res.data
  }
  throw new Error(res.msg || '创建订单失败')
}

/**
 * 查询订单列表
 */
export const queryOrderList = async (params: QueryOrderListParams): Promise<OrderListResponse> => {
  const res = await RequestUtil.post<OrderListResponse>(
    `${EnvConfig.baseUrl}/order/list`,
    {
      userId: params.userId,
      status: params.status || 'ALL',
      page: params.page || 0,
      size: params.size || 10
    }
  )
  if (isSuccess(res.code)) {
    return res.data
  }
  throw new Error(res.msg || '查询订单列表失败')
}

/**
 * 查询订单详情
 */
export const queryOrderDetail = async (userId: string, orderId: number): Promise<OrderInfo> => {
  const res = await RequestUtil.post<OrderInfo>(
    `${EnvConfig.baseUrl}/order/detail`,
    { userId, orderId }
  )
  if (isSuccess(res.code)) {
    return res.data
  }
  throw new Error(res.msg || '查询订单详情失败')
}

/**
 * 取消订单
 */
export const cancelOrder = async (userId: string, orderId: number): Promise<string> => {
  const res = await RequestUtil.post<string>(
    `${EnvConfig.baseUrl}/order/cancel`,
    { userId, orderId }
  )
  if (isSuccess(res.code)) {
    return res.data
  }
  throw new Error(res.msg || '取消订单失败')
}

/**
 * 确认收货
 */
export const confirmOrder = async (userId: string, orderId: number): Promise<string> => {
  const res = await RequestUtil.post<string>(
    `${EnvConfig.baseUrl}/order/confirm`,
    { userId, orderId }
  )
  if (isSuccess(res.code)) {
    return res.data
  }
  throw new Error(res.msg || '确认收货失败')
}

/**
 * 删除订单
 */
export const deleteOrder = async (userId: string, orderId: number): Promise<string> => {
  const res = await RequestUtil.post<string>(
    `${EnvConfig.baseUrl}/order/delete`,
    { userId, orderId }
  )
  if (isSuccess(res.code)) {
    return res.data
  }
  throw new Error(res.msg || '删除订单失败')
}

/**
 * 支付订单
 */
export const payOrder = async (userId: string, orderId: number): Promise<string> => {
  const res = await RequestUtil.post<string>(
    `${EnvConfig.baseUrl}/order/pay`,
    { userId, orderId }
  )
  if (isSuccess(res.code)) {
    return res.data
  }
  throw new Error(res.msg || '支付订单失败')
}
