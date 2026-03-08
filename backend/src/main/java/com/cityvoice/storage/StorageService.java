package com.cityvoice.storage;

import org.springframework.web.multipart.MultipartFile;

public interface StorageService {
    /**
     * Stores a file and returns its absolute public URL.
     *
     * @param file The file to store
     *             incidents@param prefix Optional sub-directory or prefix (e.g.,
     *             "incidents")
     * @return The public URL to access the file
     */
    String store(MultipartFile file, String prefix);

    /**
     * Deletes a file given its public URL.
     *
     * @param objectUrl The public URL of the file to delete
     */
    void delete(String objectUrl);
}
