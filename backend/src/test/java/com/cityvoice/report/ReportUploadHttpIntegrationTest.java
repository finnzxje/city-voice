package com.cityvoice.report;

import com.cityvoice.security.JwtUtil;
import com.cityvoice.storage.StorageService;
import com.cityvoice.user.entity.User;
import com.cityvoice.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verifyNoInteractions;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class ReportUploadHttpIntegrationTest {

    @LocalServerPort
    private int port;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtUtil jwtUtil;

    @MockitoBean
    private StorageService storageService;

    @Test
    void tc03_imageLargerThanTenMegabytesIsRejectedBeforeStorageUpload() throws Exception {
        User citizen = userRepository.findByEmail("citizen@cityvoice.vn").orElseThrow();
        String boundary = "cityvoice-tc03-boundary";
        byte[] requestBody = oversizedJpegMultipart(boundary);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:" + port + "/api/reports"))
                .header("Authorization", "Bearer " + jwtUtil.generateAccessToken(citizen))
                .header("Content-Type", "multipart/form-data; boundary=" + boundary)
                .POST(HttpRequest.BodyPublishers.ofByteArray(requestBody))
                .build();

        HttpResponse<String> response = HttpClient.newHttpClient()
                .send(request, HttpResponse.BodyHandlers.ofString());

        assertThat(response.statusCode()).isEqualTo(HttpStatus.PAYLOAD_TOO_LARGE.value());
        assertThat(response.body()).contains("\"code\":413");
        verifyNoInteractions(storageService);
    }

    @Test
    void tc15_resolveWithoutProofImageIsRejectedBeforeStorageUpload() throws Exception {
        User staff = userRepository.findByEmail("staff@cityvoice.vn").orElseThrow();
        String boundary = "cityvoice-tc15-boundary";
        byte[] requestBody = noteOnlyMultipart(boundary);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:" + port + "/api/reports/"
                        + UUID.randomUUID() + "/resolve"))
                .header("Authorization", "Bearer " + jwtUtil.generateAccessToken(staff))
                .header("Content-Type", "multipart/form-data; boundary=" + boundary)
                .POST(HttpRequest.BodyPublishers.ofByteArray(requestBody))
                .build();

        HttpResponse<String> response = HttpClient.newHttpClient()
                .send(request, HttpResponse.BodyHandlers.ofString());

        assertThat(response.statusCode()).isEqualTo(HttpStatus.BAD_REQUEST.value());
        assertThat(response.body()).contains("\"code\":400");
        verifyNoInteractions(storageService);
    }

    private byte[] oversizedJpegMultipart(String boundary) {
        byte[] prefix = ("--" + boundary + "\r\n"
                + "Content-Disposition: form-data; name=\"image\"; filename=\"oversized.jpg\"\r\n"
                + "Content-Type: image/jpeg\r\n\r\n").getBytes(StandardCharsets.UTF_8);
        byte[] fileContent = new byte[10 * 1024 * 1024 + 1];
        byte[] suffix = ("\r\n--" + boundary + "--\r\n").getBytes(StandardCharsets.UTF_8);
        byte[] body = new byte[prefix.length + fileContent.length + suffix.length];

        System.arraycopy(prefix, 0, body, 0, prefix.length);
        System.arraycopy(fileContent, 0, body, prefix.length, fileContent.length);
        System.arraycopy(suffix, 0, body, prefix.length + fileContent.length, suffix.length);
        return body;
    }

    private byte[] noteOnlyMultipart(String boundary) {
        return ("--" + boundary + "\r\n"
                + "Content-Disposition: form-data; name=\"note\"\r\n\r\n"
                + "Resolved without evidence\r\n"
                + "--" + boundary + "--\r\n").getBytes(StandardCharsets.UTF_8);
    }
}
