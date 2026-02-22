package com.example.servers.home;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.example.servers.ApiMockRepository;
import com.example.servers.BaseResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HomePageController {

    private final HomeBannerRepository bannerRepository;
    private final HomeNineMenuRepository nineMenuRepository;
    private final HomeTabRepository tabRepository;
    private final ApiMockRepository apiMockRepository;

    public HomePageController(HomeBannerRepository bannerRepository,
                              HomeNineMenuRepository nineMenuRepository,
                              HomeTabRepository tabRepository,
                              ApiMockRepository apiMockRepository) {
        this.bannerRepository = bannerRepository;
        this.nineMenuRepository = nineMenuRepository;
        this.tabRepository = tabRepository;
        this.apiMockRepository = apiMockRepository;
    }

    @PostMapping("/home/queryHomePageInfo")
    public BaseResponse<Map<String, Object>> queryHomePageInfo() {
        List<HomeBanner> banners = bannerRepository.findAllByOrderByIdAsc();
        List<HomeNineMenu> nineMenus = nineMenuRepository.findAllByOrderByIdAsc();
        List<HomeTab> tabs = tabRepository.findAllByOrderByIdAsc();

        String adUrl = null;
        try {
            adUrl = apiMockRepository.findByPathAndMethod("/home/queryHomePageInfo", "POST")
                    .map(mock -> {
                        try {
                            ObjectMapper mapper = new ObjectMapper();
                            JsonNode root = mapper.readTree(mock.getResponseBody());
                            return root.path("data").path("adUrl").asText(null);
                        } catch (Exception e) {
                            return null;
                        }
                    })
                    .orElse(null);
        } catch (Exception ignored) {
            adUrl = null;
        }

        Map<String, Object> data = new HashMap<>();
        data.put("bannerList", banners);
        data.put("adUrl", adUrl);
        data.put("nineMenuList", nineMenus);
        data.put("tabList", tabs);
        return BaseResponse.success(data);
    }
}
