package com.example.servers.goods;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface GoodsRepository extends JpaRepository<Goods, Long> {

    Page<Goods> findByCategoryCode(String categoryCode, Pageable pageable);

    Page<Goods> findByRecommendTrue(Pageable pageable);

    @Query("SELECT g FROM Goods g WHERE " +
            "LOWER(COALESCE(g.description, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(g.tag, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(g.des1, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(g.des2, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(g.categoryCode, '')) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    Page<Goods> searchByKeyword(@Param("keyword") String keyword, Pageable pageable);
}

