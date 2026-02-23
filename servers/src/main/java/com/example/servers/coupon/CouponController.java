package com.example.servers.coupon;

import com.example.servers.BaseResponse;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@RestController
public class CouponController {

    private final CouponRepository couponRepository;

    public CouponController(CouponRepository couponRepository) {
        this.couponRepository = couponRepository;
    }

    @PostMapping("/coupon/list")
    public BaseResponse<List<Map<String, Object>>> listCoupons(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        String status = getStringValue(body, "status", null);

        // 首次调用若无数据自动种入3张演示红包
        List<Coupon> allCoupons = couponRepository.findByUserId(userId);
        if (allCoupons.isEmpty()) {
            seedDemoCoupons(userId);
        }

        List<Coupon> coupons;
        if (status != null && !status.isEmpty()) {
            coupons = couponRepository.findByUserIdAndStatus(userId, status);
        } else {
            coupons = couponRepository.findByUserId(userId);
        }

        List<Map<String, Object>> result = new ArrayList<>();
        for (Coupon c : coupons) {
            result.add(couponToMap(c));
        }
        return BaseResponse.success(result);
    }

    @PostMapping("/coupon/receive")
    @Transactional
    public BaseResponse<Map<String, Object>> receiveCoupon(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Random random = new Random();
        int cents = 200 + random.nextInt(1801); // 2.00 ~ 20.00 yuan in cents
        BigDecimal amount = BigDecimal.valueOf(cents).scaleByPowerOfTen(-2);

        Coupon coupon = new Coupon();
        coupon.setUserId(userId);
        coupon.setName("限时购物红包");
        coupon.setAmount(amount);
        coupon.setType("NO_THRESHOLD");
        coupon.setMinOrderAmount(BigDecimal.ZERO);
        coupon.setStatus("UNUSED");
        coupon.setExpireAt(LocalDateTime.now().plusDays(30));
        coupon = couponRepository.save(coupon);

        return BaseResponse.success(couponToMap(coupon));
    }

    @PostMapping("/coupon/available")
    public BaseResponse<List<Map<String, Object>>> availableCoupons(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        BigDecimal orderAmount = getBigDecimalValue(body, "orderAmount", BigDecimal.ZERO);

        // 首次调用若无数据自动种入3张演示红包
        List<Coupon> allCoupons = couponRepository.findByUserId(userId);
        if (allCoupons.isEmpty()) {
            seedDemoCoupons(userId);
        }

        List<Coupon> coupons = couponRepository.findByUserIdAndStatusAndMinOrderAmountLessThanEqual(
                userId, "UNUSED", orderAmount);

        List<Map<String, Object>> result = new ArrayList<>();
        for (Coupon c : coupons) {
            result.add(couponToMap(c));
        }
        return BaseResponse.success(result);
    }

    @PostMapping("/coupon/use")
    @Transactional
    public BaseResponse<String> useCoupon(@RequestBody Map<String, Object> body) {
        String userId = resolveUserId(body);
        Long couponId = getLongValue(body, "couponId", null);

        if (couponId == null) {
            return new BaseResponse<>("400", "couponId不能为空", null);
        }

        Optional<Coupon> opt = couponRepository.findById(couponId);
        if (opt.isEmpty()) {
            return new BaseResponse<>("404", "红包不存在", null);
        }

        Coupon coupon = opt.get();
        if (!coupon.getUserId().equals(userId)) {
            return new BaseResponse<>("403", "无权操作该红包", null);
        }
        if (!"UNUSED".equals(coupon.getStatus())) {
            return new BaseResponse<>("400", "红包已使用或已过期", null);
        }

        coupon.setStatus("USED");
        couponRepository.save(coupon);
        return BaseResponse.success("红包已使用");
    }

    private void seedDemoCoupons(String userId) {
        LocalDateTime expireAt = LocalDateTime.now().plusDays(30);

        Coupon c1 = new Coupon();
        c1.setUserId(userId);
        c1.setName("无门槛红包");
        c1.setAmount(new BigDecimal("15.00"));
        c1.setType("NO_THRESHOLD");
        c1.setMinOrderAmount(BigDecimal.ZERO);
        c1.setStatus("UNUSED");
        c1.setExpireAt(expireAt);
        couponRepository.save(c1);

        Coupon c2 = new Coupon();
        c2.setUserId(userId);
        c2.setName("限时购物红包");
        c2.setAmount(new BigDecimal("5.00"));
        c2.setType("THRESHOLD");
        c2.setMinOrderAmount(new BigDecimal("100.00"));
        c2.setStatus("UNUSED");
        c2.setExpireAt(expireAt);
        couponRepository.save(c2);

        Coupon c3 = new Coupon();
        c3.setUserId(userId);
        c3.setName("新客专享红包");
        c3.setAmount(new BigDecimal("2.95"));
        c3.setType("NO_THRESHOLD");
        c3.setMinOrderAmount(BigDecimal.ZERO);
        c3.setStatus("UNUSED");
        c3.setExpireAt(expireAt);
        couponRepository.save(c3);
    }

    private Map<String, Object> couponToMap(Coupon c) {
        Map<String, Object> map = new HashMap<>();
        map.put("id", c.getId());
        map.put("userId", c.getUserId());
        map.put("name", c.getName());
        map.put("amount", c.getAmount());
        map.put("type", c.getType());
        map.put("minOrderAmount", c.getMinOrderAmount());
        map.put("status", c.getStatus());
        map.put("expireAt", c.getExpireAt());
        map.put("createdAt", c.getCreatedAt());
        return map;
    }

    private String resolveUserId(Map<String, Object> body) {
        Object userIdObj = body.get("userId");
        return userIdObj == null || userIdObj.toString().isEmpty() ? "guest" : userIdObj.toString();
    }

    private String getStringValue(Map<String, Object> body, String key, String defaultValue) {
        Object value = body.get(key);
        return value == null ? defaultValue : value.toString();
    }

    private Long getLongValue(Map<String, Object> body, String key, Long defaultValue) {
        Object value = body.get(key);
        if (value == null) return defaultValue;
        try {
            return Long.parseLong(value.toString());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }

    private BigDecimal getBigDecimalValue(Map<String, Object> body, String key, BigDecimal defaultValue) {
        Object value = body.get(key);
        if (value == null) return defaultValue;
        try {
            return new BigDecimal(value.toString());
        } catch (NumberFormatException e) {
            return defaultValue;
        }
    }
}
