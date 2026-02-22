package com.example.servers;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface ApiMockRepository extends JpaRepository<ApiMock, Long> {

    Optional<ApiMock> findByPathAndMethod(String path, String method);

    void deleteByPathAndMethod(String path, String method);
}

