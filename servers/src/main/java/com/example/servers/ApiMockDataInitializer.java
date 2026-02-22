package com.example.servers;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Random;

import com.example.servers.category.Category;
import com.example.servers.category.CategoryRepository;
import com.example.servers.goods.Goods;
import com.example.servers.goods.GoodsRepository;
import com.example.servers.home.HomeBanner;
import com.example.servers.home.HomeBannerRepository;
import com.example.servers.home.HomeConfig;
import com.example.servers.home.HomeConfigRepository;
import com.example.servers.home.HomeNineMenu;
import com.example.servers.home.HomeNineMenuRepository;
import com.example.servers.home.HomeTab;
import com.example.servers.home.HomeTabRepository;
import com.example.servers.mine.MineFunction;
import com.example.servers.mine.MineFunctionRepository;
import com.example.servers.mine.MineTab;
import com.example.servers.mine.MineTabRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class ApiMockDataInitializer implements CommandLineRunner {

    private final HomeBannerRepository homeBannerRepository;
    private final HomeConfigRepository homeConfigRepository;
    private final HomeNineMenuRepository homeNineMenuRepository;
    private final HomeTabRepository homeTabRepository;
    private final CategoryRepository categoryRepository;
    private final GoodsRepository goodsRepository;
    private final MineFunctionRepository mineFunctionRepository;
    private final MineTabRepository mineTabRepository;
    private final Random random = new Random();

    public ApiMockDataInitializer(HomeBannerRepository homeBannerRepository,
                                  HomeConfigRepository homeConfigRepository,
                                  HomeNineMenuRepository homeNineMenuRepository,
                                  HomeTabRepository homeTabRepository,
                                  CategoryRepository categoryRepository,
                                  GoodsRepository goodsRepository,
                                  MineFunctionRepository mineFunctionRepository,
                                  MineTabRepository mineTabRepository) {
        this.homeBannerRepository = homeBannerRepository;
        this.homeConfigRepository = homeConfigRepository;
        this.homeNineMenuRepository = homeNineMenuRepository;
        this.homeTabRepository = homeTabRepository;
        this.categoryRepository = categoryRepository;
        this.goodsRepository = goodsRepository;
        this.mineFunctionRepository = mineFunctionRepository;
        this.mineTabRepository = mineTabRepository;
    }

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        // 检查数据库是否已有数据
        if (goodsRepository.count() > 0 && homeBannerRepository.count() > 0) {
            System.out.println("数据库已有数据，跳过初始化");
            return;
        }

        // 尝试从 mock_server 导入（如果存在）
        Path apiRoot = Paths.get("../jdMall_Harmony/mock_server/api").toAbsolutePath().normalize();
        if (Files.exists(apiRoot)) {
            System.out.println("从 mock_server 导入数据...");
            ObjectMapper mapper = new ObjectMapper();
            importHome(apiRoot, mapper);
            importCategory(apiRoot, mapper);
            importCategoryContent(apiRoot, mapper);
            importGoods(apiRoot, mapper);
            backfillGoodsStats();
            importMine(apiRoot, mapper);
            importMaybeLike(apiRoot, mapper);
        } else {
            // mock_server 不存在时，创建基础示例数据
            System.out.println("mock_server 目录不存在，创建基础示例数据...");
            createBasicData();
        }
    }

    private void createBasicData() {
        // 创建首页 Banner
        if (homeBannerRepository.count() == 0) {
            HomeBanner banner1 = new HomeBanner();
            banner1.setImgUrl("https://via.placeholder.com/750x300/EA3931/FFFFFF?text=Welcome");
            banner1.setType("1");
            homeBannerRepository.save(banner1);

            HomeBanner banner2 = new HomeBanner();
            banner2.setImgUrl("https://via.placeholder.com/750x300/FF6B6B/FFFFFF?text=Sale");
            banner2.setType("1");
            homeBannerRepository.save(banner2);
        }

        // 创建九宫格菜单
        if (homeNineMenuRepository.count() == 0) {
            String[] menuItems = {"手机", "电脑", "家电", "服装", "美妆", "食品", "图书", "运动", "家居"};
            for (int i = 0; i < menuItems.length; i++) {
                HomeNineMenu menu = new HomeNineMenu();
                menu.setMenuName(menuItems[i]);
                menu.setMenuIcon("https://via.placeholder.com/100/EA3931/FFFFFF?text=" + menuItems[i]);
                menu.setMenuCode("menu_" + i);
                homeNineMenuRepository.save(menu);
            }
        }

        // 创建首页 Tab
        if (homeTabRepository.count() == 0) {
            String[] tabs = {"推荐", "手机", "电脑", "家电", "服装"};
            for (String tab : tabs) {
                HomeTab homeTab = new HomeTab();
                homeTab.setName(tab);
                homeTab.setCode(tab.toLowerCase());
                homeTabRepository.save(homeTab);
            }
        }

        // 创建分类
        if (categoryRepository.count() == 0) {
            String[] categories = {"手机通讯", "电脑数码", "家用电器", "服饰鞋包", "美妆个护"};
            for (int i = 0; i < categories.length; i++) {
                Category category = new Category();
                category.setName(categories[i]);
                category.setCode("cat_" + i);
                category.setIconUrl("https://via.placeholder.com/100/EA3931/FFFFFF?text=" + categories[i]);
                categoryRepository.save(category);
            }
        }

        // 创建示例商品
        if (goodsRepository.count() == 0) {
            Random rand = new Random();
            String[] products = {
                "华为 Mate 60 Pro 5G手机", "Apple iPhone 15 Pro Max", "小米14 Ultra 旗舰手机",
                "ThinkPad X1 Carbon 商务笔记本", "MacBook Pro 16英寸", "戴尔 XPS 13",
                "海尔冰箱 双开门", "美的空调 变频节能", "格力空调 静音款",
                "耐克运动鞋 男款", "阿迪达斯 跑步鞋", "李宁运动服套装"
            };
            
            for (int i = 0; i < products.length; i++) {
                Goods goods = new Goods();
                goods.setCategoryCode("cat_" + (i % 5));
                goods.setDescription(products[i]);
                goods.setImgUrl("https://via.placeholder.com/400/EA3931/FFFFFF?text=Product+" + (i + 1));
                goods.setPrice(String.valueOf((rand.nextInt(50) + 10) * 100)); // 1000-6000
                goods.setType(String.valueOf(i % 5 + 1));
                goods.setSalesCount(100 + rand.nextInt(5000));
                goods.setRating(3.5 + rand.nextDouble() * 1.5);
                goods.setViewCount(500 + rand.nextInt(20000));
                goods.setCreatedAt(Instant.now().minus(Duration.ofDays(rand.nextInt(90))));
                goods.setRecommend(i < 4); // 前4个设为推荐
                goodsRepository.save(goods);
            }
        }

        // 创建"我的"页面功能菜单
        if (mineFunctionRepository.count() == 0) {
            String[] functions = {"我的订单", "我的红包", "我的优惠券", "收货地址", "联系客服", "意见反馈"};
            for (int i = 0; i < functions.length; i++) {
                MineFunction func = new MineFunction();
                func.setMenuName(functions[i]);
                func.setMenuIcon("https://via.placeholder.com/50/EA3931/FFFFFF?text=" + i);
                func.setMenuCode("func_" + i);
                mineFunctionRepository.save(func);
            }
        }

        // 创建"我的"页面 Tab
        if (mineTabRepository.count() == 0) {
            String[] tabs = {"待付款", "待发货", "待收货", "待评价", "退换货"};
            for (int i = 0; i < tabs.length; i++) {
                MineTab mineTab = new MineTab();
                mineTab.setName(tabs[i]);
                mineTab.setCode("tab_" + i);
                mineTabRepository.save(mineTab);
            }
        }

        System.out.println("基础示例数据创建完成！");
    }

    private void backfillGoodsStats() {
        List<Goods> goodsList = goodsRepository.findAll();
        if (goodsList.isEmpty()) {
            return;
        }
        boolean updated = false;
        for (Goods g : goodsList) {
            if (g.getSalesCount() == null) {
                g.setSalesCount(100 + random.nextInt(5000));
                updated = true;
            }
            if (g.getRating() == null) {
                g.setRating(3.5 + random.nextDouble() * 1.5);
                updated = true;
            }
            if (g.getViewCount() == null) {
                g.setViewCount(500 + random.nextInt(20000));
                updated = true;
            }
            if (g.getCreatedAt() == null) {
                g.setCreatedAt(Instant.now().minus(Duration.ofDays(random.nextInt(90))));
                updated = true;
            }
            if (g.getRecommend() == null) {
                g.setRecommend(random.nextDouble() < 0.2);
                updated = true;
            }
        }
        if (updated) {
            goodsRepository.saveAll(goodsList);
        }
    }

    private void importHome(Path apiRoot, ObjectMapper mapper) throws IOException {
        Path homePath = apiRoot.resolve("home/queryHomePageInfo.json");
        if (!Files.exists(homePath)) {
            return;
        }
        JsonNode root = mapper.readTree(Files.readString(homePath, StandardCharsets.UTF_8));
        JsonNode data = root.path("data");
        String adUrl = data.path("adUrl").asText(null);
        if (homeConfigRepository.count() == 0 && adUrl != null && !adUrl.isEmpty()) {
            HomeConfig config = new HomeConfig();
            config.setAdUrl(adUrl);
            homeConfigRepository.save(config);
        }

        if (homeBannerRepository.count() > 0 || homeNineMenuRepository.count() > 0 || homeTabRepository.count() > 0) {
            return;
        }
        JsonNode bannerList = data.path("bannerList");
        if (bannerList.isArray()) {
            for (JsonNode n : bannerList) {
                HomeBanner b = new HomeBanner();
                b.setImgUrl(n.path("imgUrl").asText(null));
                b.setType(n.path("type").asText(null));
                homeBannerRepository.save(b);
            }
        }
        JsonNode nineMenuList = data.path("nineMenuList");
        if (nineMenuList.isArray()) {
            for (JsonNode n : nineMenuList) {
                HomeNineMenu m = new HomeNineMenu();
                m.setMenuIcon(n.path("menuIcon").asText(null));
                m.setMenuName(n.path("menuName").asText(null));
                m.setMenuCode(n.path("menuCode").asText(null));
                m.setH5url(n.path("h5url").asText(null));
                homeNineMenuRepository.save(m);
            }
        }
        JsonNode tabList = data.path("tabList");
        if (tabList.isArray()) {
            for (JsonNode n : tabList) {
                HomeTab t = new HomeTab();
                t.setName(n.path("name").asText(null));
                t.setCode(n.path("code").asText(null));
                homeTabRepository.save(t);
            }
        }
    }

    private void importCategory(Path apiRoot, ObjectMapper mapper) throws IOException {
        if (categoryRepository.count() > 0) {
            return;
        }
        Path listPath = apiRoot.resolve("category/list.json");
        if (Files.exists(listPath)) {
            JsonNode root = mapper.readTree(Files.readString(listPath, StandardCharsets.UTF_8));
            JsonNode data = root.path("data").path("categoryList");
            if (data.isArray()) {
                for (JsonNode n : data) {
                    Category c = new Category();
                    c.setCode(n.path("code").asText(null));
                    c.setName(n.path("name").asText(null));
                    c.setLevel(1);
                    categoryRepository.save(c);
                }
            }
        }
    }

    private void importCategoryContent(Path apiRoot, ObjectMapper mapper) throws IOException {
        Path path = apiRoot.resolve("category/queryContentByCategory.json");
        if (!Files.exists(path)) {
            return;
        }
        JsonNode root = mapper.readTree(Files.readString(path, StandardCharsets.UTF_8));
        JsonNode data = root.path("data");
        String bannerUrl = data.path("bannerUrl").asText(null);

        Category rootCategory = categoryRepository.findByCode("000")
                .orElseGet(() -> {
                    Category c = new Category();
                    c.setCode("000");
                    c.setName("推荐分类");
                    c.setLevel(1);
                    return categoryRepository.save(c);
                });
        if (bannerUrl != null && (rootCategory.getBannerUrl() == null || rootCategory.getBannerUrl().isEmpty())) {
            rootCategory.setBannerUrl(bannerUrl);
            categoryRepository.save(rootCategory);
        }

        JsonNode secondList = data.path("secondCateList");
        if (!secondList.isArray()) {
            return;
        }
        for (JsonNode secondNode : secondList) {
            String secondCode = secondNode.path("categoryCode").asText(null);
            String secondName = secondNode.path("categoryName").asText(null);
            Category second = categoryRepository.findByCode(secondCode)
                    .orElseGet(Category::new);
            second.setCode(secondCode);
            second.setName(secondName);
            second.setParentCode(rootCategory.getCode());
            second.setLevel(2);
            categoryRepository.save(second);

            JsonNode thirdList = secondNode.path("cateList");
            if (!thirdList.isArray()) {
                continue;
            }
            for (JsonNode thirdNode : thirdList) {
                String thirdCode = thirdNode.path("categoryCode").asText(null);
                String thirdName = thirdNode.path("categoryName").asText(null);
                String iconUrl = thirdNode.path("iconUrl").asText(null);
                Category third = categoryRepository.findByCode(thirdCode)
                        .orElseGet(Category::new);
                third.setCode(thirdCode);
                third.setName(thirdName);
                third.setParentCode(second.getCode());
                third.setLevel(3);
                third.setIconUrl(iconUrl);
                categoryRepository.save(third);
            }
        }
    }

    private void importGoods(Path apiRoot, ObjectMapper mapper) throws IOException {
        if (goodsRepository.count() > 0) {
            return;
        }
        Path goodsPath = apiRoot.resolve("common/queryGoodsListByPage.json");
        if (!Files.exists(goodsPath)) {
            return;
        }
        JsonNode root = mapper.readTree(Files.readString(goodsPath, StandardCharsets.UTF_8));
        JsonNode list = root.path("data").path("goodsList");
        if (list.isArray()) {
            for (JsonNode n : list) {
                Goods g = new Goods();
                g.setCategoryCode("DEFAULT");
                g.setImgUrl(n.path("imgUrl").asText(null));
                g.setDescription(n.path("description").asText(null));
                g.setTag(n.path("tag").asText(null));
                g.setDes1(n.path("des1").asText(null));
                g.setDes2(n.path("des2").asText(null));
                g.setType(n.path("type").asText(null));
                g.setPrice(n.path("price").asText(null));
                g.setH5url(n.path("h5url").asText(null));
                g.setRecommend(Boolean.FALSE);
                g.setSalesCount(100 + random.nextInt(5000));
                g.setRating(3.5 + random.nextDouble() * 1.5);
                g.setViewCount(500 + random.nextInt(20000));
                g.setCreatedAt(Instant.now().minus(Duration.ofDays(random.nextInt(90))));
                goodsRepository.save(g);
            }
        }
    }

    private void importMine(Path apiRoot, ObjectMapper mapper) throws IOException {
        if (mineFunctionRepository.count() > 0 || mineTabRepository.count() > 0) {
            return;
        }
        Path minePath = apiRoot.resolve("mine/queryMineInfo.json");
        if (!Files.exists(minePath)) {
            return;
        }
        JsonNode root = mapper.readTree(Files.readString(minePath, StandardCharsets.UTF_8));
        JsonNode data = root.path("data");
        JsonNode functionList = data.path("functionList");
        if (functionList.isArray()) {
            for (JsonNode n : functionList) {
                MineFunction f = new MineFunction();
                f.setMenuIcon(n.path("menuIcon").asText(null));
                f.setMenuName(n.path("menuName").asText(null));
                f.setMenuCode(n.path("menuCode").asText(null));
                f.setH5url(n.path("h5url").asText(null));
                mineFunctionRepository.save(f);
            }
        }
        JsonNode tabList = data.path("tabList");
        if (tabList.isArray()) {
            for (JsonNode n : tabList) {
                MineTab t = new MineTab();
                t.setName(n.path("name").asText(null));
                t.setCode(n.path("code").asText(null));
                mineTabRepository.save(t);
            }
        }
    }

    private void importMaybeLike(Path apiRoot, ObjectMapper mapper) throws IOException {
        Path path = apiRoot.resolve("cart/queryMaybeLikeList.json");
        if (!Files.exists(path)) {
            return;
        }
        JsonNode root = mapper.readTree(Files.readString(path, StandardCharsets.UTF_8));
        JsonNode list = root.path("data");
        if (!list.isArray()) {
            return;
        }
        for (JsonNode n : list) {
            Goods g = new Goods();
            g.setCategoryCode("RECOMMEND");
            g.setImgUrl(n.path("imgUrl").asText(null));
            g.setDescription(n.path("description").asText(null));
            g.setPrice(n.path("price").asText(null));
            g.setType(n.path("type").asText(null));
            g.setRecommend(Boolean.TRUE);
            goodsRepository.save(g);
        }
    }

}
