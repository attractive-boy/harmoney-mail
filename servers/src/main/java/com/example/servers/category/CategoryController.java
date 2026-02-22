package com.example.servers.category;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.example.servers.ApiMock;
import com.example.servers.ApiMockRepository;
import com.example.servers.BaseResponse;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CategoryController {

    private final CategoryRepository repository;
    private final ApiMockRepository apiMockRepository;

    public CategoryController(CategoryRepository repository,
                              ApiMockRepository apiMockRepository) {
        this.repository = repository;
        this.apiMockRepository = apiMockRepository;
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
        return apiMockRepository.findByPathAndMethod("/category/queryContentByCategory", "POST")
                .map(this::buildResponseFromMock)
                .orElseGet(() -> buildResponseFromDatabase(code));
    }

    private BaseResponse<Map<String, Object>> buildResponseFromMock(ApiMock mock) {
        try {
            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(mock.getResponseBody());
            JsonNode dataNode = root.path("data");
            Map<String, Object> data = mapper.convertValue(dataNode, new TypeReference<Map<String, Object>>() {
            });
            return BaseResponse.success(data);
        } catch (Exception e) {
            return buildFallbackResponse();
        }
    }

    private BaseResponse<Map<String, Object>> buildResponseFromDatabase(String code) {
        List<Category> second = repository.findByParentCodeOrderByIdAsc(code);
        Map<String, Object> data = new HashMap<>();
        data.put("bannerUrl", null);
        data.put("secondCateList", second);
        return BaseResponse.success(data);
    }

    private BaseResponse<Map<String, Object>> buildFallbackResponse() {
        Map<String, Object> data = new HashMap<>();
        data.put("bannerUrl", null);
        data.put("secondCateList", List.of());
        return BaseResponse.success(data);
    }
}
