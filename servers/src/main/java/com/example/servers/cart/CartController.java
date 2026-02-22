package com.example.servers.cart;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.example.servers.BaseResponse;
import com.example.servers.goods.Goods;
import com.example.servers.goods.GoodsRepository;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CartController {

    private final StoreRepository storeRepository;
    private final CartItemRepository cartItemRepository;
    private final CartRepository cartRepository;
    private final GoodsRepository goodsRepository;

    public CartController(StoreRepository storeRepository,
                          CartItemRepository cartItemRepository,
                          CartRepository cartRepository,
                          GoodsRepository goodsRepository) {
        this.storeRepository = storeRepository;
        this.cartItemRepository = cartItemRepository;
        this.cartRepository = cartRepository;
        this.goodsRepository = goodsRepository;
    }

    @PostMapping("/cart/queryCartGoodsList")
    public BaseResponse<List<Map<String, Object>>> queryCartGoodsList(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Cart cart = cartRepository.findByUserId(userId).orElse(null);
        if (cart == null) {
            return BaseResponse.success(List.of());
        }

        List<CartItem> items = cartItemRepository.findByCartOrderByIdAsc(cart);
        Map<Long, Store> storeIndex = new LinkedHashMap<>();
        Map<Long, List<CartItem>> storeItems = new LinkedHashMap<>();
        for (CartItem item : items) {
            Store store = item.getStore();
            if (store == null) {
                continue;
            }
            storeIndex.putIfAbsent(store.getId(), store);
            storeItems.computeIfAbsent(store.getId(), k -> new ArrayList<>()).add(item);
        }

        List<Map<String, Object>> result = new ArrayList<>();
        for (Store store : storeIndex.values()) {
            List<CartItem> storeItemList = storeItems.getOrDefault(store.getId(), List.of());
            List<Map<String, Object>> goodsList = new ArrayList<>();
            boolean storeSelected = true;
            for (CartItem item : storeItemList) {
                Map<String, Object> g = new HashMap<>();
                g.put("id", item.getId());
                g.put("code", item.getCode());
                g.put("imgUrl", item.getImgUrl());
                g.put("description", item.getDescription());
                g.put("price", item.getPrice());
                g.put("color", item.getColor());
                g.put("size", item.getSize());
                g.put("num", item.getNum());
                boolean selected = item.getSelected() != null && item.getSelected();
                g.put("select", selected);
                g.put("saved", item.getSaved() != null && item.getSaved());
                g.put("favorite", item.getFavorite() != null && item.getFavorite());
                g.put("compare", item.getCompare() != null && item.getCompare());
                if (!selected) {
                    storeSelected = false;
                }
                goodsList.add(g);
            }
            Map<String, Object> storePayload = new HashMap<>();
            storePayload.put("storeName", store.getStoreName());
            storePayload.put("storeCode", store.getStoreCode());
            storePayload.put("h5url", store.getH5url());
            storePayload.put("select", !goodsList.isEmpty() && storeSelected);
            storePayload.put("goodsList", goodsList);
            result.add(storePayload);
        }
        return BaseResponse.success(result);
    }

    @PostMapping("/cart/add")
    public BaseResponse<Map<String, Object>> addToCart(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        String goodsId = body.get("goodsId") == null ? null : body.get("goodsId").toString();
        int num = body.get("num") instanceof Number ? ((Number) body.get("num")).intValue() : 1;
        String color = body.get("color") == null ? "默认" : body.get("color").toString();
        String size = body.get("size") == null ? "默认" : body.get("size").toString();
        boolean selected = body.get("selected") instanceof Boolean ? (Boolean) body.get("selected") : true;
        boolean saved = body.get("saved") instanceof Boolean ? (Boolean) body.get("saved") : false;
        boolean favorite = body.get("favorite") instanceof Boolean ? (Boolean) body.get("favorite") : false;
        boolean compare = body.get("compare") instanceof Boolean ? (Boolean) body.get("compare") : false;
        String storeCode = body.get("storeCode") == null ? "default" : body.get("storeCode").toString();
        String storeName = body.get("storeName") == null ? null : body.get("storeName").toString();

        if (goodsId == null || goodsId.isEmpty()) {
            return new BaseResponse<>("400", "商品ID不能为空", null);
        }
        Goods goods;
        try {
            goods = goodsRepository.findById(Long.parseLong(goodsId)).orElse(null);
        } catch (NumberFormatException ex) {
            return new BaseResponse<>("400", "商品ID非法", null);
        }
        if (goods == null) {
            return new BaseResponse<>("404", "商品不存在", null);
        }

        Cart cart = cartRepository.findByUserId(userId).orElse(null);
        if (cart == null) {
            cart = new Cart();
            cart.setUserId(userId);
            cart.setCreatedAt(Instant.now());
            cart = cartRepository.save(cart);
        }

        Store store = storeRepository.findByStoreCode(storeCode);
        if (store == null) {
            store = new Store();
            store.setStoreCode(storeCode);
            store.setStoreName(storeName != null && !storeName.isEmpty() ? storeName :
                    (goods.getStoreName() == null ? "官方自营" : goods.getStoreName()));
            store.setH5url(goods.getH5url());
            store = storeRepository.save(store);
        }

        String code = goods.getId().toString();
        CartItem existing = cartItemRepository.findByCartAndCodeAndColorAndSize(cart, code, color, size);
        if (existing != null) {
            existing.setNum(existing.getNum() == null ? num : existing.getNum() + num);
            existing.setSelected(selected);
            existing.setSaved(saved);
            existing.setFavorite(favorite);
            existing.setCompare(compare);
            cartItemRepository.save(existing);
            Map<String, Object> data = new HashMap<>();
            data.put("itemId", existing.getId());
            data.put("num", existing.getNum());
            return BaseResponse.success(data);
        }

        CartItem item = new CartItem();
        item.setStore(store);
        item.setCart(cart);
        item.setCode(code);
        item.setImgUrl(goods.getImgUrl());
        item.setDescription(goods.getDescription());
        item.setPrice(goods.getPrice());
        item.setColor(color);
        item.setSize(size);
        item.setNum(Math.max(num, 1));
        item.setSelected(selected);
        item.setSaved(saved);
        item.setFavorite(favorite);
        item.setCompare(compare);
        cartItemRepository.save(item);

        Map<String, Object> data = new HashMap<>();
        data.put("itemId", item.getId());
        data.put("num", item.getNum());
        return BaseResponse.success(data);
    }

    @PostMapping("/cart/updateItem")
    public BaseResponse<Map<String, Object>> updateItem(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Long itemId = body.get("itemId") instanceof Number ? ((Number) body.get("itemId")).longValue() : null;
        if (itemId == null) {
            return new BaseResponse<>("400", "itemId不能为空", null);
        }
        CartItem item = cartItemRepository.findById(itemId).orElse(null);
        if (item == null) {
            return new BaseResponse<>("404", "购物车项不存在", null);
        }
        if (!belongsToUser(item, userId)) {
            return new BaseResponse<>("403", "无权限操作该购物车项", null);
        }
        if (body.get("num") instanceof Number) {
            item.setNum(Math.max(((Number) body.get("num")).intValue(), 1));
        }
        if (body.get("selected") instanceof Boolean) {
            item.setSelected((Boolean) body.get("selected"));
        }
        if (body.get("saved") instanceof Boolean) {
            item.setSaved((Boolean) body.get("saved"));
        }
        if (body.get("favorite") instanceof Boolean) {
            item.setFavorite((Boolean) body.get("favorite"));
        }
        if (body.get("compare") instanceof Boolean) {
            item.setCompare((Boolean) body.get("compare"));
        }
        cartItemRepository.save(item);
        return BaseResponse.success(new HashMap<>());
    }

    @PostMapping("/cart/removeItem")
    public BaseResponse<Map<String, Object>> removeItem(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Long itemId = body.get("itemId") instanceof Number ? ((Number) body.get("itemId")).longValue() : null;
        if (itemId == null) {
            return new BaseResponse<>("400", "itemId不能为空", null);
        }
        CartItem item = cartItemRepository.findById(itemId).orElse(null);
        if (item == null) {
            return new BaseResponse<>("404", "购物车项不存在", null);
        }
        if (!belongsToUser(item, userId)) {
            return new BaseResponse<>("403", "无权限操作该购物车项", null);
        }
        cartItemRepository.deleteById(itemId);
        return BaseResponse.success(new HashMap<>());
    }

    @PostMapping("/cart/removeItems")
    public BaseResponse<Map<String, Object>> removeItems(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Object raw = body.get("itemIds");
        if (!(raw instanceof List)) {
            return new BaseResponse<>("400", "itemIds不能为空", null);
        }
        @SuppressWarnings("unchecked")
        List<Object> ids = (List<Object>) raw;
        for (Object id : ids) {
            if (id instanceof Number) {
                Long itemId = ((Number) id).longValue();
                CartItem item = cartItemRepository.findById(itemId).orElse(null);
                if (item != null && belongsToUser(item, userId)) {
                    cartItemRepository.deleteById(itemId);
                }
            }
        }
        return BaseResponse.success(new HashMap<>());
    }

    @PostMapping("/cart/selectStore")
    public BaseResponse<Map<String, Object>> selectStore(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        String storeCode = body.get("storeCode") == null ? null : body.get("storeCode").toString();
        boolean selected = body.get("selected") instanceof Boolean ? (Boolean) body.get("selected") : true;
        if (storeCode == null || storeCode.isEmpty()) {
            return new BaseResponse<>("400", "storeCode不能为空", null);
        }
        Store store = storeRepository.findByStoreCode(storeCode);
        if (store == null) {
            return new BaseResponse<>("404", "店铺不存在", null);
        }
        Cart cart = cartRepository.findByUserId(userId).orElse(null);
        if (cart == null) {
            return BaseResponse.success(new HashMap<>());
        }
        List<CartItem> items = cartItemRepository.findByCartAndStoreOrderByIdAsc(cart, store);
        for (CartItem item : items) {
            item.setSelected(selected);
        }
        cartItemRepository.saveAll(items);
        return BaseResponse.success(new HashMap<>());
    }

    @PostMapping("/cart/selectAll")
    public BaseResponse<Map<String, Object>> selectAll(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        boolean selected = body.get("selected") instanceof Boolean ? (Boolean) body.get("selected") : true;
        Cart cart = cartRepository.findByUserId(userId).orElse(null);
        if (cart == null) {
            return BaseResponse.success(new HashMap<>());
        }
        List<CartItem> items = cartItemRepository.findByCartOrderByIdAsc(cart);
        for (CartItem item : items) {
            item.setSelected(selected);
        }
        cartItemRepository.saveAll(items);
        return BaseResponse.success(new HashMap<>());
    }

    @PostMapping("/cart/clear")
    public BaseResponse<Map<String, Object>> clearCart(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        return clearCartInternal(userId);
    }

    @PostMapping("/cart/admin/clearAll")
    public BaseResponse<Map<String, Object>> clearAllCarts() {
        cartItemRepository.deleteAll();
        cartRepository.deleteAll();
        Map<String, Object> result = new HashMap<>();
        result.put("message", "所有购物车数据已清空");
        return BaseResponse.success(result);
    }

    private BaseResponse<Map<String, Object>> clearCartInternal(String userId) {
        if (userId == null || userId.isEmpty()) {
            return new BaseResponse<>("400", "userId不能为空", null);
        }
        Cart cart = cartRepository.findByUserId(userId).orElse(null);
        if (cart == null) {
            return BaseResponse.success(new HashMap<>());
        }
        cartItemRepository.deleteByCart(cart);
        return BaseResponse.success(new HashMap<>());
    }

    private String resolveUserId(Map<String, Object> body) {
        Object raw = body == null ? null : body.get("userId");
        if (raw == null) {
            return "guest";
        }
        String userId = raw.toString();
        return userId.isEmpty() ? "guest" : userId;
    }

    private boolean belongsToUser(CartItem item, String userId) {
        if (item == null || item.getCart() == null) {
            return false;
        }
        String owner = item.getCart().getUserId();
        return owner != null && owner.equals(userId);
    }

    @PostMapping("/cart/queryMaybeLikeList")
    public BaseResponse<List<Map<String, Object>>> queryMaybeLikeList() {
        List<Goods> goods = goodsRepository.findByRecommendTrue(org.springframework.data.domain.Pageable.unpaged()).getContent();
        List<Map<String, Object>> list = new ArrayList<>();
        for (Goods g : goods) {
            Map<String, Object> m = new HashMap<>();
            m.put("imgUrl", g.getImgUrl());
            m.put("description", g.getDescription());
            m.put("price", g.getPrice());
            m.put("type", g.getType());
            list.add(m);
        }
        return BaseResponse.success(list);
    }
}

