package com.example.hotel;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.List;

@RestController
@RequestMapping("/hotels")
public class HotelController {

    @GetMapping
    public List<String> getAllHotels() {
        return List.of("Hotel 1", "Hotel 2", "Hotel 3");
    }
}
