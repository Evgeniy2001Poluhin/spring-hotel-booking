package com.example.booking.service;

import com.example.booking.dto.RoomDto;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Duration;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Component
@Slf4j
public class HotelClient {

    private final WebClient webClient;

    public HotelClient(WebClient.Builder builder) {
        // через Eureka + Spring Cloud LoadBalancer:
        // либо baseUrl("http://hotel-service"), либо без baseUrl и полный путь в каждом вызове
        this.webClient = builder
                .baseUrl("http://hotel-service")
                .build();
    }

    public List<RoomDto> recommend(LocalDate start, LocalDate end) {
        return webClient.get()
                .uri(uri -> uri.path("/api/rooms/recommend")
                        .queryParam("start", start)
                        .queryParam("end", end)
                        .build())
                .retrieve()
                .onStatus(HttpStatusCode::isError, resp ->
                        resp.bodyToMono(String.class).map(msg ->
                                new IllegalStateException("Hotel recommend failed: " + msg)))
                .bodyToFlux(RoomDto.class)
                .collectList()
                .block(Duration.ofSeconds(5));
    }

    public void confirmAvailability(long roomId, LocalDate start, LocalDate end, String requestId) {
        webClient.post()
                .uri("/api/rooms/{id}/confirm-availability", roomId)
                .header("X-Request-Id", requestId)
                .bodyValue(Map.of("start", start.toString(), "end", end.toString()))
                .retrieve()
                .onStatus(HttpStatusCode::isError, resp ->
                        resp.bodyToMono(String.class).map(msg ->
                                new IllegalStateException("Hotel confirm failed: " + msg)))
                .toBodilessEntity()
                .block(Duration.ofSeconds(5));
    }

    public void release(long roomId, String requestId) {
        webClient.post()
                .uri("/api/rooms/{id}/release", roomId)
                .header("X-Request-Id", requestId)
                .retrieve()
                .toBodilessEntity()
                .block(Duration.ofSeconds(5));
    }
}
