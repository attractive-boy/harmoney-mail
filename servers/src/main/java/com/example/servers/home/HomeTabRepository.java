package com.example.servers.home;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface HomeTabRepository extends JpaRepository<HomeTab, Long> {

    List<HomeTab> findAllByOrderByIdAsc();
}

