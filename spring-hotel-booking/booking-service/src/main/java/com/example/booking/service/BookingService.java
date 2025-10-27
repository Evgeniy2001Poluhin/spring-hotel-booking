package com.example.booking.service;

import com.example.booking.domain.Booking;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import com.example.booking.dto.BookingDto;
import com.example.booking.dto.CreateBookingRequest;
import com.example.booking.repo.BookingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class BookingService {
    private static final Logger log = LoggerFactory.getLogger(BookingService.class);

    private final BookingRepository bookingRepository;
    private final HotelClient hotelClient;
    private final BookingMapper mapper;

    @Transactional
    public BookingDto create(CreateBookingRequest req) {
        LocalDate start = req.getStartDate();
        LocalDate end = req.getEndDate();
        String requestId = req.getRequestId();

        Long roomId = req.getAutoSelect()
                ? hotelClient.recommend(start, end).stream()
                    .findFirst()
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.CONFLICT, "No rooms available for period"))
                    .getId()
                : req.getRoomId();

        Booking booking = bookingRepository.save(
                Booking.pending(req.getUserId(), roomId, start, end, requestId)
        );

        boolean confirmed = false;
        try {
            hotelClient.confirmAvailability(roomId, start, end, requestId);
            booking.confirm();
            confirmed = true;
            return mapper.toDto(bookingRepository.save(booking));
        } catch (Exception e) {
            log.error("Confirm failed, will cancel. bookingId={}, cause={}", booking.getId(), e.toString());
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Hotel confirmation failed");
        } finally {
            if (!confirmed) {
                try {
                    hotelClient.release(roomId, requestId);
                } catch (Exception ex) {
                    log.warn("Release failed (compensation). roomId={}, cause={}", roomId, ex.toString());
                }
                booking.cancel();
                bookingRepository.save(booking);
            }
        }
    }

    public List<BookingDto> findByUser(Long userId) {
        return bookingRepository.findByUserId(userId).stream().map(mapper::toDto).toList();
    }

    public BookingDto findById(Long id) {
        return bookingRepository.findById(id)
                .map(mapper::toDto)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Booking not found"));
    }

    @Transactional
    public void cancel(Long id) {
        Booking booking = bookingRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Booking not found"));
        booking.cancel();
        bookingRepository.save(booking);
    }
}
