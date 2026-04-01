import { useState } from "react";

const ImageZoom = ({ src }: { src: string }) => {
    const [isMaximized, setIsMaximized] = useState(false);
    if (!src) return null;

    const fullSrc = src.replace("http://minio:9000", "http://localhost:9000");

    return (
        <>
            {/* Ảnh nhỏ hiển thị trong trang */}
            <div
                onClick={() => setIsMaximized(true)}
                className="relative w-48 h-32 rounded-lg overflow-hidden border-2 border-green-200 cursor-zoom-in group"
            >
                <img
                    src={fullSrc}
                    className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
                    alt="Thumbnail"
                />
                <div className="absolute inset-0 bg-black/10 group-hover:bg-transparent" />
            </div>

            {/* Lớp phủ phóng to toàn màn hình */}
            {isMaximized && (
                <div
                    className="fixed inset-0 z-999 flex items-center justify-center bg-black/90 backdrop-blur-sm cursor-zoom-out p-4"
                    onClick={() => setIsMaximized(false)}
                >
                    <img
                        src={fullSrc}
                        className="max-w-full max-h-full rounded shadow-2xl transition-all duration-300 scale-95 animate-in zoom-in-90"
                        alt="Full size"
                    />
                    <button className="absolute top-5 right-5 text-white text-4xl">&times;</button>
                </div>
            )}
        </>
    );
};

export default ImageZoom;