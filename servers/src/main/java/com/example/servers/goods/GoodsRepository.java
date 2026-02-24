package com.example.servers.goods;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface GoodsRepository extends JpaRepository<Goods, Long> {

    // 首页：type=2 推广商品排在最前
    @Query("SELECT g FROM Goods g ORDER BY CASE WHEN g.type = '2' THEN 0 ELSE 1 END, g.id DESC")
    Page<Goods> findAllWithType2First(Pageable pageable);

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

    // 管理端：按状态+关键字搜索
    @Query("SELECT g FROM Goods g WHERE " +
            "(:status IS NULL OR g.status = :status) AND " +
            "(:keyword IS NULL OR :keyword = '' OR " +
            " LOWER(COALESCE(g.description, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            " LOWER(COALESCE(g.tag, '')) LIKE LOWER(CONCAT('%', :keyword, '%')))") 
    Page<Goods> adminSearch(@Param("status") String status, @Param("keyword") String keyword, Pageable pageable);

    // 统计按分类的销通量
    @Query("SELECT g.categoryCode, SUM(g.salesCount) FROM Goods g WHERE g.status = 'ACTIVE' GROUP BY g.categoryCode")
    List<Object[]> sumSalesByCategory();

    // 按状态计数
    long countByStatus(String status);
}
