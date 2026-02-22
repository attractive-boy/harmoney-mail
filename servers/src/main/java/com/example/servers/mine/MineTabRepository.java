package com.example.servers.mine;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface MineTabRepository extends JpaRepository<MineTab, Long> {

    List<MineTab> findAllByOrderByIdAsc();
}

