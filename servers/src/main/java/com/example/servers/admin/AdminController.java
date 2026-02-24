package com.example.servers.admin;

import com.example.servers.BaseResponse;
import com.example.servers.auth.User;
import com.example.servers.auth.UserRepository;
import com.example.servers.goods.Goods;
import com.example.servers.goods.GoodsRepository;
import com.example.servers.news.Article;
import com.example.servers.news.ArticleRepository;
import com.example.servers.order.Order;
import com.example.servers.order.OrderRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.*;

@RestController
@RequestMapping("/admin")
public class AdminController {

    // ─── 简单的管理员凭据（生产环境应换成数据库+JWT）─────────────────
    private static final String ADMIN_USER = "admin";
    private static final String ADMIN_PASS = "admin123";
    private static final String ADMIN_TOKEN = "ADMIN_SECRET_TOKEN_2025";

    private final UserRepository userRepository;
    private final GoodsRepository goodsRepository;
    private final OrderRepository orderRepository;
    private final ArticleRepository articleRepository;

    public AdminController(UserRepository userRepository,
                           GoodsRepository goodsRepository,
                           OrderRepository orderRepository,
                           ArticleRepository articleRepository) {
        this.userRepository = userRepository;
        this.goodsRepository = goodsRepository;
        this.orderRepository = orderRepository;
        this.articleRepository = articleRepository;
    }

    // ─── 鉴权 ────────────────────────────────────────────────────────

    @PostMapping("/login")
    public BaseResponse<Map<String, Object>> login(@RequestBody Map<String, Object> body) {
        String username = getStr(body, "username", "");
        String password = getStr(body, "password", "");
        if (ADMIN_USER.equals(username) && ADMIN_PASS.equals(password)) {
            Map<String, Object> data = new HashMap<>();
            data.put("token", ADMIN_TOKEN);
            data.put("username", ADMIN_USER);
            return BaseResponse.success(data);
        }
        return new BaseResponse<>("401", "用户名或密码错误", null);
    }

    private boolean checkToken(Map<String, Object> body) {
        return ADMIN_TOKEN.equals(getStr(body, "token", ""));
    }

    // ─── 仪表盘统计 ───────────────────────────────────────────────────

    @PostMapping("/dashboard")
    public BaseResponse<Map<String, Object>> dashboard(@RequestBody Map<String, Object> body) {
        if (!checkToken(body)) return unauthorized();
        Map<String, Object> data = new HashMap<>();
        data.put("totalUsers", userRepository.count());
        data.put("activeUsers", userRepository.countByStatus("ACTIVE"));
        data.put("disabledUsers", userRepository.countByStatus("DISABLED"));
        data.put("totalGoods", goodsRepository.count());
        data.put("activeGoods", goodsRepository.countByStatus("ACTIVE"));
        data.put("inactiveGoods", goodsRepository.countByStatus("INACTIVE"));
        data.put("totalOrders", orderRepository.count());
        data.put("totalArticles", articleRepository.count());
        // 各订单状态数量
        Map<String, Long> orderStats = new LinkedHashMap<>();
        String[] statuses = {"PENDING_PAYMENT", "PENDING_SHIPMENT", "PENDING_RECEIPT", "COMPLETED", "CANCELLED"};
        for (String s : statuses) {
            orderStats.put(s, orderRepository.countByStatus(s));
        }
        data.put("orderStats", orderStats);
        // 分类销量
        List<Map<String, Object>> catSales = new ArrayList<>();
        List<Object[]> rows = goodsRepository.sumSalesByCategory();
        for (Object[] row : rows) {
            Map<String, Object> m = new HashMap<>();
            m.put("category", row[0]);
            m.put("sales", row[1]);
            catSales.add(m);
        }
        data.put("categorySales", catSales);
        return BaseResponse.success(data);
    }

    // ─── 用户管理 ─────────────────────────────────────────────────────

