package com.example.servers.coupon;

import org.springframework.data.jpa.repository.JpaRepository;

import java.math.BigDecimal;
import java.util.List;

public interface CouponRepository extends JpaRepository<Coupon, Long> {

    List<Coupon> findByUserIdAndStatus(String userId, String status);

    List<Coupon> findByUserId(String userId);

    long countByUserIdAndStatus(String userId, String status);

    List<Coupon> findByUserIdAndStatusAndMinOrderAmountLessThanEqual(
            String userId, String status, BigDecimal minOrderAmount);
}
