package com.example.booking.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.OffsetDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BookingDto {
    private Long id;
    private Long userId;
    private Long roomId;
    private LocalDate startDate;
    private LocalDate endDate;
    private String status;              // PENDING/CONFIRMED/CANCELLED
    private OffsetDateTime createdAt;   // можно null, если в Entity нет
    // added by fix2
    private String requestId;
}
