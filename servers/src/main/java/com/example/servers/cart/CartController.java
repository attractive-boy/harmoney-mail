package com.example.servers.cart;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.example.servers.BaseResponse;
import com.example.servers.goods.Goods;
import com.example.servers.goods.GoodsRepository;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CartController {

    private final StoreRepository storeRepository;
    private final CartItemRepository cartItemRepository;
    private final GoodsRepository goodsRepository;

    public CartController(StoreRepository storeRepository,
                          CartItemRepository cartItemRepository,
                          GoodsRepository goodsRepository) {
        this.storeRepository = storeRepository;
        this.cartItemRepository = cartItemRepository;
        this.goodsRepository = goodsRepository;
    }

    @PostMapping("/cart/queryCartGoodsList")
    public BaseResponse<List<Map<String, Object>>> queryCartGoodsList() {
        List<Store> stores = storeRepository.findAllByOrderByIdAsc();
        List<Map<String, Object>> result = new ArrayList<>();
        for (Store store : stores) {
            List<CartItem> items = cartItemRepository.findByStoreOrderByIdAsc(store);
            List<Map<String, Object>> goodsList = new ArrayList<>();
            for (CartItem item : items) {
                Map<String, Object> g = new HashMap<>();
                g.put("code", item.getCode());
                g.put("imgUrl", item.getImgUrl());
                g.put("description", item.getDescription());
                g.put("price", item.getPrice());
                g.put("color", item.getColor());
                g.put("size", item.getSize());
                g.put("num", item.getNum());
                g.put("select", item.getSelected());
                goodsList.add(g);
            }
            Map<String, Object> storeMap = new HashMap<>();
            storeMap.put("storeName", store.getStoreName());
            storeMap.put("storeCode", store.getStoreCode());
            storeMap.put("h5url", store.getH5url());
            storeMap.put("select", Boolean.TRUE);
            storeMap.put("goodsList", goodsList);
            result.add(storeMap);
        }
        return BaseResponse.success(result);
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

