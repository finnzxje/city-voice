package com.cityvoice.exception;

import com.cityvoice.common.dto.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartException;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;
import java.util.stream.Collectors;

/**
 * Centralized exception handler for all controller/service layer errors.
 * Spring Security filter-level errors (unauthenticated, forbidden) are
 * handled separately by {@link SecurityExceptionHandler}.
 */
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

        // ── ResponseStatusException ──────────────────────────────────────────────

        @ExceptionHandler(ResponseStatusException.class)
        public ResponseEntity<ApiResponse<Object>> handleResponseStatusException(
                        ResponseStatusException ex, HttpServletRequest request) {
                if (ex.getStatusCode().is5xxServerError()) {
                        log.error("[{}] {} → {}", request.getMethod(), request.getRequestURI(), ex.getReason(), ex);
                } else {
                        log.debug("[{}] {} → {} {}", request.getMethod(), request.getRequestURI(),
                                        ex.getStatusCode().value(), ex.getReason());
                }

                String message = ex.getReason() != null ? ex.getReason() : "Lỗi không xác định";
                return ResponseEntity.status(ex.getStatusCode())
                                .body(ApiResponse.error(ex.getStatusCode().value(), message));
        }

        // ── AccessDeniedException ────────────────────────────────────────────────

        @ExceptionHandler(AccessDeniedException.class)
        public ResponseEntity<ApiResponse<Object>> handleAccessDenied(
                        AccessDeniedException ex, HttpServletRequest request) {
                log.debug("[{}] {} → 403 Access Denied", request.getMethod(), request.getRequestURI());
                return ResponseEntity.status(HttpStatus.FORBIDDEN)
                                .body(ApiResponse.error(HttpStatus.FORBIDDEN.value(),
                                                "Bạn không có quyền truy cập vào tài nguyên này."));
        }

        // ── Validation errors ────────────────────────────────────────────────────

        @ExceptionHandler(MethodArgumentNotValidException.class)
        public ResponseEntity<ApiResponse<Map<String, String>>> handleValidation(
                        MethodArgumentNotValidException ex, HttpServletRequest request) {
                Map<String, String> fieldErrors = ex.getBindingResult().getFieldErrors().stream()
                                .collect(Collectors.toMap(
                                                FieldError::getField,
                                                fe -> fe.getDefaultMessage() != null ? fe.getDefaultMessage()
                                                                : "Giá trị không hợp lệ",
                                                (a, b) -> a));
                log.debug("[{}] {} → 400 Validation Failed", request.getMethod(), request.getRequestURI());
                return ResponseEntity.badRequest()
                                .body(ApiResponse.error(HttpStatus.BAD_REQUEST.value(), "Dữ liệu không hợp lệ",
                                                fieldErrors));
        }

        @ExceptionHandler(MethodArgumentTypeMismatchException.class)
        public ResponseEntity<ApiResponse<Object>> handleTypeMismatch(
                        MethodArgumentTypeMismatchException ex, HttpServletRequest request) {
                log.debug("[{}] {} → 400 Type Mismatch", request.getMethod(), request.getRequestURI());
                String detail = String.format("Tham số '%s' phải có kiểu %s",
                                ex.getName(),
                                ex.getRequiredType() != null ? ex.getRequiredType().getSimpleName() : "không xác định");
                return ResponseEntity.badRequest()
                                .body(ApiResponse.error(HttpStatus.BAD_REQUEST.value(), detail));
        }

        // ── Multipart / file upload errors ────────────────────────────────────────

        @ExceptionHandler(MaxUploadSizeExceededException.class)
        public ResponseEntity<ApiResponse<Object>> handleMaxUploadSizeExceeded(
                        MaxUploadSizeExceededException ex, HttpServletRequest request) {
                log.debug("[{}] {} → 413 File too large", request.getMethod(), request.getRequestURI());
                return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE)
                                .body(ApiResponse.error(HttpStatus.PAYLOAD_TOO_LARGE.value(),
                                                "Kích thước tệp tải lên vượt quá giới hạn cho phép."));
        }

        @ExceptionHandler(MultipartException.class)
        public ResponseEntity<ApiResponse<Object>> handleMultipart(
                        MultipartException ex, HttpServletRequest request) {
                log.debug("[{}] {} → 400 Malformed multipart", request.getMethod(), request.getRequestURI());
                return ResponseEntity.badRequest()
                                .body(ApiResponse.error(HttpStatus.BAD_REQUEST.value(),
                                                "Yêu cầu multipart không hợp lệ hoặc luồng tệp bị gián đoạn."));
        }

        // ── Fallback ─────────────────────────────────────────────────────────────

        @ExceptionHandler(Exception.class)
        public ResponseEntity<ApiResponse<Object>> handleGenericException(
                        Exception ex, HttpServletRequest request) {
                log.error("[{}] {} → 500 Unhandled exception", request.getMethod(), request.getRequestURI(), ex);
                return ResponseEntity.internalServerError()
                                .body(ApiResponse.error(HttpStatus.INTERNAL_SERVER_ERROR.value(),
                                                "Đã xảy ra lỗi không mong đợi. Vui lòng thử lại sau."));
        }
}
