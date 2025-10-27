package com.example.booking.service;

import com.example.booking.domain.Booking;
import com.example.booking.dto.BookingDto;
import org.springframework.stereotype.Component;

import java.time.ZoneOffset;

@Component
public class BookingMapper {

    public BookingDto toDto(Booking b) {
        if (b == null) return null;
        BookingDto dto = new BookingDto();
        dto.setId(b.getId());
        dto.setUserId(b.getUserId());
        dto.setRoomId(b.getRoomId());
        dto.setStartDate(b.getStartDate());
        dto.setEndDate(b.getEndDate());
        dto.setStatus(b.getStatus() == null ? null : b.getStatus().name()); // Enum совместим, если в DTO тоже Enum BookingStatus
        dto.setRequestId(b.getRequestId());
        dto.setCreatedAt(b.getCreatedAt() == null ? null : b.getCreatedAt().atOffset(ZoneOffset.UTC));
        return dto;
    }
}
