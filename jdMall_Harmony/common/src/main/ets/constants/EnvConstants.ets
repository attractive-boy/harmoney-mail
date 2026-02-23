
export class EnvConfig {
  // 后端服务地址配置
  // 如果订单加载失败，根据运行环境调整：
  // - 真机（同局域网）：http://192.168.5.10:8091
  // - 模拟器：http://10.0.2.2:8091 或 http://127.0.0.1:8091 (需在模拟器设置中配置)
  static readonly baseUrl: string = 'http://192.168.5.10:8091'
}
