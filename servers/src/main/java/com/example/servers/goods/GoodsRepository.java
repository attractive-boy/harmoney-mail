package com.example.servers.goods;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface GoodsRepository extends JpaRepository<Goods, Long> {

    Page<Goods> findByCategoryCode(String categoryCode, Pageable pageable);

    // 分类页面：排除 type=2 的推广商品
    Page<Goods> findByCategoryCodeAndTypeNot(String categoryCode, String excludeType, Pageable pageable);
    
    // 排除 type=2 的所有商品
    Page<Goods> findByTypeNot(String excludeType, Pageable pageable);

    Page<Goods> findByRecommendTrue(Pageable pageable);

    @Query("SELECT g FROM Goods g WHERE " +
            "LOWER(COALESCE(g.description, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(g.tag, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(g.des1, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(g.des2, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(g.categoryCode, '')) LIKE LOWER(CONCAT('%', :keyword, '%'))")
    Page<Goods> searchByKeyword(@Param("keyword") String keyword, Pageable pageable);
    
    // 搜索：排除 type=2 的推广商品
    @Query("SELECT g FROM Goods g WHERE g.type != '2' AND (" +
            "LOWER(COALESCE(g.description, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(g.tag, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(g.des1, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(g.des2, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(COALESCE(g.categoryCode, '')) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    Page<Goods> searchByKeywordExcludeType2(@Param("keyword") String keyword, Pageable pageable);
    
    // 首页：type=2 的商品排在最前面
    @Query("SELECT g FROM Goods g ORDER BY " +
            "CASE WHEN g.type = '2' THEN 0 ELSE 1 END, " +
            "g.recommend DESC, g.salesCount DESC, g.rating DESC, g.createdAt DESC")
    Page<Goods> findAllWithType2First(Pageable pageable);
}