    @PostMapping("/user/list")
    public BaseResponse<Map<String, Object>> userList(@RequestBody Map<String, Object> body) {
        if (!checkToken(body)) return unauthorized();
        String keyword = getStr(body, "keyword", null);
        String status  = getStr(body, "status", null);
        int page  = getInt(body, "page", 0);
        int size  = getInt(body, "size", 20);
        Pageable pageable = PageRequest.of(page, size, Sort.by("id").descending());
        Page<User> result = userRepository.adminSearch(
                (status == null || status.isEmpty()) ? null : status,
                (keyword == null || keyword.isEmpty()) ? null : keyword,
                pageable);
        List<Map<String, Object>> list = new ArrayList<>();
        for (User u : result.getContent()) {
            list.add(userToMap(u));
        }
        return BaseResponse.success(pageResult(list, result));
    }

    @PostMapping("/user/toggleStatus")
    @Transactional
    public BaseResponse<String> userToggleStatus(@RequestBody Map<String, Object> body) {
        if (!checkToken(body)) return unauthorized();
        Long id = getLong(body, "id");
        if (id == null) return new BaseResponse<>("400", "缺少id", null);
        Optional<User> opt = userRepository.findById(id);
        if (opt.isEmpty()) return new BaseResponse<>("404", "用户不存在", null);
        User u = opt.get();
        u.setStatus("ACTIVE".equals(u.getStatus()) ? "DISABLED" : "ACTIVE");
        userRepository.save(u);
        return BaseResponse.success("状态已更新为：" + u.getStatus());
    }

    // ─── 商品管理 ─────────────────────────────────────────────────────

    @PostMapping("/goods/list")
    public BaseResponse<Map<String, Object>> goodsList(@RequestBody Map<String, Object> body) {
        if (!checkToken(body)) return unauthorized();
        String keyword = getStr(body, "keyword", null);
        String status  = getStr(body, "status", null);
        int page  = getInt(body, "page", 0);
        int size  = getInt(body, "size", 20);
        String sortField = getStr(body, "sortField", "id");
        String sortDir   = getStr(body, "sortDir", "desc");
        Sort sort = "asc".equalsIgnoreCase(sortDir) ? Sort.by(sortField).ascending() : Sort.by(sortField).descending();
        Pageable pageable = PageRequest.of(page, size, sort);
        Page<Goods> result = goodsRepository.adminSearch(
                (status == null || status.isEmpty()) ? null : status,
                (keyword == null || keyword.isEmpty()) ? null : keyword,
                pageable);
        List<Map<String, Object>> list = new ArrayList<>();
        for (Goods g : result.getContent()) {
            list.add(goodsToMap(g));
        }
        return BaseResponse.success(pageResult(list, result));
    }

    @PostMapping("/goods/create")
    @Transactional
    public BaseResponse<Map<String, Object>> goodsCreate(@RequestBody Map<String, Object> body) {
        if (!checkToken(body)) return unauthorized();
        Goods g = new Goods();
        fillGoods(g, body);
        g.setStatus("ACTIVE");
        g.setCreatedAt(Instant.now());
        goodsRepository.save(g);
        return BaseResponse.success(goodsToMap(g));
    }

    @PostMapping("/goods/update")
    @Transactional
    public BaseResponse<Map<String, Object>> goodsUpdate(@RequestBody Map<String, Object> body) {
        if (!checkToken(body)) return unauthorized();
        Long id = getLong(body, "id");
        if (id == null) return new BaseResponse<>("400", "缺少id", null);
        Optional<Goods> opt = goodsRepository.findById(id);
        if (opt.isEmpty()) return new BaseResponse<>("404", "商品不存在", null);
        Goods g = opt.get();
        fillGoods(g, body);
        goodsRepository.save(g);
        return BaseResponse.success(goodsToMap(g));
    }

    @PostMapping("/goods/toggleStatus")
    @Transactional
    public BaseResponse<String> goodsToggleStatus(@RequestBody Map<String, Object> body) {
        if (!checkToken(body)) return unauthorized();
        Long id = getLong(body, "id");
        if (id == null) return new BaseResponse<>("400", "缺少id", null);
        Optional<Goods> opt = goodsRepository.findById(id);
        if (opt.isEmpty()) return new BaseResponse<>("404", "商品不存在", null);
        Goods g = opt.get();
        g.setStatus("ACTIVE".equals(g.getStatus()) ? "INACTIVE" : "ACTIVE");
        goodsRepository.save(g);
        return BaseResponse.success("状态已更新为：" + g.getStatus());
    }

