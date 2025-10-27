package com.example.booking.service;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.example.booking.domain.Booking;
import com.example.booking.domain.BookingStatus;
import com.example.booking.repo.BookingRepository;
import com.example.booking.web.dto.BookingDto;
import com.example.booking.web.dto.CreateBookingRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDate;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;
import java.time.ZoneOffset;

@Service
public class BookingSagaService {
    private static final Logger log = LoggerFactory.getLogger(BookingSagaService.class);

    private final BookingRepository bookings;
    private final RestTemplate rt;

    public BookingSagaService(BookingRepository bookings, RestTemplate rt) {
        this.bookings = bookings;
        this.rt = rt;
    }

    @Transactional
    public BookingDto create(CreateBookingRequest req) {
        String requestId = Optional.ofNullable(req.requestId()).orElse(UUID.randomUUID().toString());

        // идемпотентность на нашем уровне
        var existing = bookings.findByRequestId(requestId);
        if (existing.isPresent()) {
            return toDto(existing.get());
        }

        var b = new Booking();
        b.setUserId(req.userId());
        b.setStartDate(req.startDate());
        b.setEndDate(req.endDate());
        b.setStatus(BookingStatus.PENDING);
        b.setRequestId(requestId);

        // Если не указан roomId или autoSelect=true — спросим у Hotel рекомендации
        Long roomId = req.roomId();
        if (Boolean.TRUE.equals(req.autoSelect()) || roomId == null) {
            roomId = autoSelectRoom(req.startDate(), req.endDate());
            if (roomId == null) {
                b.setStatus(BookingStatus.CANCELLED);
                bookings.save(b);
                return toDto(b);
            }
        }
        b.setRoomId(roomId);
        bookings.saveAndFlush(b); // фиксируем PENDING (шаг 1 саги)

        // Шаг 2: confirm-availability с ретраями
        boolean confirmed = false;
        try {
            confirmed = confirmAvailabilityWithRetry(roomId, requestId, b.getId(), req.startDate(), req.endDate());
        } catch (Exception e) {
            log.warn("confirm-availability failed: {}", e.toString());
        }

        if (confirmed) {
            b.setStatus(BookingStatus.CONFIRMED);
            bookings.save(b);
        } else {
            // компенсация
            try {
                release(roomId, requestId);
            } catch (Exception e) {
                log.warn("release compensation failed: {}", e.toString());
            }
            b.setStatus(BookingStatus.CANCELLED);
            bookings.save(b);
        }

        return toDto(b);
    }

    public List<BookingDto> listByUser(Long userId) {
        return bookings.findByUserId(userId).stream().map(BookingSagaService::toDto).toList();
    }

    public Optional<BookingDto> get(Long id) {
        return bookings.findById(id).map(BookingSagaService::toDto);
    }

    @Transactional
    public Optional<BookingDto> cancel(Long id) {
        return bookings.findById(id).map(b -> {
            if (b.getStatus() == BookingStatus.CONFIRMED || b.getStatus() == BookingStatus.PENDING) {
                // мягкая компенсация — просто CANCELLED; (в бою стоило бы позвать Hotel release, если ещё держим блокировку)
                b.setStatus(BookingStatus.CANCELLED);
                bookings.save(b);
            }
            return toDto(b);
        });
    }

    private static BookingDto toDto(Booking b) {
        return new BookingDto(
                b.getId(), b.getUserId(), b.getRoomId(),
                b.getStartDate(), b.getEndDate(),
                b.getStatus(), b.getRequestId(), b.getCreatedAt().atOffset(java.time.ZoneOffset.UTC)
        );
    }

    // === Hotel API DTOs (минимум) ===
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record RoomDto(Long id, @JsonProperty("timesBooked") long timesBooked) {}

    // === Calls to Hotel ===

    private Long autoSelectRoom(LocalDate start, LocalDate end) {
        String url = "http://hotel-service/api/rooms/recommend?startDate=" + start + "&endDate=" + end;
        ResponseEntity<RoomDto[]> resp = rt.getForEntity(url, RoomDto[].class);
        if (!resp.getStatusCode().is2xxSuccessful() || resp.getBody() == null) return null;
        if (resp.getBody().length == 0) return null;
        return Arrays.stream(resp.getBody())
                .min(Comparator.comparingLong(RoomDto::timesBooked).thenComparing(RoomDto::id))
                .map(RoomDto::id)
                .orElse(null);
    }

    private boolean confirmAvailabilityWithRetry(Long roomId, String requestId, Long bookingId,
                                                 LocalDate start, LocalDate end) {
        int attempts = 0;
        int maxAttempts = 3;
        while (attempts < maxAttempts) {
            attempts++;
            try {
                String url = "http://hotel-service/api/rooms/" + roomId + "/confirm-availability";
                Map<String, Object> body = Map.of(
                        "startDate", start.toString(),
                        "endDate", end.toString(),
                        "requestId", requestId,
                        "bookingId", "b-" + bookingId
                );
                ResponseEntity<String> resp = rt.postForEntity(url, body, String.class);
                if (resp.getStatusCode().is2xxSuccessful()) return true;
            } catch (Exception e) {
                // backoff 100..300ms * attempt
                long sleep = (100L + ThreadLocalRandom.current().nextLong(200)) * attempts;
                try { Thread.sleep(sleep); } catch (InterruptedException ignored) {}
            }
        }
        return false;
    }

    private void release(Long roomId, String requestId) {
        String url = "http://hotel-service/api/rooms/" + roomId + "/release";
        HttpHeaders h = new HttpHeaders();
        h.set("X-Request-Id", requestId);
        rt.exchange(url, HttpMethod.POST, new HttpEntity<>(h), String.class);
    }
}
