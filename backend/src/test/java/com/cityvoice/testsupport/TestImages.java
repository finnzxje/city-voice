package com.cityvoice.testsupport;

import org.springframework.mock.web.MockMultipartFile;

public final class TestImages {

    private TestImages() {
    }

    public static MockMultipartFile jpeg(String fieldName) {
        return new MockMultipartFile(
                fieldName,
                "incident.jpg",
                "image/jpeg",
                new byte[] {(byte) 0xff, (byte) 0xd8, (byte) 0xff, 0x00, 0x01, (byte) 0xff, (byte) 0xd9});
    }

    public static MockMultipartFile pdf(String fieldName) {
        return new MockMultipartFile(
                fieldName,
                "incident.pdf",
                "application/pdf",
                "%PDF-1.4".getBytes());
    }
}
