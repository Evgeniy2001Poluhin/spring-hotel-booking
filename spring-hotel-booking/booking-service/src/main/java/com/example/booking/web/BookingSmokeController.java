package com.example.booking.web;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/booking/smoke")
public class BookingSmokeController {

    @GetMapping("/ping")
    public Map<String, String> pingSmoke() {
        return Map.of("service", "booking", "status", "ok");
    }
}
