import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { IncidentAPI, type ReportResponse } from "../../api/services";
import { useAuth } from "../../contexts/AuthContext";
import {
  ArrowLeft,
  Calendar,
  CheckCircle2,
  XCircle,
  MapPin,
  Image as ImageIcon,
  CheckSquare,
  X,
  ShieldCheck,
  AlertCircle,
  User
} from "lucide-react";
import toast from "react-hot-toast";

import { MapContainer, TileLayer, Marker, ZoomControl } from "react-leaflet";
import "leaflet/dist/leaflet.css";
import L from "leaflet";
import ActivityLog from "./components/report-details/ActivityLog";

// Leaflet fix for default markers
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
});

export default function StaffReportDetails() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();

  const [report, setReport] = useState<ReportResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const [actionLoading, setActionLoading] = useState(false);
  const [showRejectInput, setShowRejectInput] = useState(false);
  const [rejectNote, setRejectNote] = useState("");

  const [selectedPriority, setSelectedPriority] = useState("medium");

  const [resolveImage, setResolveImage] = useState<File | null>(null);
  const [resolveNote, setResolveNote] = useState("");

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

  const handleAccept = async () => {
    if (!id || !user) return;
    setActionLoading(true);
    try {
      await IncidentAPI.reviewReport(id, {
        priority: selectedPriority,
        assignedTo: user.id,
        note: "Đã tiếp nhận xử lý",
      });
      toast.success("Đã tiếp nhận báo cáo");
      await fetchReport();
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Lỗi khi tiếp nhận");
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    if (!id || !rejectNote) {
      toast.error("Vui lòng nhập lý do từ chối");
      return;
    }
    setActionLoading(true);
    try {
      await IncidentAPI.rejectReport(id, { note: rejectNote });
      toast.success("Đã từ chối báo cáo");
      setShowRejectInput(false);
      setRejectNote("");
      await fetchReport();
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Lỗi khi từ chối");
    } finally {
      setActionLoading(false);
    }
  };

  const handleResolve = async () => {
    if (!id || !resolveImage) {
      toast.error("Vui lòng tải lên hình ảnh minh chứng đã giải quyết");
      return;
    }
    setActionLoading(true);
    try {
      const formData = new FormData();
      formData.append("image", resolveImage);
      if (resolveNote) formData.append("note", resolveNote);

      await IncidentAPI.resolveReport(id, formData);
      toast.success("Đã giải quyết báo cáo");
      setResolveImage(null);
      setResolveNote("");
      await fetchReport();
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Lỗi khi giải quyết");
    } finally {
      setActionLoading(false);
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
      <div className="min-h-screen bg-surface flex items-center justify-center p-6">
        <div className="bg-error-container text-on-error-container p-6 rounded-xl flex items-center shadow-lg">
          <AlertCircle className="h-6 w-6 mr-4" />
          <p className="font-bold">{error || "Không tìm thấy báo cáo."}</p>
        </div>
      </div>
    );
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "newly_received":
        return <span className="px-3 py-1 bg-orange-100 text-orange-800 rounded-full text-[12px] font-bold uppercase tracking-wider">Mới tiếp nhận</span>;
      case "in_progress":
        return <span className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-[12px] font-bold uppercase tracking-wider">Đang xử lý</span>;
      case "resolved":
        return <span className="px-3 py-1 bg-green-100 text-green-800 rounded-full text-[12px] font-bold uppercase tracking-wider">Đã giải quyết</span>;
      case "rejected":
        return <span className="px-3 py-1 bg-red-100 text-red-800 rounded-full text-[12px] font-bold uppercase tracking-wider">Từ chối</span>;
      default:
        return <span className="px-3 py-1 bg-surface-container-high text-on-surface-variant rounded-full text-[12px] font-bold uppercase tracking-wider">{status}</span>;
    }
  };
  const level = {
    low: "thấp",
    medium: "trung bình",
    high: "cao",
    critical: "khẩn cấp"
  }
  const PRIORITY_CONFIG: Record<string, { label: string; color: string; bg: string }> = {
    critical: { label: "Nghiêm trọng", color: "bg-red-500", bg: "bg-red-50 text-red-700 border-red-200" },
    high: { label: "Cao", color: "bg-orange-500", bg: "bg-orange-50 text-orange-700 border-orange-200" },
    medium: { label: "Trung bình", color: "bg-amber-400", bg: "bg-amber-50 text-amber-700 border-amber-200" },
    low: { label: "Thấp", color: "bg-sky-400", bg: "bg-sky-50 text-sky-700 border-sky-200" },
  };

  const priority = report.priority || 'low';
  const config = PRIORITY_CONFIG[priority];
  // Convert status back to readable history
  const historyItems = [
    { title: "Báo cáo được khởi tạo", date: report.createdAt, by: report.citizenName || report.citizenPhone || "Người dân" }
  ];
  if (report.currentStatus === 'in_progress' || report.currentStatus === 'resolved') {
    console.log(report);
    historyItems.push({ title: "Đã phân công xử lý", date: report.updatedAt || report.createdAt, by: "Hệ thống / Staff" });
  }
  if (report.currentStatus === 'resolved') {
    console.log(report);
    historyItems.push({ title: "Đã nghiệm thu", date: report.updatedAt || report.createdAt, by: "Hệ thống / Staff" });
  }
  if (report.currentStatus === 'rejected') {
    historyItems.push({ title: "Báo cáo bị từ chối", date: report.updatedAt || report.createdAt, by: "Hệ thống / Staff" });
  }

  return (
    <div className="min-h-screen bg-surface text-on-surface font-body antialiased flex flex-col">
      {/* Top App Bar */}
      <header className="sticky top-0 w-full flex items-center justify-between px-8 h-16 bg-[#f7fafe]/70 backdrop-blur-xl z-40 border-b border-surface-container">
        <div className="flex items-center gap-4">
          <button onClick={() => navigate(-1)} className="p-2 hover:bg-surface-container-low rounded-full transition-colors active:scale-95">
            <ArrowLeft className="h-5 w-5" />
          </button>
          <h1 className="text-xl font-bold tracking-tight text-on-surface font-headline">
            Chi tiết sự cố #{report.id.substring(0, 8).toUpperCase()}
          </h1>
        </div>
        <div className="flex items-center gap-4">
          {getStatusBadge(report.currentStatus)}
        </div>
      </header>

      <div className="p-8 space-y-8 max-w-7xl mx-auto w-full">
        {/* Asymmetric Bento Grid Layout */}
        <div className="grid grid-cols-12 gap-6">

          {/* Left Column: Report Details (8 Columns) */}
          <div className="col-span-12 lg:col-span-8 space-y-6">

            {/* Header Info Card */}
            <section className="bg-surface-container-lowest rounded-xl p-8 shadow-sm border border-surface-container/50 transition-all hover:-translate-y-1">
              <div className="flex flex-col gap-2 mb-6">
                <span className="text-primary font-bold text-xs uppercase tracking-widest">{report.categoryName}</span>
                {/* Badge Priority mới */}
                {report.priority && (
                  <div className={`flex items-center w-fit gap-1.5 px-2.5 py-1 rounded-md border text-[11px] font-bold uppercase shadow-sm ${PRIORITY_CONFIG[report.priority].bg}`}>
                    <span className={`w-1.5 h-1.5 rounded-full ${PRIORITY_CONFIG[report.priority].color}`} />
                    {PRIORITY_CONFIG[report.priority].label}
                  </div>
                )}
                <h2 className="text-3xl font-extrabold text-on-surface leading-tight font-headline">{report.title}</h2>
                <div className="flex flex-wrap items-center gap-4 mt-2 text-on-surface-variant text-sm font-medium">
                  <span className="flex items-center gap-1.5"><Calendar className="w-4 h-4" /> {new Date(report.createdAt).toLocaleString()}</span>
                  <span className="flex items-center gap-1.5"><User className="w-4 h-4" /> {report.citizenName || report.citizenPhone || "Người dân ẩn danh"}</span>
                </div>
              </div>

              <p className="text-on-surface-variant leading-relaxed mb-8">
                {report.description || "Không có mô tả thêm."}
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {report.incidentImageUrl ? (
                  <div className="rounded-lg overflow-hidden relative group aspect-video">
                    <img
                      className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                      src={report.incidentImageUrl.replace("http://minio:9000", "http://localhost:9000")}
                      alt="Ảnh hiện trường"
                    />
                    <div className="absolute inset-0 bg-black/10 group-hover:bg-transparent transition-colors"></div>
                  </div>
                ) : (
                  <div className="rounded-lg border-2 border-dashed border-outline-variant/30 flex items-center justify-center p-8 aspect-video bg-surface-container-low/50">
                    <div className="text-center opacity-60">
                      <ImageIcon className="h-8 w-8 mx-auto mb-2" />
                      <p className="text-sm font-medium">Không có ảnh đính kèm</p>
                    </div>
                  </div>
                )}
                {report.resolutionImageUrl && (
                  <div className="rounded-lg overflow-hidden relative group aspect-video border-2 border-green-500">
                    <div className="absolute top-2 left-2 z-10 bg-green-500 text-white text-[10px] font-bold px-2 py-1 rounded-full flex items-center gap-1">
                      <CheckCircle2 className="w-3 h-3" /> ẢNH NGHIỆM THU
                    </div>
                    <img
                      className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                      src={report.resolutionImageUrl.replace("http://minio:9000", "http://localhost:9000")}
                      alt="Ảnh hoàn thành"
                    />
                    <div className="absolute inset-0 bg-black/10 group-hover:bg-transparent transition-colors"></div>
                  </div>
                )}
              </div>
            </section>

            {/* Interactive Map Section */}
            <section className="bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm border border-surface-container/50">
              <div className="p-4 bg-surface-container-low flex justify-between items-center">
                <div className="flex items-center gap-2">
                  <MapPin className="text-primary h-5 w-5" />
                  <span className="font-bold text-sm">Vị trí phản ánh: {report.administrativeZoneName}</span>
                </div>
                <span className="text-xs text-on-surface-variant font-mono bg-surface-container-highest px-2 py-1 rounded-md">
                  {report.latitude.toFixed(4)}, {report.longitude.toFixed(4)}
                </span>
              </div>
              <div className="h-80 w-full relative z-0">
                <MapContainer
                  center={[report.latitude, report.longitude]}
                  zoom={16}
                  zoomControl={false}
                  className="w-full h-full"
                >
                  <TileLayer url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png" />
                  <ZoomControl position="bottomright" />
                  <Marker position={[report.latitude, report.longitude]} />
                </MapContainer>
              </div>
            </section>
          </div>

          {/* Right Column: Action Modules (4 Columns) */}
          <div className="col-span-12 lg:col-span-4 space-y-6">

            {/* Module 2: Processing Actions */}
            {report.currentStatus === "newly_received" && (
              <section className="bg-surface-container-lowest rounded-xl p-6 shadow-sm border border-surface-container/50 flex flex-col gap-6">
                <h3 className="text-lg font-bold border-b border-surface-container pb-4 font-headline">Xử lý báo cáo</h3>

                {/* Priority & Assignment */}
                {!showRejectInput ? (
                  <>
                    <div className="space-y-4">
                      <div>
                        <label className="text-xs font-bold text-on-surface-variant uppercase mb-2 block tracking-wider">Mức độ ưu tiên</label>
                        <div className="grid grid-cols-2 lg:grid-cols-4 gap-2">
                          {(Object.keys(level) as (keyof typeof level)[]).map(pLevel => (
                            <button
                              key={pLevel}
                              onClick={() => setSelectedPriority(pLevel)}
                              className={`py-2 px-1 text-[11px] font-bold rounded-lg border-2 transition-colors uppercase
                                  ${selectedPriority === pLevel
                                  ? 'border-primary bg-primary/10 text-primary'
                                  : 'border-surface-container hover:bg-surface-container'
                                }`}
                            >
                              {level[pLevel]}
                            </button>
                          ))}
                        </div>
                      </div>

                      <button
                        onClick={handleAccept}
                        disabled={actionLoading}
                        className="w-full py-4 bg-primary text-white font-bold rounded-xl shadow-lg shadow-primary/20 hover:bg-primary-container active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-50"
                      >
                        <CheckSquare className="h-5 w-5" />
                        Duyệt & Phân công
                      </button>
                    </div>

                    <div className="relative">
                      <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-surface-container"></div></div>
                      <div className="relative flex justify-center text-xs"><span className="px-2 bg-surface-container-lowest text-outline italic">hoặc</span></div>
                    </div>

                    <button
                      onClick={() => setShowRejectInput(true)}
                      className="w-full py-3 bg-surface-container-high text-on-surface font-bold rounded-xl hover:bg-error-container hover:text-on-error-container transition-colors flex items-center justify-center gap-2"
                    >
                      <XCircle className="h-5 w-5" />
                      Từ chối báo cáo
                    </button>
                  </>
                ) : (
                  /* Rejection Form */
                  <div className="space-y-3 animate-fade-in-down">
                    <div className="flex justify-between items-center mb-2">
                      <label className="text-xs font-bold text-error uppercase tracking-wider">Lý do từ chối</label>
                      <button onClick={() => setShowRejectInput(false)} className="text-on-surface-variant hover:text-on-surface"><X className="h-4 w-4" /></button>
                    </div>
                    <textarea
                      value={rejectNote}
                      onChange={(e) => setRejectNote(e.target.value)}
                      className="w-full bg-surface-container-highest border-none rounded-xl text-sm p-4 focus:ring-2 focus:ring-error/40 min-h-[100px] outline-none"
                      placeholder="Nhập lý do từ chối nếu báo cáo không hợp lệ..."
                    ></textarea>
                    <button
                      onClick={handleReject}
                      disabled={actionLoading}
                      className="w-full py-3 bg-error text-on-error font-bold rounded-xl hover:bg-[#93000a] transition-colors flex items-center justify-center gap-2 disabled:opacity-50"
                    >
                      Xác nhận từ chối
                    </button>
                  </div>
                )}
              </section>
            )}

            {/* Resolve Module */}
            {report.currentStatus === "in_progress" && (
              <section className="bg-[#f3f3ff] rounded-xl p-6 border-2 border-dashed border-primary/30 space-y-4 relative overflow-hidden">
                <div className="absolute top-0 right-0 p-4 opacity-10"><ShieldCheck className="w-16 h-16 text-primary" /></div>

                <h3 className="text-lg font-bold flex items-center gap-2 text-primary relative z-10 font-headline">
                  <CheckSquare className="h-5 w-5" />
                  Nghiệm thu (Resolve)
                </h3>
                <p className="text-xs text-[#00174c] mb-2 font-medium relative z-10">Vui lòng tải lên hình ảnh sau khi đã hoàn thành việc sửa chữa hiện trường.</p>

                <div className="relative z-10 space-y-3">
                  <label className="flex flex-col cursor-pointer group">
                    <div className="border-2 border-dashed border-[#b4c5ff] hover:border-primary transition-colors bg-white/70 rounded-xl p-8 flex flex-col items-center justify-center gap-2">
                      <ImageIcon className="text-on-primary-fixed-variant group-hover:text-primary transition-colors h-8 w-8" />
                      <span className="text-xs font-bold text-on-primary-fixed-variant group-hover:text-primary mt-1 text-center">
                        {resolveImage ? resolveImage.name : "Kéo thả hoặc Click để tải ảnh (*)"}
                      </span>
                    </div>
                    <input
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={(e) => e.target.files && setResolveImage(e.target.files[0])}
                    />
                  </label>

                  <textarea
                    value={resolveNote}
                    onChange={(e) => setResolveNote(e.target.value)}
                    placeholder="Ghi chú hoàn thành (tùy chọn)..."
                    className="w-full bg-white border-none rounded-xl text-sm p-4 outline-none focus:ring-2 focus:ring-primary/40 shadow-sm"
                    rows={2}
                  ></textarea>

                  <button
                    onClick={handleResolve}
                    disabled={actionLoading || !resolveImage}
                    className="w-full py-4 bg-white text-primary border-2 border-primary font-bold rounded-xl hover:bg-primary hover:text-white transition-all flex items-center justify-center gap-2 disabled:opacity-50 mt-2 shadow-sm"
                  >
                    <CheckCircle2 className="h-5 w-5" />
                    Hoàn thành & Đóng hồ sơ
                  </button>
                </div>
              </section>
            )}

            {/* Activity Log (Editorial feel) */}
            <ActivityLog historyItems={historyItems} />
          </div>
        </div>
      </div>
    </div>
  );
}

