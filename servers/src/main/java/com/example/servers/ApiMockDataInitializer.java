package com.example.servers;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
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

    private final ApiMockRepository apiMockRepository;
    private final HomeBannerRepository homeBannerRepository;
    private final HomeNineMenuRepository homeNineMenuRepository;
    private final HomeTabRepository homeTabRepository;
    private final CategoryRepository categoryRepository;
    private final GoodsRepository goodsRepository;
    private final MineFunctionRepository mineFunctionRepository;
    private final MineTabRepository mineTabRepository;
    private final StoreRepository storeRepository;
    private final CartItemRepository cartItemRepository;
    private final Random random = new Random();

    public ApiMockDataInitializer(ApiMockRepository apiMockRepository,
                                  HomeBannerRepository homeBannerRepository,
                                  HomeNineMenuRepository homeNineMenuRepository,
                                  HomeTabRepository homeTabRepository,
                                  CategoryRepository categoryRepository,
                                  GoodsRepository goodsRepository,
                                  MineFunctionRepository mineFunctionRepository,
                                  MineTabRepository mineTabRepository,
                                  StoreRepository storeRepository,
                                  CartItemRepository cartItemRepository) {
        this.apiMockRepository = apiMockRepository;
        this.homeBannerRepository = homeBannerRepository;
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
        if (apiMockRepository.count() == 0) {
            importAllJsonAsMock(apiRoot);
        }
        removeDetailMocks();
        ObjectMapper mapper = new ObjectMapper();
        importHome(apiRoot, mapper);
        importCategory(apiRoot, mapper);
        importGoods(apiRoot, mapper);
        backfillGoodsStats();
        importMine(apiRoot, mapper);
        importCart(apiRoot, mapper);
        importMaybeLike(apiRoot, mapper);
        updateCategoryQueryContentMock(apiRoot);
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

    private void importAllJsonAsMock(Path apiRoot) throws IOException {
        List<ApiMock> items = new ArrayList<>();
        Files.walk(apiRoot)
                .filter(p -> Files.isRegularFile(p) && p.toString().endsWith(".json"))
                .forEach(p -> {
                    try {
                        String body = Files.readString(p, StandardCharsets.UTF_8);
                        Path relative = apiRoot.relativize(p);
                        String path = "/" + relative.toString().replace(FileSystems.getDefault().getSeparator(), "/");
                        if (path.endsWith(".json")) {
                            path = path.substring(0, path.length() - ".json".length());
                        }
                        items.add(new ApiMock(path, "POST", body));
                    } catch (IOException e) {
                    }
                });
        if (!items.isEmpty()) {
            apiMockRepository.saveAll(items);
        }
    }

        private void removeDetailMocks() {
        apiMockRepository.deleteByPathAndMethod("/detail/queryGoodsDetail", "POST");
        apiMockRepository.deleteByPathAndMethod("/detail/queryStoreGoodsList", "POST");
    }

    private void importHome(Path apiRoot, ObjectMapper mapper) throws IOException {
        if (homeBannerRepository.count() > 0 || homeNineMenuRepository.count() > 0 || homeTabRepository.count() > 0) {
            return;
        }
        Path homePath = apiRoot.resolve("home/queryHomePageInfo.json");
        if (!Files.exists(homePath)) {
            return;
        }
        JsonNode root = mapper.readTree(Files.readString(homePath, StandardCharsets.UTF_8));
        JsonNode data = root.path("data");
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

    private void updateCategoryQueryContentMock(Path apiRoot) throws IOException {
        Path path = apiRoot.resolve("category/queryContentByCategory.json");
        if (!Files.exists(path)) {
            return;
        }
        String body = Files.readString(path, StandardCharsets.UTF_8);
        String apiPath = "/category/queryContentByCategory";
        apiMockRepository.findByPathAndMethod(apiPath, "POST")
                .ifPresentOrElse(mock -> {
                    mock.setResponseBody(body);
                    apiMockRepository.save(mock);
                }, () -> apiMockRepository.save(new ApiMock(apiPath, "POST", body)));
    }
}
