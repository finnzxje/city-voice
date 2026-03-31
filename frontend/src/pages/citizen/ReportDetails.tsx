import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { IncidentAPI, type ReportResponse } from "../../api/services";
import Header from "../../components/Header";
import Footer from "../../components/Footer";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { AlertOctagon, ArrowLeft, CheckCircle2, ChevronDown, ChevronsUp, ClipboardList, Clock, HelpCircle, Mail, MapPin, Minus, User, XCircle } from "lucide-react";
import ImageZoom from "../../components/ImageZoom";

// @ts-ignore
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png",
  iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png",
  shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png",
});

export default function ReportDetails() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const [report, setReport] = useState<ReportResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const fetchReport = async () => {
    try {
      if (!id) return;
      const res = await IncidentAPI.getReportById(id);
      setReport(res.data.data);
    } catch (err: any) {
      setError(err.response?.data?.message || "Lỗi tải chi tiết báo cáo.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReport();
  }, [id]);

  const getStatusDisplay = (status: string) => {
    switch (status) {
      case "newly_received":
        return {
          label: "Mới tiếp nhận",
          bg: "bg-blue-100",
          text: "text-blue-800",
          icon: <Mail size={14} className="mr-2" />,
        };
      case "in_progress":
        return {
          label: "Đang xử lý",
          bg: "bg-amber-100",
          text: "text-amber-800",
          icon: <Clock size={14} className="mr-2" />,
        };
      case "resolved":
        return {
          label: "Đã giải quyết",
          bg: "bg-emerald-100",
          text: "text-emerald-800",
          icon: <CheckCircle2 size={14} className="mr-2" />,
        };
      case "rejected":
        return {
          label: "Từ chối",
          bg: "bg-red-100",
          text: "text-red-800",
          icon: <XCircle size={14} className="mr-2" />,
        };
      default:
        return {
          label: status,
          bg: "bg-gray-100",
          text: "text-gray-800",
          icon: "info",
        };
    }
  };

  const getPriorityDisplay = (priority?: string) => {
    switch (priority) {
      case "critical":
        return {
          label: "Nghiêm trọng",
          icon: <AlertOctagon size={16} />,
          color: "text-red-600",
          bgColor: "bg-red-50"
        };
      case "high":
        return {
          label: "Ưu tiên cao",
          icon: <ChevronsUp size={16} />,
          color: "text-orange-600",
          bgColor: "bg-orange-50"
        };
      case "medium":
        return {
          label: "Ưu tiên trung bình",
          icon: <Minus size={16} />,
          color: "text-amber-600",
          bgColor: "bg-amber-50"
        };
      case "low":
        return {
          label: "Ưu tiên thấp",
          icon: <ChevronDown size={16} />,
          color: "text-blue-600",
          bgColor: "bg-blue-50"
        };
      default:
        return {
          label: "Chưa phân loại",
          icon: <HelpCircle size={16} />,
          color: "text-gray-500",
          bgColor: "bg-gray-50"
        };
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-surface py-12 flex justify-center items-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  if (error || !report) {
    return (
      <div className="min-h-screen bg-surface py-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-3xl mx-auto">
          <button
            onClick={() => navigate(-1)}
            className="flex items-center text-sm font-medium text-gray-500 hover:text-gray-900 mb-6 focus:outline-none font-body"
          >
            <span className="material-symbols-outlined mr-2">arrow_back</span> Quay lại
          </button>
          <div className="bg-red-50 border border-red-200 rounded-xl p-6 flex items-start">
            <span className="material-symbols-outlined text-red-500 mr-4">error</span>
            <div>
              <h3 className="text-lg font-medium text-red-800 font-headline">Lỗi Khi Tải Báo Cáo</h3>
              <p className="mt-1 text-sm text-red-700 font-body">{error || "Không tìm thấy báo cáo."}</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  const statusInfo = getStatusDisplay(report.currentStatus);
  const priorityInfo = getPriorityDisplay(report.priority);

  return (
    <div className="bg-surface text-on-surface min-h-screen flex flex-col">
      <Header />

      <main className="pt-24 pb-20 px-4 md:px-8 max-w-7xl mx-auto font-body flex-1 w-full">
        {/* Breadcrumbs / Action Bar */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
          <button onClick={() => navigate(-1)} className="flex items-center gap-2 group hover:text-primary transition-colors text-slate-600">
            <ArrowLeft size={20} strokeWidth={2.5} />
            <span className="font-medium text-sm">Quay lại danh sách</span>
          </button>

        </div>

        {/* Hero Section: Title & Status */}
        <div className="relative overflow-hidden mb-12">
          <div className="relative z-10">
            <div className="flex items-center gap-3 mb-4">
              <span className="bg-primary-container text-white px-3 py-1 rounded-full text-[10px] font-bold tracking-widest uppercase shadow-sm">
                Mã BC: #REP-{report.id.substring(0, 5).toUpperCase()}
              </span>
              <span className={`${statusInfo.bg} ${statusInfo.text} px-3 py-1 rounded-full text-[10px] font-bold tracking-widest uppercase flex items-center gap-1 shadow-sm`}>
                <span className="material-symbols-outlined text-xs" style={{ fontVariationSettings: "'FILL' 1" }}>
                  {statusInfo.icon}
                </span>
                {statusInfo.label}
              </span>
            </div>
            <h1 className="text-3xl md:text-5xl font-extrabold text-on-surface leading-tight tracking-tight mb-2 font-headline">
              {report.title}
            </h1>
            <p className="text-on-surface-variant text-lg max-w-2xl font-body">
              Gửi vào ngày {new Date(report.createdAt).toLocaleDateString("vi-VN")} lúc {new Date(report.createdAt).toLocaleTimeString("vi-VN")}
            </p>
          </div>
          {/* Decorative Asymmetry */}
          <div className="absolute -right-20 -top-20 w-96 h-96 bg-primary-container/10 rounded-full blur-3xl"></div>
        </div>

        {/* Bento Grid Layout */}
        <div className="grid grid-cols-1 md:grid-cols-12 gap-8">
          {/* Main Content Column */}
          <div className="md:col-span-8 space-y-8">
            {/* Report Information Card */}
            <section className="bg-surface-container-lowest rounded-xl p-8 shadow-sm border border-gray-100">
              <h2 className="text-xl font-bold mb-6 flex items-center gap-2 font-headline">
                <ClipboardList className="text-primary" size={24} strokeWidth={2.5} />
                Thông tin báo cáo
              </h2>
              <div className="grid md:grid-cols-2 gap-8">
                <div>
                  <label className="text-[10px] uppercase tracking-wider font-bold text-outline block mb-2">
                    Danh mục
                  </label>
                  <p className="text-on-surface font-medium flex items-center gap-2 text-sm">

                    {report.categoryName}
                  </p>
                </div>
                <div>
                  <label className="text-[10px] uppercase tracking-wider font-bold text-outline block mb-2">
                    Mức độ ưu tiên
                  </label>
                  <div className={`flex items-center gap-2 px-3 py-1.5 rounded-lg w-fit ${priorityInfo.bgColor}`}>
                    <span className={priorityInfo.color}>
                      {priorityInfo.icon}
                    </span>
                    <span className={`text-sm font-semibold ${priorityInfo.color}`}>
                      {priorityInfo.label}
                    </span>
                  </div>
                </div>
                <div className="md:col-span-2">
                  <label className="text-[10px] uppercase tracking-wider font-bold text-outline block mb-2">
                    Mô tả chi tiết
                  </label>
                  <p className="text-on-surface leading-relaxed text-sm whitespace-pre-wrap">
                    {report.description || "Không có mô tả chi tiết."}
                  </p>
                </div>
                <ImageZoom src={report.incidentImageUrl} />
              </div>
            </section>

            {/* Location Card */}
            <section className="bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm border border-gray-100">
              <div className="p-8">
                <h2 className="text-xl font-bold mb-6 flex items-center gap-2 font-headline">
                  <MapPin className="text-primary" size={24} strokeWidth={2.5} />
                  Vị trí phản ánh
                </h2>
                <p className="text-on-surface font-medium mb-4 text-sm">{report.administrativeZoneName}</p>
              </div>
              <div className="h-64 w-full bg-surface-container-high relative flex items-center justify-center overflow-hidden">
                {report.latitude && report.longitude ? (
                  <MapContainer
                    center={[report.latitude, report.longitude]}
                    zoom={15}
                    style={{ height: "100%", width: "100%", zIndex: 10 }}
                    zoomControl={false}
                    dragging={false}
                    scrollWheelZoom={false}
                    doubleClickZoom={false}
                    attributionControl={false}
                  >
                    <TileLayer url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png" />
                    <Marker position={[report.latitude, report.longitude]}>
                      <Popup>{report.administrativeZoneName}</Popup>
                    </Marker>
                  </MapContainer>
                ) : report.incidentImageUrl ? (
                  <img src={report.incidentImageUrl.replace("http://minio:9000", "http://localhost:9000")} alt="Hình ảnh sự cố" className="w-full h-full object-cover opacity-80" />
                ) : (
                  <div className="text-slate-400 flex flex-col items-center">
                    <span className="material-symbols-outlined text-4xl mb-2">map</span>
                    <p className="text-sm">Bản đồ đang được tải...</p>
                  </div>
                )}
                {report.latitude && report.longitude && (
                  <div className="absolute bottom-4 right-4 bg-white/90 backdrop-blur-md p-3 rounded-lg text-xs font-bold shadow-lg text-slate-700 pointer-events-none z-20">
                    GPS: {report.latitude.toFixed(4)}° N, {report.longitude.toFixed(4)}° W
                  </div>
                )}
              </div>
            </section>

            {/* Optional Staff Assignment Info */}
            {report.assignedToName && (
              <section className="bg-surface-container-lowest rounded-xl p-8 shadow-sm border-l-4 border-blue-500 transition-all">
                <div className="flex justify-between items-start mb-6">
                  <h2 className="text-xl font-bold flex items-center gap-2 font-headline text-on-surface">
                    <div className="w-5 h-5 bg-blue-600 rounded"></div>
                    <span>Cán bộ xử lý</span>
                  </h2>
                  <span className={`text-[10px] font-bold uppercase px-2 py-1 rounded ${report.resolutionImageUrl ? 'bg-green-100 text-green-700' : 'bg-blue-100 text-blue-700'}`}>
                    {report.resolutionImageUrl ? "Đã có kết quả" : "Đang xử lý"}
                  </span>
                </div>
                <div className="flex gap-6 items-start">
                  <div className="flex-1">
                    <div className="mb-4">
                      <p className="font-bold text-base text-on-surface">{report.assignedToName}</p>
                      <p className="text-xs text-on-surface-variant italic">ID Cán bộ: {report.assignedToId}</p>
                    </div>
                    {report.resolutionImageUrl ? (
                      <div className="space-y-2">
                        <p className="text-sm font-semibold text-green-600 flex items-center gap-1">
                          KẾT QUẢ NGHIỆM THU:
                        </p>
                        <div
                          className="relative group w-32 h-32 md:w-48 md:h-32 rounded-lg overflow-hidden border-2 border-green-200 cursor-zoom-in"
                          onClick={() => setSelectedImage(report.resolutionImageUrl!.replace("http://minio:9000", "http://localhost:9000"))}
                        >
                          <img
                            className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-110"
                            src={report.resolutionImageUrl.replace("http://minio:9000", "http://localhost:9000")}
                            alt="Kết quả nghiệm thu"
                          />
                          <div className="absolute inset-0 bg-black/20 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                            <span className="text-white text-xs font-medium bg-black/50 px-2 py-1 rounded-md">Xem ảnh lớn</span>
                          </div>
                        </div>
                      </div>
                    ) : (
                      <div className="flex items-center gap-3 p-4 bg-surface-container-low rounded-lg border border-dashed border-outline-variant/50">
                        <div className="animate-spin h-5 w-5 border-2 border-blue-500 border-t-transparent rounded-full"></div>
                        <p className="text-sm font-medium text-on-surface-variant">
                          Hiện trường đang được giải quyết...
                        </p>
                      </div>
                    )}
                  </div>
                </div>
              </section>
            )}

            {/* LIGHTBOX (LỚP PHỦ HIỂN THỊ ẢNH TO) */}
            {selectedImage && (
              <div
                className="fixed inset-0 bg-black/80 z-50 flex items-center justify-center p-4 cursor-zoom-out backdrop-blur-sm"
                onClick={() => setSelectedImage(null)} // Nhấp ra ngoài để đóng
              >
                {/* Nút đóng ảnh (Tùy chọn) */}
                <button
                  className="absolute top-4 right-4 text-white hover:text-gray-300 z-50 p-2"
                  onClick={() => setSelectedImage(null)}
                >
                  Đóng
                </button>

                {/* Ảnh kích thước đầy đủ */}
                <img
                  src={selectedImage}
                  alt="Ảnh nghiệm thu kích thước lớn"
                  className="max-w-full max-h-full rounded-lg shadow-2xl transition-transform duration-300 ease-out"
                  onClick={(e) => e.stopPropagation()}
                />
              </div>
            )}
          </div>

          {/* Side Column: Activity Timeline */}
          <aside className="md:col-span-4">
            <div className="sticky top-28 space-y-8 flex flex-col gap-6">
              <section className="bg-surface-container-lowest border border-gray-100 rounded-xl p-6 shadow-sm">
                <h2 className="text-lg font-bold mb-6 font-headline text-on-surface">Tiến trình xử lý</h2>
                <div className="space-y-0 relative">
                  {/* Vertical Line */}
                  <div className="absolute left-4 top-2 bottom-2 w-0.5 bg-outline-variant"></div>

                  {/* Timeline Items - Mocked for demo since no statusHistory array */}
                  <div className="relative pl-10 pb-8">
                    <div className={`absolute left-2.5 top-1.5 w-3.5 h-3.5 rounded-full ${statusInfo.bg.replace("bg-", "bg-").split(" ")[0] || "bg-primary"} ring-4 ring-white z-10`}></div>
                    <p className="text-sm font-bold text-on-surface">{statusInfo.label}</p>
                    <p className="text-xs text-on-surface-variant mt-1">{report.resolvedAt && new Date(report.resolvedAt).toLocaleDateString("vi-VN", {
                      hour: "2-digit",
                      minute: "2-digit",
                    })}</p>
                    <p className="text-xs text-on-surface-variant mt-1">Trạng thái hiện tại</p>
                  </div>

                  <div className="relative pl-10">
                    <div className="absolute left-2.5 top-1.5 w-3.5 h-3.5 rounded-full bg-slate-300 ring-4 ring-white z-10"></div>
                    <p className="text-sm font-bold text-on-surface">Đã gửi báo cáo</p>
                    <p className="text-xs text-on-surface-variant mt-1">{new Date(report.createdAt).toLocaleDateString("vi-VN", {
                      hour: "2-digit",
                      minute: "2-digit",
                    })}</p>
                    <p className="text-xs mt-2 text-on-surface-variant leading-tight">Hệ thống đã ghi nhận phản ánh của bạn.</p>
                  </div>
                </div>
              </section>

              {/* User Feedback Box - Active if resolved */}
              {report.currentStatus === "resolved" && (
                <section className="bg-primary-container p-6 rounded-xl text-white shadow-md">
                  <h3 className="font-bold mb-2 font-headline text-lg">Bạn có hài lòng với kết quả?</h3>
                  <p className="text-xs text-blue-100 mb-4 opacity-90 leading-snug">Đánh giá của bạn giúp chúng tôi cải thiện chất lượng dịch vụ.</p>
                  <div className="flex flex-col gap-2">
                    <button className="w-full bg-white text-primary py-2.5 rounded-lg text-sm font-bold hover:bg-surface-bright transition-colors">
                      👍 Hài lòng
                    </button>
                    <button className="w-full border border-white/30 text-white py-2.5 rounded-lg text-sm font-bold hover:bg-white/10 transition-colors">
                      👎 Chưa giải quyết triệt để
                    </button>
                  </div>
                </section>
              )}
            </div>
          </aside>
        </div>
      </main>
      <Footer />
    </div>
  );
}
