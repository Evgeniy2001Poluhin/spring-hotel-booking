package com.example.hotel.web;

import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/api")
public class SmokeController {

    @GetMapping("/hotels")
    public List<Map<String, Object>> hotels() {
        List<Map<String, Object>> list = new ArrayList<>();
        list.add(Map.of("id", 1, "name", "demo-hotel-1", "address", "Center st. 1"));
        list.add(Map.of("id", 2, "name", "demo-hotel-2", "address", "Main ave. 2"));
        return list;
    }

    @PostMapping("/hotels")
    public Map<String, Object> createHotel(@RequestBody Map<String, Object> req) {
        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("id", new Random().nextInt(100000));
        resp.put("name", req.get("name"));
        resp.put("address", req.get("address"));
        return resp;
    }

    @PostMapping("/rooms/{id}/release")
    public Map<String, Object> release(
            @PathVariable Long id,
            @RequestHeader(value = "X-Request-Id", required = false) String requestId
    ) {
        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("status", "released");
        resp.put("roomId", id);
        resp.put("requestId", requestId);
        return resp;
    }
}
