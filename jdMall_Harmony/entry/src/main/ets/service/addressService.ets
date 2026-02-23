import { RequestUtil, EnvConfig, isSuccess } from '@ohos/common'

export interface AddressInfo {
  id: number
  userId: string
  name: string
  phone: string
  region: string
  detail: string
  isDefault: boolean
  label: string
}

export interface AddressParams {
  userId: string
  name: string
  phone: string
  region: string
  detail: string
  isDefault: boolean
  label?: string
}

export interface UpdateAddressParams extends AddressParams {
  id: number
}

export const queryAddressList = async (userId: string): Promise<AddressInfo[]> => {
  const res = await RequestUtil.post<AddressInfo[]>(
    `${EnvConfig.baseUrl}/address/list`,
    { userId: userId }
  )
  if (isSuccess(res.code)) {
    return res.data || []
  }
  throw new Error(res.msg || '查询地址列表失败')
}

export const addAddress = async (params: AddressParams): Promise<AddressInfo> => {
  const res = await RequestUtil.post<AddressInfo>(
    `${EnvConfig.baseUrl}/address/add`,
    params
  )
  if (isSuccess(res.code)) {
    return res.data
  }
  throw new Error(res.msg || '新增地址失败')
}

export const updateAddress = async (params: UpdateAddressParams): Promise<AddressInfo> => {
  const res = await RequestUtil.post<AddressInfo>(
    `${EnvConfig.baseUrl}/address/update`,
    params
  )
  if (isSuccess(res.code)) {
    return res.data
  }
  throw new Error(res.msg || '更新地址失败')
}

export const deleteAddress = async (userId: string, id: number): Promise<void> => {
  const res = await RequestUtil.post<string>(
    `${EnvConfig.baseUrl}/address/delete`,
    { userId: userId, id: id }
  )
  if (!isSuccess(res.code)) {
    throw new Error(res.msg || '删除地址失败')
  }
}

export const setDefaultAddress = async (userId: string, id: number): Promise<void> => {
  const res = await RequestUtil.post<string>(
    `${EnvConfig.baseUrl}/address/setDefault`,
    { userId: userId, id: id }
  )
  if (!isSuccess(res.code)) {
    throw new Error(res.msg || '设置默认地址失败')
  }
}
