package com.example.servers.goods;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.example.servers.BaseResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GoodsController {

    private final GoodsRepository repository;

    public GoodsController(GoodsRepository repository) {
        this.repository = repository;
    }

    @PostMapping("/common/queryGoodsListByPage")
    public BaseResponse<Map<String, Object>> queryGoodsListByPage(@RequestBody Map<String, Object> body) {
        String code = body.get("code") == null ? null : body.get("code").toString();
        int pageNo = body.get("pageNo") instanceof Number ? ((Number) body.get("pageNo")).intValue() : 1;
        int pageSize = body.get("pageSize") instanceof Number ? ((Number) body.get("pageSize")).intValue() : 15;
        String strategy = body.get("strategy") == null ? null : body.get("strategy").toString();
        String sort = body.get("sort") == null ? null : body.get("sort").toString();
        PageRequest pageable = PageRequest.of(Math.max(pageNo - 1, 0), pageSize, resolveSort(strategy, sort));
        Page<Goods> page;
        
        if (code == null || code.isEmpty()) {
            // 首页：type=2 的商品排在最前面
            page = repository.findAllWithType2First(PageRequest.of(Math.max(pageNo - 1, 0), pageSize));
        } else {
            // 分类页：过滤掉 type=2 的推广商品
            page = repository.findByCategoryCodeAndTypeNot(code, "2", pageable);
            if (page.getTotalElements() == 0) {
                // 如果该分类没有商品，显示其他分类的普通商品（仍过滤 type=2）
                page = repository.findByTypeNot("2", pageable);
            }
        }
        
        Map<String, Object> data = new HashMap<>();
        List<Goods> list = page.getContent();
        data.put("goodsList", list);
        data.put("totalCount", page.getTotalElements());
        data.put("totalPageCount", page.getTotalPages());
        return BaseResponse.success(data);
    }

    private Sort resolveSort(String strategy, String sort) {
        // 如果有sort参数，优先使用sort参数
        if (sort != null && !sort.isEmpty()) {
            switch (sort) {
                case "priceAsc":
                    return Sort.by(Sort.Order.asc("price"));
                case "priceDesc":
                    return Sort.by(Sort.Order.desc("price"));
                case "salesDesc":
                    return Sort.by(Sort.Order.desc("salesCount"));
                case "ratingDesc":
                    return Sort.by(Sort.Order.desc("rating"));
                case "newArrival":
                    return Sort.by(Sort.Order.desc("createdAt"));
                default:
                    return Sort.by(Sort.Order.desc("salesCount"));
            }
        }
        
        // 否则使用strategy策略排序
        if (strategy == null || strategy.isEmpty() || "smart".equals(strategy)) {
            return Sort.by(Sort.Order.desc("recommend"),
                    Sort.Order.desc("salesCount"),
                    Sort.Order.desc("rating"),
                    Sort.Order.desc("createdAt"));
        }
        switch (strategy) {
            case "topSales":
                return Sort.by(Sort.Order.desc("salesCount"));
            case "topRated":
                return Sort.by(Sort.Order.desc("rating"));
            case "newArrival":
                return Sort.by(Sort.Order.desc("createdAt"));
            default:
                return Sort.by(Sort.Order.desc("salesCount"));
        }
    }

    @PostMapping("/common/searchGoods")
    public BaseResponse<Map<String, Object>> searchGoods(@RequestBody Map<String, Object> body) {
        String keyword = body.get("keyword") == null ? "" : body.get("keyword").toString();
        int pageNo = body.get("pageNo") instanceof Number ? ((Number) body.get("pageNo")).intValue() : 1;
        int pageSize = body.get("pageSize") instanceof Number ? ((Number) body.get("pageSize")).intValue() : 15;
        String sort = body.get("sort") == null ? null : body.get("sort").toString();
        
        if (keyword == null || keyword.trim().isEmpty()) {
            return new BaseResponse<>("400", "搜索词不能为空", null);
        }
        
        PageRequest pageable = PageRequest.of(Math.max(pageNo - 1, 0), pageSize, resolveSort(null, sort));
        // 搜索结果排除 type=2 的推广商品
        Page<Goods> page = repository.searchByKeywordExcludeType2(keyword.trim(), pageable);
        
        Map<String, Object> data = new HashMap<>();
        List<Goods> list = page.getContent();
        data.put("goodsList", list);
        data.put("totalCount", page.getTotalElements());
        data.put("totalPageCount", page.getTotalPages());
        return BaseResponse.success(data);
    }
}
