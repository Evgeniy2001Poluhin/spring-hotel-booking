package com.example.booking.dto;

import lombok.Data;

import java.time.LocalDate;

@Data
public class CreateBookingRequest {
    private Long userId;
    private Boolean autoSelect = Boolean.FALSE; // если true — roomId игнорируется
    private Long roomId;                        // опционально
    private LocalDate startDate;
    private LocalDate endDate;
    private String requestId;                   // идемпотентность
}
