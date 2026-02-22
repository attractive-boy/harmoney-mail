package com.example.servers.mine;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface MineFunctionRepository extends JpaRepository<MineFunction, Long> {

    List<MineFunction> findAllByOrderByIdAsc();
}