    // ─── 资讯管理 ─────────────────────────────────────────────────────

    @PostMapping("/news/list")
    public BaseResponse<Map<String, Object>> newsList(@RequestBody Map<String, Object> body) {
        if (!checkToken(body)) return unauthorized();
        int page = getInt(body, "page", 0);
        int size = getInt(body, "size", 20);
        Pageable pageable = PageRequest.of(page, size, Sort.by("publishedAt").descending());
        Page<Article> result = articleRepository.findAllByOrderByPublishedAtDesc(pageable);
        List<Map<String, Object>> list = new ArrayList<>();
        for (Article a : result.getContent()) {
            list.add(articleToMap(a));
        }
        return BaseResponse.success(pageResult(list, result));
    }

    @PostMapping("/news/create")
    @Transactional
    public BaseResponse<Map<String, Object>> newsCreate(@RequestBody Map<String, Object> body) {
        if (!checkToken(body)) return unauthorized();
        Article a = new Article();
        fillArticle(a, body);
        a.setPublishedAt(LocalDateTime.now());
        articleRepository.save(a);
        return BaseResponse.success(articleToMap(a));
    }

    @PostMapping("/news/update")
    @Transactional
    public BaseResponse<Map<String, Object>> newsUpdate(@RequestBody Map<String, Object> body) {
        if (!checkToken(body)) return unauthorized();
        Long id = getLong(body, "id");
        if (id == null) return new BaseResponse<>("400", "缺少id", null);
        Optional<Article> opt = articleRepository.findById(id);
        if (opt.isEmpty()) return new BaseResponse<>("404", "资讯不存在", null);
        Article a = opt.get();
        fillArticle(a, body);
        articleRepository.save(a);
        return BaseResponse.success(articleToMap(a));
    }

    @PostMapping("/news/delete")
    @Transactional
    public BaseResponse<String> newsDelete(@RequestBody Map<String, Object> body) {
        if (!checkToken(body)) return unauthorized();
        Long id = getLong(body, "id");
        if (id == null) return new BaseResponse<>("400", "缺少id", null);
        articleRepository.deleteById(id);
        return BaseResponse.success("已删除");
    }

    // ─── 销量分析 ─────────────────────────────────────────────────────

    @PostMapping("/analytics/sales")
    public BaseResponse<Map<String, Object>> salesAnalytics(@RequestBody Map<String, Object> body) {
        if (!checkToken(body)) return unauthorized();
        Map<String, Object> data = new HashMap<>();
        // 按分类统计
        List<Map<String, Object>> catSales = new ArrayList<>();
        for (Object[] row : goodsRepository.sumSalesByCategory()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("category", row[0]);
            m.put("sales", row[1]);
            catSales.add(m);
        }
        data.put("categorySales", catSales);
        // 订单总金额 + 各状态数量
        List<Order> allOrders = orderRepository.findAll();
        double totalRevenue = 0.0;
        Map<String, Long> statusCount = new LinkedHashMap<>();
        for (Order o : allOrders) {
            totalRevenue += o.getTotalAmount() != null ? o.getTotalAmount().doubleValue() : 0;
            statusCount.merge(o.getStatus(), 1L, Long::sum);
        }
        data.put("totalRevenue", String.format("%.2f", totalRevenue));
        data.put("orderStatusCount", statusCount);
        return BaseResponse.success(data);
    }

    // ─── 辅助方法 ─────────────────────────────────────────────────────

    private <T> BaseResponse<T> unauthorized() {
        return new BaseResponse<>("401", "未授权，请先登录", null);
    }

