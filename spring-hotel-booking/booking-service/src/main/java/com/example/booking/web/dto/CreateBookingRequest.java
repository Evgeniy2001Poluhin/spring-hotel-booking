package com.example.booking.web.dto;

import java.time.LocalDate;

public record CreateBookingRequest(
        Long userId,
        Long roomId,
        Boolean autoSelect,   // при true roomId игнорируется
        LocalDate startDate,
        LocalDate endDate,
        String requestId      // опционально, если null — сгенерируем
) {}
