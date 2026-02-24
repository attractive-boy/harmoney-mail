package com.example.servers.news;

import com.example.servers.BaseResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.*;

@RestController
public class ArticleController {

    private final ArticleRepository articleRepository;

    public ArticleController(ArticleRepository articleRepository) {
        this.articleRepository = articleRepository;
    }

    @PostMapping("/news/list")
    @Transactional
    public BaseResponse<Map<String, Object>> listArticles(@RequestBody Map<String, Object> body) {
        // seed demo data on first call
        if (articleRepository.count() == 0) {
            seedDemoArticles();
        }

        String category = getStringValue(body, "category", null);
        int page = getIntValue(body, "page", 0);
        int size = getIntValue(body, "size", 10);

        Pageable pageable = PageRequest.of(page, size, Sort.by("publishedAt").descending());

        Page<Article> pageResult;
        if (category != null && !category.isEmpty() && !category.equals("ALL")) {
            pageResult = articleRepository.findByCategory(category, pageable);
        } else {
            pageResult = articleRepository.findAllByOrderByPublishedAtDesc(pageable);
        }

        List<Map<String, Object>> list = new ArrayList<>();
        for (Article a : pageResult.getContent()) {
            list.add(articleToListMap(a));
        }

        Map<String, Object> result = new HashMap<>();
        result.put("list", list);
        result.put("totalPages", pageResult.getTotalPages());
        result.put("totalElements", pageResult.getTotalElements());
        result.put("currentPage", page);
        result.put("hasMore", page + 1 < pageResult.getTotalPages());

        return BaseResponse.success(result);
    }

    @PostMapping("/news/detail")
    @Transactional
    public BaseResponse<Map<String, Object>> getArticle(@RequestBody Map<String, Object> body) {
        Long id = getLongValue(body, "id");
        if (id == null) {
            return new BaseResponse<>("400", "缺少资讯id", null);
        }
        Optional<Article> opt = articleRepository.findById(id);
        if (opt.isEmpty()) {
            return new BaseResponse<>("404", "资讯不存在", null);
        }
        Article article = opt.get();
        article.setViewCount(article.getViewCount() + 1);
        articleRepository.save(article);
        return BaseResponse.success(articleToDetailMap(article));
    }

    // ─── helpers ────────────────────────────────────────────────────────────

    private Map<String, Object> articleToListMap(Article a) {
        Map<String, Object> m = new HashMap<>();
        m.put("id", a.getId());
        m.put("title", a.getTitle());
        m.put("summary", a.getSummary());
        m.put("imageUrl", a.getImageUrl());
        m.put("category", a.getCategory());
        m.put("source", a.getSource());
        m.put("viewCount", a.getViewCount());
        m.put("publishedAt", a.getPublishedAt() != null ? a.getPublishedAt().toString().substring(0, 10) : "");
        return m;
    }

    private Map<String, Object> articleToDetailMap(Article a) {
        Map<String, Object> m = articleToListMap(a);
        m.put("content", a.getContent());
        return m;
    }

    private String getStringValue(Map<String, Object> body, String key, String defaultVal) {
        Object val = body.get(key);
        return val != null ? val.toString() : defaultVal;
    }

    private int getIntValue(Map<String, Object> body, String key, int defaultVal) {
        Object val = body.get(key);
        if (val == null) return defaultVal;
        try { return Integer.parseInt(val.toString()); } catch (NumberFormatException e) { return defaultVal; }
    }

    private Long getLongValue(Map<String, Object> body, String key) {
        Object val = body.get(key);
        if (val == null) return null;
        try { return Long.parseLong(val.toString()); } catch (NumberFormatException e) { return null; }
    }

