package com.example.servers.detail;

import com.example.servers.BaseResponse;
import com.example.servers.goods.Goods;
import com.example.servers.goods.GoodsRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
public class DetailController {

    private final GoodsRepository goodsRepository;

    public DetailController(GoodsRepository goodsRepository) {
        this.goodsRepository = goodsRepository;
    }

    @PostMapping("/detail/queryGoodsDetail")
    public BaseResponse<Map<String, Object>> queryGoodsDetail(@RequestBody Map<String, Object> body) {
        String goodsId = body.get("goodsId") == null ? null : body.get("goodsId").toString();
        Goods goods = parseGoods(goodsId);
        if (goods == null) {
            return new BaseResponse<>("404", "商品不存在", null);
        }
        // 设置占位数据
        if (goods.getStoreName() == null) {
            goods.setStoreName("爱回收严选手机旗舰店");
        }
        if (goods.getStoreRating() == null) {
            goods.setStoreRating(4.8);
        }
        if (goods.getStoreLevel() == null) {
            goods.setStoreLevel("钻石级");
        }
        if (goods.getShipping() == null) {
            goods.setShipping("包邮");
        }
        if (goods.getSalesCount() == null) {
            goods.setSalesCount(8600);
        }
        if (goods.getRating() == null) {
            goods.setRating(4.8);
        }
        Map<String, Object> data = new HashMap<>();
        data.put("goods", goods);
        return BaseResponse.success(data);
    }

    @PostMapping("/detail/queryStoreGoodsList")
    public BaseResponse<Map<String, Object>> queryStoreGoodsList(@RequestBody Map<String, Object> body) {
        String goodsId = body.get("goodsId") == null ? null : body.get("goodsId").toString();
        Goods goods = parseGoods(goodsId);
        if (goods == null) {
            return new BaseResponse<>("404", "商品不存在", null);
        }
        String categoryCode = goods.getCategoryCode();
        List<Goods> list = goodsRepository.findByCategoryCode(categoryCode, PageRequest.of(0, 10)).getContent();
        Map<String, Object> data = new HashMap<>();
        data.put("goodsList", list);
        return BaseResponse.success(data);
    }

    private Goods parseGoods(String goodsId) {
        if (goodsId == null || goodsId.isEmpty()) {
            return null;
        }
        try {
            Long id = Long.parseLong(goodsId);
            return goodsRepository.findById(id).orElse(null);
        } catch (NumberFormatException ex) {
            return null;
        }
    }
}
