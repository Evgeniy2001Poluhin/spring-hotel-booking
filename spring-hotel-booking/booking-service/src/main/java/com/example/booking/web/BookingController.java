package com.example.booking.web;

import com.example.booking.dto.BookingDto;
import com.example.booking.dto.CreateBookingRequest;
import com.example.booking.service.BookingService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/booking")
public class BookingController {

    private final BookingService bookingService;

    public BookingController(BookingService bookingService) {
        this.bookingService = bookingService;
    }

    @GetMapping("/ping")
    public ResponseEntity<?> ping() {
        return ResponseEntity.ok().body(java.util.Map.of("service","booking","status","ok"));
    }

    @GetMapping("/smoke/ping2")
    public ResponseEntity<?> smokePing() {
        return ResponseEntity.ok().body(java.util.Map.of("service","booking","status","ok"));
    }

    @PostMapping
    public ResponseEntity<BookingDto> create(@RequestBody CreateBookingRequest req) {
        BookingDto dto = bookingService.create(req);
        return ResponseEntity.ok(dto);
    }
}
