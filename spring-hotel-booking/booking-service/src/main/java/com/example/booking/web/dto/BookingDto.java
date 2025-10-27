package com.example.booking.web.dto;

import com.example.booking.domain.BookingStatus;

import java.time.LocalDate;
import java.time.OffsetDateTime;

public record BookingDto(
        Long id,
        Long userId,
        Long roomId,
        LocalDate startDate,
        LocalDate endDate,
        BookingStatus status,
        String requestId,
        OffsetDateTime createdAt
) {}
