package com.cityvoice.storage;

import io.minio.*;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.InputStream;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class MinioStorageService implements StorageService {

    private final MinioClient minioClient;

    @Value("${app.minio.bucket}")
    private String bucketName;

    @Value("${app.minio.endpoint}")
    private String endpoint;

    private static final List<String> ALLOWED_MIME_TYPES = List.of(
            "image/jpeg",
            "image/png",
            "image/webp");

    @PostConstruct
    public void init() {
        log.info("Initializing MinIO Storage Service for bucket: {}", bucketName);
        try {
            boolean isExist = minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucketName).build());
            if (!isExist) {
                log.info("Bucket {} does not exist, creating it.", bucketName);
                minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucketName).build());

                // Set bucket policy to public read so frontend can display incident images
                // directly
                String policy = """
                        {
                          "Statement": [
                            {
                              "Action": ["s3:GetObject"],
                              "Effect": "Allow",
                              "Principal": "*",
                              "Resource": ["arn:aws:s3:::%s/*"]
                            }
                          ],
                          "Version": "2012-10-17"
                        }
                        """.formatted(bucketName);
                minioClient.setBucketPolicy(
                        SetBucketPolicyArgs.builder().bucket(bucketName).config(policy).build());
            }
        } catch (Exception e) {
            log.error("Failed to initialize MinIO bucket: ", e);
            throw new RuntimeException("Could not initialize MinIO storage", e);
        }
    }

    @Override
    public String store(MultipartFile file, String prefix) {
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_MIME_TYPES.contains(contentType)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid image type. Allowed: JPG, PNG, WEBP");
        }

        try {
            String extension = getExtension(file.getOriginalFilename());
            String objectName = String.format("%s/%s%s", prefix, UUID.randomUUID(), extension);

            try (InputStream is = file.getInputStream()) {
                minioClient.putObject(
                        PutObjectArgs.builder()
                                .bucket(bucketName)
                                .object(objectName)
                                .stream(is, file.getSize(), -1)
                                .contentType(contentType)
                                .build());
            }

            // Return the public URL
            // Adjust to handle endpoint URLs containing trailing slashes or not
            String cleanEndpoint = endpoint.endsWith("/") ? endpoint.substring(0, endpoint.length() - 1) : endpoint;
            return String.format("%s/%s/%s", cleanEndpoint, bucketName, objectName);

        } catch (Exception e) {
            log.error("Failed to store file in MinIO", e);
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to upload file");
        }
    }

    @Override
    public void delete(String objectUrl) {
        try {
            // Extract the object name from the public URL
            String prefix = String.format("%s/%s/",
                    endpoint.endsWith("/") ? endpoint.substring(0, endpoint.length() - 1) : endpoint, bucketName);
            if (objectUrl.startsWith(prefix)) {
                String objectName = objectUrl.substring(prefix.length());
                minioClient.removeObject(
                        RemoveObjectArgs.builder().bucket(bucketName).object(objectName).build());
            }
        } catch (Exception e) {
            log.error("Failed to delete object from MinIO: {}", objectUrl, e);
        }
    }

    private String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) {
            return ".jpg"; // fallback
        }
        return filename.substring(filename.lastIndexOf(".")).toLowerCase();
    }
}
