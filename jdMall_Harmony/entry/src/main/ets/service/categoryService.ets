import { isSuccess, RequestUtil, EnvConfig } from "@ohos/common"
import { ToastUtil, LogUtil } from '@pura/harmony-utils'

export const queryCategoryList = async () => {
  try {
    const res = await RequestUtil.post<LeftCategoryInfo>(`${EnvConfig.baseUrl}/category/list`)
    if (isSuccess(res.code) && res.msg) {
      ToastUtil.showToast(res.msg)
    }
    return res.data
  } catch (error) {
    LogUtil.error(['[categoryService] queryCategoryList error', JSON.stringify(error || {})])
    ToastUtil.showToast('分类列表加载失败')
    return {
      categoryList: []
    } as LeftCategoryInfo
  }
}

interface LeftCategoryInfo {
  categoryList: CategoryInfo[];
}

export interface CategoryInfo {
  name: string
  code: string
}

export const queryGroupCategoryList = async (code: string) => {
  try {
    const res =
      await RequestUtil.post<GroupCategoryListInfo>(`${EnvConfig.baseUrl}/category/queryContentByCategory`, { code })
    if (isSuccess(res.code) && res.msg) {
      ToastUtil.showToast(res.msg)
    }
    return res.data
  } catch (error) {
    LogUtil.error(['[categoryService] queryGroupCategoryList error', JSON.stringify(error || {})])
    ToastUtil.showToast('分类内容加载失败')
    return {
      bannerUrl: '',
      secondCateList: []
    } as GroupCategoryListInfo
  }
}

interface GroupCategoryListInfo {
  bannerUrl: string;
  secondCateList: SecondCategoryInfo[];
}


export interface SecondCategoryInfo {
  categoryName: string
  categoryCode: string
  cateList: ThirdCategoryInfo[]
}

export interface ThirdCategoryInfo {
  iconUrl: string
  categoryName: string
  categoryCode: string
}
