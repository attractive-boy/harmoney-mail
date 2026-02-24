import { RequestUtil, EnvConfig, isSuccess } from '@ohos/common'

export interface ArticleInfo {
  id: number
  title: string
  summary: string
  imageUrl: string
  category: string   // INDUSTRY | TECH
  source: string
  viewCount: number
  publishedAt: string
}

export interface ArticleDetail extends ArticleInfo {
  content: string
}

export interface ArticleListResult {
  list: ArticleInfo[]
  totalPages: number
  totalElements: number
  currentPage: number
  hasMore: boolean
}

export interface QueryNewsParams {
  category?: string
  page?: number
  size?: number
}

export const queryNewsList = async (params: QueryNewsParams): Promise<ArticleListResult> => {
  const res = await RequestUtil.post<ArticleListResult>(
    `${EnvConfig.baseUrl}/news/list`,
    {
      category: params.category || 'ALL',
      page: params.page || 0,
      size: params.size || 10
    }
  )
  if (isSuccess(res.code)) {
    return res.data
  }
  return { list: [], totalPages: 0, totalElements: 0, currentPage: 0, hasMore: false }
}

export const queryNewsDetail = async (id: number): Promise<ArticleDetail> => {
  const res = await RequestUtil.post<ArticleDetail>(
    `${EnvConfig.baseUrl}/news/detail`,
    { id: id }
  )
  if (isSuccess(res.code)) {
    return res.data
  }
  return res.data
}
