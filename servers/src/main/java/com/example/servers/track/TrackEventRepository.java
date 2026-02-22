package com.example.servers.track;

import org.springframework.data.jpa.repository.JpaRepository;

public interface TrackEventRepository extends JpaRepository<TrackEvent, Long> {
}
