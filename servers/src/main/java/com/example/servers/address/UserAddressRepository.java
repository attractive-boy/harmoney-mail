package com.example.servers.address;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserAddressRepository extends JpaRepository<UserAddress, Long> {

    List<UserAddress> findByUserIdOrderByIsDefaultDescCreatedAtDesc(String userId);

    Optional<UserAddress> findByUserIdAndIsDefaultTrue(String userId);

    long countByUserId(String userId);
}
