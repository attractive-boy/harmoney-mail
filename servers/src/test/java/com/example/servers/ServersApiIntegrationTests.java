package com.example.servers;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ServersApiIntegrationTests {

    @LocalServerPort
    private int port;

    private String url(String path) {
        return "http://localhost:" + port + path;
    }

    @Test
    void home_queryHomePageInfo() throws Exception {
        ResponseEntity<String> res = new org.springframework.web.client.RestTemplate()
                .postForEntity(url("/home/queryHomePageInfo"), null, String.class);
        assertThat(res.getStatusCode().is2xxSuccessful()).isTrue();
    }

    @Test
    void category_list() throws Exception {
        ResponseEntity<String> res = new org.springframework.web.client.RestTemplate()
                .postForEntity(url("/category/list"), null, String.class);
        assertThat(res.getStatusCode().is2xxSuccessful()).isTrue();
    }

    @Test
    void category_queryContentByCategory() throws Exception {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        String body = "{\"code\":\"0101\"}";
        HttpEntity<String> entity = new HttpEntity<>(body, headers);
        ResponseEntity<String> res = new org.springframework.web.client.RestTemplate().exchange(url("/category/queryContentByCategory"),
                HttpMethod.POST, entity, String.class);
        assertThat(res.getStatusCode().is2xxSuccessful()).isTrue();
    }

    @Test
    void common_queryGoodsListByPage() throws Exception {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        String body = "{\"code\":\"DEFAULT\",\"pageNo\":1,\"pageSize\":10}";
        HttpEntity<String> entity = new HttpEntity<>(body, headers);
        ResponseEntity<String> res = new org.springframework.web.client.RestTemplate().exchange(url("/common/queryGoodsListByPage"),
                HttpMethod.POST, entity, String.class);
        assertThat(res.getStatusCode().is2xxSuccessful()).isTrue();
    }

    @Test
    void mine_queryMineInfo() throws Exception {
        ResponseEntity<String> res = new org.springframework.web.client.RestTemplate()
                .postForEntity(url("/mine/queryMineInfo"), null, String.class);
        assertThat(res.getStatusCode().is2xxSuccessful()).isTrue();
    }

    @Test
    void cart_queryCartGoodsList() throws Exception {
        ResponseEntity<String> res = new org.springframework.web.client.RestTemplate()
                .postForEntity(url("/cart/queryCartGoodsList"), null, String.class);
        assertThat(res.getStatusCode().is2xxSuccessful()).isTrue();
    }

    @Test
    void cart_queryMaybeLikeList() throws Exception {
        ResponseEntity<String> res = new org.springframework.web.client.RestTemplate()
                .postForEntity(url("/cart/queryMaybeLikeList"), null, String.class);
        assertThat(res.getStatusCode().is2xxSuccessful()).isTrue();
    }

    @Test
    void common_login() throws Exception {
        ResponseEntity<String> res = new org.springframework.web.client.RestTemplate()
                .postForEntity(url("/common/login"), null, String.class);
        assertThat(res.getStatusCode().is2xxSuccessful()).isTrue();
    }

    @Test
    void detail_queryGoodsDetail() throws Exception {
        ResponseEntity<String> res = new org.springframework.web.client.RestTemplate()
                .postForEntity(url("/detail/queryGoodsDetail"), null, String.class);
        assertThat(res.getStatusCode().is2xxSuccessful()).isTrue();
    }

    @Test
    void detail_queryStoreGoodsList() throws Exception {
        ResponseEntity<String> res = new org.springframework.web.client.RestTemplate()
                .postForEntity(url("/detail/queryStoreGoodsList"), null, String.class);
        assertThat(res.getStatusCode().is2xxSuccessful()).isTrue();
    }

    @Test
    void example_queryContactList() throws Exception {
        ResponseEntity<String> res = new org.springframework.web.client.RestTemplate()
                .postForEntity(url("/example/queryContactList"), null, String.class);
        assertThat(res.getStatusCode().is2xxSuccessful()).isTrue();
    }

    @Test
    void mine_queryRecommendList() throws Exception {
        ResponseEntity<String> res = new org.springframework.web.client.RestTemplate()
                .postForEntity(url("/mine/queryRecommendList"), null, String.class);
        assertThat(res.getStatusCode().is2xxSuccessful()).isTrue();
    }
}
