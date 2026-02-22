package com.example.servers.home;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.example.servers.BaseResponse;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HomePageController {

    private final HomeBannerRepository bannerRepository;
    private final HomeNineMenuRepository nineMenuRepository;
    private final HomeTabRepository tabRepository;
    private final HomeConfigRepository homeConfigRepository;

    public HomePageController(HomeBannerRepository bannerRepository,
                              HomeNineMenuRepository nineMenuRepository,
                              HomeTabRepository tabRepository,
                              HomeConfigRepository homeConfigRepository) {
        this.bannerRepository = bannerRepository;
        this.nineMenuRepository = nineMenuRepository;
        this.tabRepository = tabRepository;
        this.homeConfigRepository = homeConfigRepository;
    }

    @PostMapping("/home/queryHomePageInfo")
    public BaseResponse<Map<String, Object>> queryHomePageInfo() {
        List<HomeBanner> banners = bannerRepository.findAllByOrderByIdAsc();
        List<HomeNineMenu> nineMenus = nineMenuRepository.findAllByOrderByIdAsc();
        List<HomeTab> tabs = tabRepository.findAllByOrderByIdAsc();

        String adUrl = homeConfigRepository.findTopByOrderByIdAsc()
                .map(HomeConfig::getAdUrl)
                .orElse(null);

        Map<String, Object> data = new HashMap<>();
        data.put("bannerList", banners);
        data.put("adUrl", adUrl);
        data.put("nineMenuList", nineMenus);
        data.put("tabList", tabs);
        return BaseResponse.success(data);
    }
}
