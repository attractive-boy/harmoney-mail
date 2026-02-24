package com.example.servers.news;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ArticleRepository extends JpaRepository<Article, Long> {

    Page<Article> findByCategory(String category, Pageable pageable);

    Page<Article> findAllByOrderByPublishedAtDesc(Pageable pageable);
}
