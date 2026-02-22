package com.example.servers.home;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface HomeConfigRepository extends JpaRepository<HomeConfig, Long> {

    Optional<HomeConfig> findTopByOrderByIdAsc();
}
