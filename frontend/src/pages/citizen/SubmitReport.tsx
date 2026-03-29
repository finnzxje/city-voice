import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { IncidentAPI, type Category } from "../../api/services";
import toast from "react-hot-toast";
import Header from "../../components/Header";
import Footer from "../../components/Footer";
import {
  Camera,
  MapPin,
  UploadCloud,
  AlertCircle,
  ArrowRight,
  ArrowLeft,
} from "lucide-react";

export default function SubmitReport() {
  const navigate = useNavigate();
  const [categories, setCategories] = useState<Category[]>([]);

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [latitude, setLatitude] = useState("");
  const [longitude, setLongitude] = useState("");
  const [image, setImage] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string>("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    // Fetch categories on mount
    const fetchCategories = async () => {
      try {
        const res = await IncidentAPI.getCategories();
        setCategories(res.data.data);
      } catch (err) {
        console.error("Failed to load categories", err);
      }
    };
    fetchCategories();

    // Try to get user location automatically
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setLatitude(position.coords.latitude.toString());
          setLongitude(position.coords.longitude.toString());
        },
        (error) => {
          console.error("Geolocation error:", error);
        },
      );
    }
  }, []);

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setImage(file);
      setImagePreview(URL.createObjectURL(file));
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    if (!image) {
      setError("Vui lòng cung cấp hình ảnh về sự cố.");
      toast.error("Vui lòng cung cấp hình ảnh về sự cố.");
      setLoading(false);
      return;
    }

    try {
      const formData = new FormData();
      formData.append("title", title);
      formData.append("description", description);
      formData.append("categoryId", categoryId);
      formData.append("latitude", latitude);
      formData.append("longitude", longitude);
      formData.append("image", image);

      await IncidentAPI.submitReport(formData);
      toast.success("Báo cáo đã được gửi thành công!");
      navigate("/citizen/dashboard");
    } catch (err: any) {
      const errorMessage =
        err.response?.data?.message ||
        "Gửi báo cáo thất bại. Đảm bảo vị trí của bạn nằm trong khu vực TP.HCM.";
      setError(errorMessage);
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-surface flex flex-col font-body">
      <Header />

      <main className="flex-1 w-full pt-24 pb-12 px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto">
        <button
          onClick={() => navigate(-1)}
          className="flex items-center text-sm font-medium text-slate-500 hover:text-primary mb-6 transition-colors"
        >
          <ArrowLeft className="mr-2 h-4 w-4" /> Quay lại danh sách
        </button>

        <div className="bg-surface-container-lowest shadow-sm rounded-3xl overflow-hidden border border-outline-variant/30">
          <div className="p-8 border-b border-outline-variant/30 bg-surface-container-low">
            <h1 className="text-3xl font-extrabold text-on-surface flex items-center font-headline tracking-tight">
              <Camera className="mr-3 h-8 w-8 text-primary" />
              Báo cáo Sự cố mới
            </h1>
            <p className="mt-3 text-sm text-on-surface-variant leading-relaxed">
              Cung cấp chi tiết và hình ảnh bằng chứng để các cơ quan quản lý thành phố có
              thể tiếp nhận và giải quyết vấn đề hiệu quả nhất.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="p-8 space-y-8 bg-surface-container-lowest">
            {error && (
              <div className="bg-error-container/80 backdrop-blur-sm border-l-4 border-error p-4 rounded-r-lg flex items-center">
                <AlertCircle className="text-error mr-3 shrink-0" size={20} />
                <p className="text-sm text-on-error-container font-medium">{error}</p>
              </div>
            )}

            {/* Photo Upload Section */}
            <div>
              <label className="block text-sm font-bold text-on-surface mb-3 tracking-wide">
                Hình ảnh Bằng chứng <span className="text-error">*</span>
              </label>
              <div
                className={`mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-dashed rounded-2xl transition-all ${imagePreview
                  ? "border-primary bg-primary-container/10"
                  : "border-outline-variant hover:border-primary bg-surface"
                  }`}
              >
                <div className="space-y-4 text-center w-full">
                  {imagePreview ? (
                    <div className="relative group rounded-xl overflow-hidden h-64 bg-black">
                      <img
                        src={imagePreview}
                        alt="Preview"
                        className="w-full h-full object-contain opacity-90 group-hover:opacity-100 transition-opacity"
                      />
                      <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                        <label
                          htmlFor="file-upload"
                          className="cursor-pointer bg-white/20 backdrop-blur-md text-white px-4 py-2 rounded-lg font-bold shadow-lg hover:bg-white/30 transition-colors"
                        >
                          Đổi hình ảnh khác
                        </label>
                      </div>
                    </div>
                  ) : (
                    <>
                      <div className="w-16 h-16 mx-auto bg-primary-container/30 rounded-full flex items-center justify-center mb-4">
                        <UploadCloud className="h-8 w-8 text-primary" />
                      </div>
                      <div className="flex justify-center text-sm text-on-surface-variant">
                        <label
                          htmlFor="file-upload"
                          className="relative cursor-pointer bg-transparent rounded-md font-bold text-primary hover:text-primary-container transition-colors focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-primary"
                        >
                          <span>Nhấn để Tải tệp lên</span>
                          <input
                            id="file-upload"
                            name="file-upload"
                            type="file"
                            accept="image/jpeg, image/png"
                            className="sr-only"
                            onChange={handleImageChange}
                            required
                          />
                        </label>
                        <p className="pl-1">hoặc kéo thả vào đây</p>
                      </div>
                      <p className="text-xs text-outline font-medium tracking-wide">
                        Hỗ trợ PNG, JPG • Tối đa 10MB
                      </p>
                    </>
                  )}
                  {imagePreview && (
                    <input
                      id="file-upload"
                      name="file-upload"
                      type="file"
                      accept="image/jpeg, image/png"
                      className="sr-only"
                      onChange={handleImageChange}
                    />
                  )}
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 gap-y-8 gap-x-6 sm:grid-cols-2 pt-4">
              <div className="sm:col-span-2">
                <label
                  htmlFor="title"
                  className="block text-sm font-bold text-on-surface mb-2 tracking-wide"
                >
                  Tiêu đề <span className="text-error">*</span>
                </label>
                <div className="mt-1 relative">
                  <input
                    type="text"
                    name="title"
                    id="title"
                    required
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    className="block w-full border-outline-variant/60 rounded-xl leading-5 bg-surface py-3.5 px-4 transition-all sm:text-sm border text-on-surface placeholder:text-outline"
                    placeholder="Mô tả ngắn gọn sự cố (VD: Cột đèn giao thông số 5 bị mờ hỏng)"
                  />
                </div>
              </div>

              <div className="sm:col-span-2">
                <label
                  htmlFor="category"
                  className="block text-sm font-bold text-on-surface mb-2 tracking-wide"
                >
                  Danh mục <span className="text-error">*</span>
                </label>
                <div className="mt-1">
                  <select
                    id="category"
                    name="category"
                    required
                    value={categoryId}
                    onChange={(e) => setCategoryId(e.target.value)}
                    className="block w-full border-outline-variant/60 rounded-xl bg-surface py-3.5 px-4 sm:text-sm border appearance-none text-on-surface"
                  >
                    <option value="" disabled>
                      Chọn một danh mục phù hợp
                    </option>
                    {categories.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="sm:col-span-2">
                <label
                  htmlFor="description"
                  className="block text-sm font-bold text-on-surface mb-2 justify-between tracking-wide"
                >
                  <span>Mô tả chi tiết</span>
                  <span className="text-outline font-medium text-xs bg-surface-container-high px-2 py-0.5 rounded-full">Tùy chọn</span>
                </label>
                <div className="mt-1">
                  <textarea
                    id="description"
                    name="description"
                    rows={4}
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    className="block w-full border-outline-variant/60 rounded-xl bg-surface py-3.5 px-4  sm:text-sm border resize-none text-on-surface placeholder:text-outline"
                    placeholder="Cung cấp thêm thông tin về tình trạng sự cố, đặc điểm nhận dạng..."
                  />
                </div>
              </div>

              {/* Location Fields */}
              <div className="sm:col-span-2 space-y-4 pt-2">
                <label className="text-sm font-bold text-on-surface flex items-center tracking-wide">
                  <MapPin className="mr-2 h-5 w-5 text-primary" /> Vị trí sự cố{" "}
                  <span className="text-error ml-1">*</span>
                </label>
                <div className="bg-primary-container/10 border border-primary-container/30 rounded-xl p-4 mb-4 flex">
                  <span className="text-sm text-on-surface-variant font-medium leading-relaxed">
                    Hệ thống sẽ tự động lấy tọa độ vị trí hiện tại của bạn. Bạn cũng có thể điều chỉnh thủ công nếu vị trí không chính xác.
                  </span>
                </div>
                <div className="grid grid-cols-2 gap-6">
                  <div>
                    <label
                      htmlFor="latitude"
                      className="block text-xs font-bold text-outline uppercase tracking-widest mb-2"
                    >
                      Vĩ độ (Latitude)
                    </label>
                    <input
                      type="number"
                      step="any"
                      name="latitude"
                      id="latitude"
                      required
                      value={latitude}
                      onChange={(e) => setLatitude(e.target.value)}
                      className="block w-full border-outline-variant/60 rounded-xl bg-surface py-3.5 px-4 focus:ring-2 focus:ring-primary focus:border-primary font-mono text-sm border text-on-surface"
                      placeholder="10.7769"
                    />
                  </div>
                  <div>
                    <label
                      htmlFor="longitude"
                      className="block text-xs font-bold text-outline uppercase tracking-widest mb-2"
                    >
                      Kinh độ (Longitude)
                    </label>
                    <input
                      type="number"
                      step="any"
                      name="longitude"
                      id="longitude"
                      required
                      value={longitude}
                      onChange={(e) => setLongitude(e.target.value)}
                      className="block w-full border-outline-variant/60 rounded-xl bg-surface py-3.5 px-4 focus:ring-2 focus:ring-primary focus:border-primary font-mono text-sm border text-on-surface"
                      placeholder="106.7009"
                    />
                  </div>
                </div>
              </div>
            </div>

            <div className="pt-8 border-t border-outline-variant/30 mt-8">
              <button
                type="submit"
                disabled={loading}
                className="w-full flex justify-center items-center py-4 px-4 border border-transparent rounded-xl shadow-lg shadow-primary/20 text-base font-bold text-on-primary bg-primary hover:bg-primary-container hover:text-white focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary transition-all active:scale-[0.98] disabled:opacity-70 disabled:active:scale-100"
              >
                {loading ? "Đang xử lý..." : "Gửi Báo Cáo"}
                {!loading && <ArrowRight className="ml-2 h-5 w-5" />}
              </button>
            </div>
          </form>
        </div>
      </main>

      <Footer />
    </div>
  );
}
