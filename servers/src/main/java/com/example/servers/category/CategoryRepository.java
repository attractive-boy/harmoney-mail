package com.example.servers.category;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface CategoryRepository extends JpaRepository<Category, Long> {

    List<Category> findByLevelOrderByIdAsc(Integer level);

    List<Category> findByParentCodeOrderByIdAsc(String parentCode);

    java.util.Optional<Category> findByCode(String code);
}

