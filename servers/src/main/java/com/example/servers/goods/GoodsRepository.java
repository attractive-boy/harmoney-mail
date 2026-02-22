package com.example.servers.goods;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface GoodsRepository extends JpaRepository<Goods, Long> {

    Page<Goods> findByCategoryCode(String categoryCode, Pageable pageable);

    Page<Goods> findByRecommendTrue(Pageable pageable);

    @Query("SELECT g FROM Goods g WHERE g.description LIKE %:keyword% OR g.tag LIKE %:keyword%")
    Page<Goods> searchByKeyword(@Param("keyword") String keyword, Pageable pageable);
}

