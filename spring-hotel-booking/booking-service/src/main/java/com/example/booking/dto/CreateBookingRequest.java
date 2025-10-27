package com.example.booking.dto;

import java.time.LocalDate;

public class CreateBookingRequest {
    private Long userId;
    private Long roomId;
    private LocalDate startDate;
    private LocalDate endDate;
    private String requestId;
    private Boolean autoSelect;

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Long getRoomId() { return roomId; }
    public void setRoomId(Long roomId) { this.roomId = roomId; }

    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }

    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }

    public String getRequestId() { return requestId; }
    public void setRequestId(String requestId) { this.requestId = requestId; }

    public Boolean getAutoSelect() { return autoSelect; }
    public void setAutoSelect(Boolean autoSelect) { this.autoSelect = autoSelect; }
}
