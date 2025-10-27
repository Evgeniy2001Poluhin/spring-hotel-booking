package com.example.hotel.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                // actuator для диагностики
                .requestMatchers("/actuator/**").permitAll()
                // публичный read для отелей
                .requestMatchers(HttpMethod.GET, "/hotels/**", "/hotel/**").permitAll()
                // preflight
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                // остальное — авторизация (по желанию можно ослабить)
                .anyRequest().authenticated()
            )
            .httpBasic(basic -> {});
        return http.build();
    }
}
