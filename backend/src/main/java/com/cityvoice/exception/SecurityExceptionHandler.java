package com.cityvoice.exception;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.time.Instant;

/**
 * Handles Spring Security filter-chain errors — these occur BEFORE the request
 * reaches any controller, so @ControllerAdvice cannot catch them.
 *
 * <ul>
 * <li>{@link AuthenticationEntryPoint} → no token / invalid token → 401</li>
 * <li>{@link AccessDeniedHandler} → valid token but wrong role → 403</li>
 * </ul>
 */
@Component
public class SecurityExceptionHandler implements AuthenticationEntryPoint, AccessDeniedHandler {

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    // 401 – No / invalid token
    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
            AuthenticationException ex) throws IOException {
        writeProblem(response, request, HttpStatus.UNAUTHORIZED,
                "Unauthorized", "Authentication required. Please provide a valid Bearer token.");
    }

    // 403 – Valid token but wrong role / permission
    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response,
            AccessDeniedException ex) throws IOException {
        writeProblem(response, request, HttpStatus.FORBIDDEN,
                "Forbidden", "You don't have permission to access this resource.");
    }

    private void writeProblem(HttpServletResponse response, HttpServletRequest request,
            HttpStatus status, String title, String detail) throws IOException {
        ProblemDetail problem = ProblemDetail.forStatus(status);
        problem.setTitle(title);
        problem.setDetail(detail);
        problem.setInstance(URI.create(request.getRequestURI()));
        problem.setProperty("timestamp", Instant.now());

        response.setStatus(status.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        MAPPER.writeValue(response.getWriter(), problem);
    }
}
