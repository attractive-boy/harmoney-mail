package com.example.servers.category;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.example.servers.BaseResponse;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CategoryController {

    private final CategoryRepository repository;

    public CategoryController(CategoryRepository repository) {
        this.repository = repository;
    }

    @PostMapping("/category/list")
    public BaseResponse<Map<String, Object>> list() {
        List<Category> list = repository.findByLevelOrderByIdAsc(1);
        Map<String, Object> data = new HashMap<>();
        data.put("categoryList", list);
        return BaseResponse.success(data);
    }

    @PostMapping("/category/queryContentByCategory")
    public BaseResponse<Map<String, Object>> queryContentByCategory(@RequestBody Map<String, Object> body) {
        String code = body.get("code") == null ? null : body.get("code").toString();
        return buildResponseFromDatabase(code);
    }

    private BaseResponse<Map<String, Object>> buildResponseFromDatabase(String code) {
        String rootCode = (code == null || code.isEmpty()) ? "000" : code;
        String bannerUrl = repository.findByCode(rootCode)
                .map(Category::getBannerUrl)
                .orElse(null);

        List<Category> second = repository.findByParentCodeOrderByIdAsc(rootCode);
        if (second.isEmpty()) {
            second = repository.findByLevelOrderByIdAsc(2);
        }

        List<Map<String, Object>> secondCateList = new ArrayList<>();
        for (Category s : second) {
            Map<String, Object> secondItem = new HashMap<>();
            secondItem.put("categoryName", s.getName());
            secondItem.put("categoryCode", s.getCode());

            List<Category> third = repository.findByParentCodeOrderByIdAsc(s.getCode());
            List<Map<String, Object>> cateList = new ArrayList<>();
            for (Category t : third) {
                Map<String, Object> thirdItem = new HashMap<>();
                thirdItem.put("iconUrl", t.getIconUrl());
                thirdItem.put("categoryName", t.getName());
                thirdItem.put("categoryCode", t.getCode());
                cateList.add(thirdItem);
            }
            secondItem.put("cateList", cateList);
            secondCateList.add(secondItem);
        }

        Map<String, Object> data = new HashMap<>();
        data.put("bannerUrl", bannerUrl);
        data.put("secondCateList", secondCateList);
        return BaseResponse.success(data);
    }
}