    private Map<String, Object> pageResult(List<?> list, Page<?> page) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("list", list);
        m.put("totalElements", page.getTotalElements());
        m.put("totalPages", page.getTotalPages());
        m.put("currentPage", page.getNumber());
        m.put("hasMore", page.hasNext());
        return m;
    }

    private Map<String, Object> userToMap(User u) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", u.getId());
        m.put("email", u.getEmail());
        m.put("phone", u.getPhone());
        m.put("nickname", u.getNickname());
        m.put("points", u.getPoints());
        m.put("credit", u.getCredit());
        m.put("status", u.getStatus());
        m.put("createdAt", u.getCreatedAt() != null ? u.getCreatedAt().toString().substring(0, 10) : "");
        return m;
    }

    private Map<String, Object> goodsToMap(Goods g) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", g.getId());
        m.put("description", g.getDescription());
        m.put("tag", g.getTag());
        m.put("price", g.getPrice());
        m.put("categoryCode", g.getCategoryCode());
        m.put("imgUrl", g.getImgUrl());
        m.put("salesCount", g.getSalesCount());
        m.put("rating", g.getRating());
        m.put("recommend", g.getRecommend());
        m.put("status", g.getStatus());
        m.put("storeName", g.getStoreName());
        m.put("createdAt", g.getCreatedAt() != null ? g.getCreatedAt().toString().substring(0, 10) : "");
        return m;
    }

    private void fillGoods(Goods g, Map<String, Object> body) {
        if (body.containsKey("description")) g.setDescription(getStr(body, "description", ""));
        if (body.containsKey("tag"))          g.setTag(getStr(body, "tag", ""));
        if (body.containsKey("price"))        g.setPrice(getStr(body, "price", "0"));
        if (body.containsKey("categoryCode")) g.setCategoryCode(getStr(body, "categoryCode", ""));
        if (body.containsKey("imgUrl"))       g.setImgUrl(getStr(body, "imgUrl", ""));
        if (body.containsKey("des1"))         g.setDes1(getStr(body, "des1", ""));
        if (body.containsKey("des2"))         g.setDes2(getStr(body, "des2", ""));
        if (body.containsKey("storeName"))    g.setStoreName(getStr(body, "storeName", ""));
        if (body.containsKey("recommend"))    g.setRecommend(Boolean.parseBoolean(getStr(body, "recommend", "false")));
        if (body.containsKey("status"))       g.setStatus(getStr(body, "status", "ACTIVE"));
    }

    private Map<String, Object> articleToMap(Article a) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", a.getId());
        m.put("title", a.getTitle());
        m.put("summary", a.getSummary());
        m.put("content", a.getContent());
        m.put("imageUrl", a.getImageUrl());
        m.put("category", a.getCategory());
        m.put("source", a.getSource());
        m.put("viewCount", a.getViewCount());
        m.put("publishedAt", a.getPublishedAt() != null ? a.getPublishedAt().toString().substring(0, 10) : "");
        return m;
    }

    private void fillArticle(Article a, Map<String, Object> body) {
        if (body.containsKey("title"))    a.setTitle(getStr(body, "title", ""));
        if (body.containsKey("summary"))  a.setSummary(getStr(body, "summary", ""));
        if (body.containsKey("content"))  a.setContent(getStr(body, "content", ""));
        if (body.containsKey("imageUrl")) a.setImageUrl(getStr(body, "imageUrl", ""));
        if (body.containsKey("category")) a.setCategory(getStr(body, "category", "INDUSTRY"));
        if (body.containsKey("source"))   a.setSource(getStr(body, "source", ""));
    }

    private String getStr(Map<String, Object> body, String key, String def) {
        Object v = body.get(key);
        return v != null ? v.toString() : def;
    }

    private int getInt(Map<String, Object> body, String key, int def) {
        Object v = body.get(key);
        if (v == null) return def;
        try { return Integer.parseInt(v.toString()); } catch (Exception e) { return def; }
    }

    private Long getLong(Map<String, Object> body, String key) {
        Object v = body.get(key);
        if (v == null) return null;
        try { return Long.parseLong(v.toString()); } catch (Exception e) { return null; }
    }
}
