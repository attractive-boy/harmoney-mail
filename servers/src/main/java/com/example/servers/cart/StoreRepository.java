package com.example.servers.cart;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface StoreRepository extends JpaRepository<Store, Long> {

    List<Store> findAllByOrderByIdAsc();

    Store findByStoreCode(String storeCode);
}

