package com.example.servers.home;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface HomeNineMenuRepository extends JpaRepository<HomeNineMenu, Long> {

    List<HomeNineMenu> findAllByOrderByIdAsc();
}