    @Transactional
    protected void seedDemoArticles() {
        String[][] data = {
            {"INDUSTRY", "2025年智能穿戴设备市场规模突破5000亿",
             "据市场研究机构最新报告显示，2025年全球智能穿戴设备市场规模预计突破5000亿元，同比增长28%，健康监测和运动追踪类产品成为主要增长驱动力。",
             "随着老龄化社会的到来和全民健康意识的提升，智能穿戴设备正在从消费电子走向医疗健康领域……\n\n主要趋势包括：\n1. 血糖无创检测功能商业化落地\n2. 心电监测精度达到医疗级别\n3. 睡眠分析算法持续优化\n4. 国产品牌市场份额同比提升15个百分点\n\n分析师认为，未来3年，搭载AI健康管理功能的穿戴设备将成为市场主流，预计渗透率从18%增长至45%。",
             "https://picsum.photos/seed/article1/400/240", "行业观察"},
            {"TECH", "HarmonyOS NEXT 操作系统深度解析",
             "华为HarmonyOS NEXT正式发布，全面采用自研内核，彻底与Android兼容层说再见，系统性能提升40%，流畅度大幅改善，开发者生态加速构建。",
             "HarmonyOS NEXT是华为自主研发的下一代操作系统，采用全新的微内核架构……\n\n核心技术亮点：\n\n▌微内核架构\n仅保留最精简的内核功能，大量系统服务运行在用户态，安全隔离级别显著提升，即使系统服务崩溃也不会影响整体稳定性。\n\n▌分布式软总线 2.0\n全新升级的跨设备通信框架，延迟降低60%，支持实时音视频流在多设备间无缝传输。\n\n▌ArkTS语言体系\n基于TypeScript扩展的应用开发语言，提供严格的静态类型检查，编译期优化大幅提升运行时性能。\n\n▌自研图形栈\n全自研高性能渲染引擎，UI刷新延迟从16ms降低至8ms，动画流畅度媲美顶级商业系统。",
             "https://picsum.photos/seed/article2/400/240", "技术前沿"},
            {"INDUSTRY", "京东双11大屏电视品类销量增长分析",
             "京东今年双11大屏电视品类销售额同比增长35%，100英寸以上超大屏电视首次进入销量TOP10，Mini LED技术成为消费者选购核心考量因素。",
             "京东双11数据显示，2025年超大屏电视市场呈现爆发式增长……\n\n数据亮点：\n- 65英寸以上电视占总销量比例首次超过50%\n- 100英寸+超大屏销量同比增长320%\n- Mini LED背光方案渗透率达42%\n- 国产品牌占据前五名中的四席\n\n消费者洞察：\n购买超大屏电视的用户中，72%将其用于观看体育赛事，58%与家庭影院系统配合使用，年龄分布呈现年轻化趋势，25-35岁用户占比提升至38%。",
             "https://picsum.photos/seed/article3/400/240", "市场数据"},
            {"TECH", "端侧大模型：AI手机的下一个赛点",
             "手机厂商纷纷布局端侧大模型，在不依赖云端的情况下实现AI推理，保护用户隐私的同时降低延迟，智能助手、拍照优化、实时翻译等场景迎来质的飞跃。",
             "端侧AI正在成为旗舰手机的标配功能……\n\n技术路线对比：\n\n苹果Apple Intelligence：\n- 采用NPU+CPU混合推理架构\n- 3B参数量模型本地运行\n- 与云端Private Cloud Compute无缝切换\n\n华为盘古模型：\n- 专为移动端优化的轻量化架构\n- 支持语文、代码、多模态三种模式\n- 麒麟芯片深度协同优化\n\n高通Snapdragon AI：\n- 开放NPU SDK给第三方开发者\n- 支持主流开源大模型格式\n- 推理效率业界领先\n\n行业预测：2026年出货的旗舰手机将100%搭载本地AI大模型能力，中端机型渗透率也将超过65%。",
             "https://picsum.photos/seed/article4/400/240", "AI前沿"},
            {"INDUSTRY", "新能源汽车智能座舱硬件升级趋势报告",
             "2025年新能源汽车智能座舱迎来硬件大升级，高通8295芯片成为旗舰标配，高清大屏、AR-HUD、全舱语音交互三大功能加速普及，用户体验显著改善。",
             "智能座舱正在成为消费者购车决策的重要因素……\n\n硬件配置趋势：\n\n计算平台：\n高通骁龙8295成为旗舰座舱标配，算力达到30TOPS，支持多屏多任务流畅运行，相比上一代提升200%。\n\n显示系统：\n主驾15.6英寸以上曲面屏渗透率超过60%，三联屏、环绕屏设计逐步量产，OLED材质占比提升至25%。\n\nAR-HUD：\nAR增强现实抬头显示系统量产成本大幅下降，年销量突破200万套，导航、预警信息投影在前挡风玻璃上，安全性大幅提升。",
             "https://picsum.photos/seed/article5/400/240", "行业报告"},
            {"TECH", "国产芯片突破：龙芯3A6000台式机实测",
             "龙芯3A6000处理器综合性能达到Intel第十代酷睿同级水平，在办公、编程、轻度图形处理场景表现稳定，国产软硬件生态进一步完善，信创市场加速替代。",
             "龙芯3A6000是目前性能最强的国产桌面处理器……\n\n规格参数：\n- 制程：12nm LoongArch指令集\n- 核心数：4核心4线程\n- 主频：2.5GHz（睿频3.0GHz）\n- 三级缓存：16MB\n- 内存支持：DDR4-3200双通道\n\n性能测试结果：\n\nSPEC CPU 2017测试中，整数性能达到Intel Core i5-10400的95%，浮点性能约为85%，在国产芯片中处于领先水平。\n\n生态进展：\n- WPS、钉钉、腾讯会议均已原生适配\n- 主流Linux发行版完整支持\n- 统信UOS、麒麟OS深度优化\n- 龙芯授权开发板生态持续扩展",
             "https://picsum.photos/seed/article6/400/240", "深度评测"},
        };

        LocalDateTime base = LocalDateTime.now().minusDays(1);
        for (int i = 0; i < data.length; i++) {
            Article a = new Article();
            a.setCategory(data[i][0]);
            a.setTitle(data[i][1]);
            a.setSummary(data[i][2]);
            a.setContent(data[i][3]);
            a.setImageUrl(data[i][4]);
            a.setSource(data[i][5]);
            a.setViewCount((long) (100 + i * 137 % 900));
            a.setPublishedAt(base.minusHours(i * 6L));
            articleRepository.save(a);
        }
    }
}
