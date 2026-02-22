package com.example.servers.track;

import com.example.servers.BaseResponse;
import com.example.servers.goods.Goods;
import com.example.servers.goods.GoodsRepository;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;

@RestController
public class TrackController {

    private final TrackEventRepository trackEventRepository;
    private final GoodsRepository goodsRepository;

    public TrackController(TrackEventRepository trackEventRepository,
                           GoodsRepository goodsRepository) {
        this.trackEventRepository = trackEventRepository;
        this.goodsRepository = goodsRepository;
    }

    @PostMapping("/common/trackEvent")
    public BaseResponse<Void> track(@RequestBody TrackRequest request) {
        if (request == null || request.goodsId == null || request.goodsId.isEmpty() || request.event == null || request.event.isEmpty()) {
            return new BaseResponse<>("400", "参数错误", null);
        }

        Long goodsId = parseGoodsId(request.goodsId);
        if (goodsId == null) {
            return new BaseResponse<>("400", "参数错误", null);
        }

        trackEventRepository.save(new TrackEvent(goodsId, request.event, Instant.now()));
        goodsRepository.findById(goodsId).ifPresent(goods -> updateGoodsStats(goods, request.event));
        return BaseResponse.success(null);
    }

    private void updateGoodsStats(Goods goods, String event) {
        Integer viewCount = goods.getViewCount() == null ? 0 : goods.getViewCount();
        Integer salesCount = goods.getSalesCount() == null ? 0 : goods.getSalesCount();
        switch (event) {
            case "impression":
            case "click":
                goods.setViewCount(viewCount + 1);
                break;
            case "purchase":
                goods.setSalesCount(salesCount + 1);
                break;
            default:
                break;
        }
        goodsRepository.save(goods);
    }

    static class TrackRequest {
        public String goodsId;
        public String event;
    }

    private Long parseGoodsId(String value) {
        try {
            return Long.parseLong(value);
        } catch (NumberFormatException ex) {
            return null;
        }
    }
}
