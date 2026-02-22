package com.example.servers;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MockApiController {

    private final ApiMockRepository repository;

    public MockApiController(ApiMockRepository repository) {
        this.repository = repository;
    }

    @PostMapping("/**")
    public ResponseEntity<String> handlePost(HttpServletRequest request) {
        String path = request.getRequestURI();
        return repository.findByPathAndMethod(path, "POST")
                .map(api -> ResponseEntity.ok()
                        .contentType(MediaType.APPLICATION_JSON)
                        .body(api.getResponseBody()))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .contentType(MediaType.APPLICATION_JSON)
                        .body("{\"code\":\"404\",\"msg\":\"Not Found\",\"data\":null}"));
    }
}

