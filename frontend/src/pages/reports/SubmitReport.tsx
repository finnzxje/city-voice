import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { IncidentAPI, type Category } from "../../api/services";
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
        setCategories(res.data);
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
      navigate("/");
    } catch (err: any) {
      setError(
        err.response?.data?.message ||
          "Gửi báo cáo thất bại. Đảm bảo vị trí của bạn nằm trong khu vực TP.HCM.",
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        <button
          onClick={() => navigate(-1)}
          className="flex items-center text-sm font-medium text-gray-500 hover:text-gray-900 mb-6 transition-colors"
        >
          <ArrowLeft className="mr-2 h-4 w-4" /> Quay lại Bảng điều khiển
        </button>

        <div className="bg-white shadow-xl shadow-indigo-100/20 rounded-3xl overflow-hidden border border-gray-100">
          <div className="p-8 border-b border-gray-100 bg-gradient-to-r from-indigo-50/50 to-white">
            <h1 className="text-2xl font-bold text-gray-900 flex items-center">
              <Camera className="mr-3 h-6 w-6 text-indigo-600" />
              Báo cáo Sự cố mới
            </h1>
            <p className="mt-2 text-sm text-gray-500">
              Cung cấp chi tiết và hình ảnh bằng chứng để nhân viên thành phố có thể giải quyết vấn đề.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="p-8 space-y-8">
            {error && (
              <div className="bg-red-50/80 backdrop-blur-sm border-l-4 border-red-500 p-4 rounded-r-lg flex items-center">
                <AlertCircle className="text-red-500 mr-3 shrink-0" size={20} />
                <p className="text-sm text-red-700">{error}</p>
              </div>
            )}

            {/* Photo Upload Section */}
            <div>
              <label className="block text-sm font-semibold text-gray-900 mb-2">
                Hình ảnh Bằng chứng <span className="text-red-500">*</span>
              </label>
              <div
                className={`mt-1 flex justify-center px-6 pt-5 pb-6 border-2 border-dashed rounded-2xl transition-all ${
                  imagePreview
                    ? "border-indigo-500 bg-indigo-50/20"
                    : "border-gray-300 hover:border-indigo-400 bg-gray-50/50"
                }`}
              >
                <div className="space-y-2 text-center w-full">
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
                          className="cursor-pointer bg-white/20 backdrop-blur-md text-white px-4 py-2 rounded-lg font-medium hover:bg-white/30 transition-colors"
                        >
                          Đổi hình ảnh
                        </label>
                      </div>
                    </div>
                  ) : (
                    <>
                      <UploadCloud className="mx-auto h-12 w-12 text-gray-400" />
                      <div className="flex justify-center text-sm text-gray-600 pt-2">
                        <label
                          htmlFor="file-upload"
                          className="relative cursor-pointer bg-white rounded-md font-medium text-indigo-600 hover:text-indigo-500 focus-within:outline-none focus-within:ring-2 focus-within:ring-offset-2 focus-within:ring-indigo-500"
                        >
                          <span>Tải tệp lên</span>
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
                      <p className="text-xs text-gray-500">
                        PNG, JPG tối đa 10MB
                      </p>
                    </>
                  )}
                  {/* Keep input accessible if image preview is shown too */}
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

            <div className="grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-2">
              <div className="sm:col-span-2">
                <label
                  htmlFor="title"
                  className="block text-sm font-semibold text-gray-900"
                >
                  Tiêu đề <span className="text-red-500">*</span>
                </label>
                <div className="mt-1">
                  <input
                    type="text"
                    name="title"
                    id="title"
                    required
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    className="block w-full border-gray-200 rounded-xl leading-5 bg-gray-50 py-3 px-4 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-shadow sm:text-sm border"
                    placeholder="Tóm tắt ngắn gọn về sự cố"
                  />
                </div>
              </div>

              <div className="sm:col-span-2">
                <label
                  htmlFor="category"
                  className="block text-sm font-semibold text-gray-900"
                >
                  Danh mục <span className="text-red-500">*</span>
                </label>
                <div className="mt-1">
                  <select
                    id="category"
                    name="category"
                    required
                    value={categoryId}
                    onChange={(e) => setCategoryId(e.target.value)}
                    className="block w-full border-gray-200 rounded-xl bg-gray-50 py-3 px-4 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm border appearance-none"
                  >
                    <option value="" disabled>
                      Chọn một danh mục
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
                  className="block text-sm font-semibold text-gray-900 border-b border-gray-100 pb-2 flex justify-between"
                >
                  <span>Mô tả chi tiết</span>
                  <span className="text-gray-400 font-normal">Tùy chọn</span>
                </label>
                <div className="mt-2">
                  <textarea
                    id="description"
                    name="description"
                    rows={4}
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                    className="block w-full border-gray-200 rounded-xl bg-gray-50 py-3 px-4 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm border resize-none"
                    placeholder="Cung cấp thêm thông tin chi tiết..."
                  />
                </div>
              </div>

              {/* Location Fields (Mock map picker representation) */}
              <div className="sm:col-span-2 space-y-4">
                <label className="block text-sm font-semibold text-gray-900 flex items-center">
                  <MapPin className="mr-2 h-4 w-4 text-indigo-500" /> Vị trí{" "}
                  <span className="text-red-500 ml-1">*</span>
                </label>
                <div className="bg-blue-50/50 border border-blue-100 rounded-xl p-4 mb-4 flex">
                  <span className="text-sm text-blue-800">
                    Vị trí của bạn đã được tự động xác định. Nếu không đúng, vui lòng nhập tọa độ theo cách thủ công hoặc cho phép quyền truy cập vị trí.
                  </span>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label
                      htmlFor="latitude"
                      className="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1"
                    >
                      Vĩ độ
                    </label>
                    <input
                      type="number"
                      step="any"
                      name="latitude"
                      id="latitude"
                      required
                      value={latitude}
                      onChange={(e) => setLatitude(e.target.value)}
                      className="block w-full border-gray-200 rounded-lg bg-gray-50 py-2.5 px-3 focus:ring-2 focus:ring-indigo-500 font-mono text-sm border"
                      placeholder="10.7769"
                    />
                  </div>
                  <div>
                    <label
                      htmlFor="longitude"
                      className="block text-xs font-medium text-gray-500 uppercase tracking-wider mb-1"
                    >
                      Kinh độ
                    </label>
                    <input
                      type="number"
                      step="any"
                      name="longitude"
                      id="longitude"
                      required
                      value={longitude}
                      onChange={(e) => setLongitude(e.target.value)}
                      className="block w-full border-gray-200 rounded-lg bg-gray-50 py-2.5 px-3 focus:ring-2 focus:ring-indigo-500 font-mono text-sm border"
                      placeholder="106.7009"
                    />
                  </div>
                </div>
              </div>
            </div>

            <div className="pt-6 border-t border-gray-100">
              <button
                type="submit"
                disabled={loading}
                className="w-full flex justify-center items-center py-4 px-4 border border-transparent rounded-xl shadow-lg shadow-indigo-200 text-base font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all disabled:opacity-70"
              >
                {loading ? "Đang gửi..." : "Gửi báo cáo"}
                {!loading && <ArrowRight className="ml-2 h-5 w-5" />}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
