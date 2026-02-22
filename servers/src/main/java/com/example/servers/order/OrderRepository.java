package com.example.servers.order;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface OrderRepository extends JpaRepository<Order, Long> {
    
    Page<Order> findByUserId(String userId, Pageable pageable);
    
    Page<Order> findByUserIdAndStatus(String userId, String status, Pageable pageable);
    
    List<Order> findByUserId(String userId);
    
    Order findByOrderNo(String orderNo);
}
