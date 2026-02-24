package com.example.servers.auth;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    Optional<User> findByPhone(String phone);
    Optional<User> findByAuthToken(String authToken);

    boolean existsByEmail(String email);
    boolean existsByPhone(String phone);

    // 管理端：按状态+关键字搜索
    @Query("SELECT u FROM User u WHERE " +
            "(:status IS NULL OR u.status = :status) AND " +
            "(:keyword IS NULL OR :keyword = '' OR " +
            " LOWER(COALESCE(u.email, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            " LOWER(COALESCE(u.phone, '')) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            " LOWER(COALESCE(u.nickname, '')) LIKE LOWER(CONCAT('%', :keyword, '%')))")
    Page<User> adminSearch(@Param("status") String status, @Param("keyword") String keyword, Pageable pageable);

    long countByStatus(String status);
}
