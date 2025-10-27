package com.example.booking.dto;

public class RoomDto {
    private Long id;
    private Long hotelId;
    private String number;
    private Boolean available;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getHotelId() { return hotelId; }
    public void setHotelId(Long hotelId) { this.hotelId = hotelId; }

    public String getNumber() { return number; }
    public void setNumber(String number) { this.number = number; }

    public Boolean getAvailable() { return available; }
    public void setAvailable(Boolean available) { this.available = available; }
}
