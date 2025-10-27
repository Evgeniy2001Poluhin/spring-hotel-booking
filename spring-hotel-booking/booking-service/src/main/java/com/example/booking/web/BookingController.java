package com.example.booking.web;

import com.example.booking.dto.BookingDto;
import com.example.booking.dto.CreateBookingRequest;
import com.example.booking.service.BookingService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/booking")
@RequiredArgsConstructor
public class BookingController {
    private final BookingService bookingService;

    // СОЗДАТЬ БРОНЬ
    @PostMapping
    public BookingDto create(@RequestBody CreateBookingRequest req) {
        return bookingService.create(req);
    }

    // ИСТОРИЯ ПОЛЬЗОВАТЕЛЯ (должен быть выше, чем /{id})
    @GetMapping("/bookings")
    public List<BookingDto> userBookings(@RequestParam("userId") Long userId) {
        return bookingService.findByUser(userId);
    }

    // ПОЛУЧИТЬ ПО ID (только цифры)
    @GetMapping("/{id:\\d+}")
    public BookingDto getById(@PathVariable Long id) {
        return bookingService.findById(id);
    }

    // УДАЛИТЬ/ОТМЕНИТЬ (только цифры)
    @DeleteMapping("/{id:\\d+}")
    public void cancel(@PathVariable Long id) {
        bookingService.cancel(id);
    }

    // SMOKE
    @GetMapping("/ping")
    public Map<String, String> ping() {
        return Map.of("service", "booking", "status", "ok");
    }
}
