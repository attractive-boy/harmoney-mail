package com.example.servers.cart;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface CartItemRepository extends JpaRepository<CartItem, Long> {

    List<CartItem> findByStoreOrderByIdAsc(Store store);

    List<CartItem> findByCartOrderByIdAsc(Cart cart);

    List<CartItem> findByCartAndStoreOrderByIdAsc(Cart cart, Store store);

    CartItem findByCartAndCodeAndColorAndSize(Cart cart, String code, String color, String size);

    void deleteByCart(Cart cart);
}

