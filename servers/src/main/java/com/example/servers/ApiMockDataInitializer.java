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

import com.example.servers.cart.CartItem;
import com.example.servers.cart.CartItemRepository;
import com.example.servers.cart.Store;
import com.example.servers.cart.StoreRepository;
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
    private final StoreRepository storeRepository;
    private final CartItemRepository cartItemRepository;
    private final Random random = new Random();

    public ApiMockDataInitializer(HomeBannerRepository homeBannerRepository,
                                  HomeConfigRepository homeConfigRepository,
                                  HomeNineMenuRepository homeNineMenuRepository,
                                  HomeTabRepository homeTabRepository,
                                  CategoryRepository categoryRepository,
                                  GoodsRepository goodsRepository,
                                  MineFunctionRepository mineFunctionRepository,
                                  MineTabRepository mineTabRepository,
                                  StoreRepository storeRepository,
                                  CartItemRepository cartItemRepository) {
        this.homeBannerRepository = homeBannerRepository;
        this.homeConfigRepository = homeConfigRepository;
        this.homeNineMenuRepository = homeNineMenuRepository;
        this.homeTabRepository = homeTabRepository;
        this.categoryRepository = categoryRepository;
        this.goodsRepository = goodsRepository;
        this.mineFunctionRepository = mineFunctionRepository;
        this.mineTabRepository = mineTabRepository;
        this.storeRepository = storeRepository;
        this.cartItemRepository = cartItemRepository;
    }

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        Path apiRoot = Paths.get("../jdMall_Harmony/mock_server/api").toAbsolutePath().normalize();
        if (!Files.exists(apiRoot)) {
            return;
        }
        ObjectMapper mapper = new ObjectMapper();
        importHome(apiRoot, mapper);
        importCategory(apiRoot, mapper);
        importCategoryContent(apiRoot, mapper);
        importGoods(apiRoot, mapper);
        backfillGoodsStats();
        importMine(apiRoot, mapper);
        importCart(apiRoot, mapper);
        importMaybeLike(apiRoot, mapper);
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

    private void importCart(Path apiRoot, ObjectMapper mapper) throws IOException {
        if (storeRepository.count() > 0 || cartItemRepository.count() > 0) {
            return;
        }
        Path cartPath = apiRoot.resolve("cart/queryCartGoodsList.json");
        if (!Files.exists(cartPath)) {
            return;
        }
        JsonNode root = mapper.readTree(Files.readString(cartPath, StandardCharsets.UTF_8));
        JsonNode list = root.path("data");
        if (!list.isArray()) {
            return;
        }
        for (JsonNode s : list) {
            Store store = new Store();
            store.setStoreName(s.path("storeName").asText(null));
            store.setStoreCode(s.path("storeCode").asText(null));
            store.setH5url(s.path("h5url").asText(null));
            store = storeRepository.save(store);
            JsonNode goodsList = s.path("goodsList");
            if (goodsList.isArray()) {
                for (JsonNode n : goodsList) {
                    CartItem item = new CartItem();
                    item.setStore(store);
                    item.setCode(n.path("code").asText(null));
                    item.setImgUrl(n.path("imgUrl").asText(null));
                    item.setDescription(n.path("description").asText(null));
                    item.setPrice(n.path("price").asText(null));
                    item.setColor(n.path("color").asText(null));
                    item.setSize(n.path("size").asText(null));
                    item.setNum(n.path("num").isNumber() ? n.path("num").intValue() : 1);
                    item.setSelected(n.path("select").asBoolean(true));
                    cartItemRepository.save(item);
                }
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
