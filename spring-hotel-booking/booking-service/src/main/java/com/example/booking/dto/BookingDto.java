package com.example.booking.dto;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import com.example.booking.domain.BookingStatus;

public class BookingDto {

    public BookingDto(Long id, Long userId, Long roomId,
                        java.time.LocalDate startDate, java.time.LocalDate endDate,
                        BookingStatus statusEnum, String requestId, java.time.OffsetDateTime createdAt) {
        this.id = id;
        this.userId = userId;
        this.roomId = roomId;
        this.startDate = startDate;
        this.endDate = endDate;
        this.status = (statusEnum != null ? statusEnum.name() : null);
        this.requestId = requestId;
        this.createdAt = createdAt;
    }

    public BookingDto() {}
    private Long id;
    private Long userId;
    private Long roomId;
    private LocalDate startDate;
    private LocalDate endDate;
    private String status;
    private String requestId;
    private OffsetDateTime createdAt;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Long getRoomId() { return roomId; }
    public void setRoomId(Long roomId) { this.roomId = roomId; }

    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }

    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getRequestId() { return requestId; }
    public void setRequestId(String requestId) { this.requestId = requestId; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
