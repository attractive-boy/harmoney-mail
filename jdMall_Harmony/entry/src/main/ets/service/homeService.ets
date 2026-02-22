import { isSuccess, RequestUtil, EnvConfig } from "@ohos/common"
import { ToastUtil, LogUtil } from '@pura/harmony-utils'

export const queryHomePageInfo = async() => {
  try {
    const res = await RequestUtil.post<HomePageInfo>(`${EnvConfig.baseUrl}/home/queryHomePageInfo`)
    if (isSuccess(res.code) && res.msg) {
      ToastUtil.showToast(res.msg)
    }
    return res.data
  } catch (error) {
    LogUtil.error(['[homeService] queryHomePageInfo error', JSON.stringify(error || {})])
    ToastUtil.showToast('首页数据加载失败')
    return {
      bannerList: [],
      adUrl: '',
      nineMenuList: [],
      tabList: []
    } as HomePageInfo
  }
}

export interface BannerInfo{
  imgUrl: string
  type: string
}

export interface NineMenuInfo {
  menuIcon: string
  menuName: string
  menuCode: string
  h5url: string
}

export interface TabInfo {
  name: string
  code: string
}

export interface HomePageInfo {
  bannerList: BannerInfo[]
  adUrl: string
  nineMenuList: NineMenuInfo[]
  tabList: TabInfo[]
}
