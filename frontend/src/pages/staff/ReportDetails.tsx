import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { IncidentAPI, type ReportResponse } from "../../api/services";
import { useAuth } from "../../contexts/AuthContext";
import {
  ArrowLeft,
  MapPin,
  Calendar,
  Tag,
  Info,
  AlertCircle,
  CheckCircle,
  XCircle,
} from "lucide-react";
import toast from "react-hot-toast";

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
  const [showResolveInput, setShowResolveInput] = useState(false);
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
        priority: "medium", // Default priority for now, can be expanded
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
      setShowResolveInput(false);
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
      <div className="min-h-screen bg-gray-50 py-12 flex justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  if (error || !report) {
    return (
      <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-3xl mx-auto">
          <button
            onClick={() => navigate(-1)}
            className="flex items-center text-sm font-medium text-gray-500 hover:text-gray-900 mb-6 focus:outline-none"
          >
            <ArrowLeft className="mr-2 h-4 w-4" /> Quay lại
          </button>
          <div className="bg-red-50 border border-red-200 rounded-xl p-6 flex items-start">
            <AlertCircle className="h-6 w-6 text-red-500 mr-4 flex-shrink-0 mt-0.5" />
            <div>
              <h3 className="text-lg font-medium text-red-800">
                Lỗi Khi Tải Báo Cáo
              </h3>
              <p className="mt-1 text-sm text-red-700">
                {error || "Không tìm thấy báo cáo."}
              </p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case "newly_received":
        return (
          <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-yellow-100 text-yellow-800 border border-yellow-200">
            Mới tiếp nhận
          </span>
        );
      case "in_progress":
        return (
          <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800 border border-blue-200">
            Đang xử lý
          </span>
        );
      case "resolved":
        return (
          <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800 border border-green-200">
            Đã giải quyết
          </span>
        );
      case "rejected":
        return (
          <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-red-100 text-red-800 border border-red-200">
            Từ chối
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-800 border border-gray-200">
            {status}
          </span>
        );
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <button
          onClick={() => navigate(-1)}
          className="flex items-center text-sm font-medium text-gray-500 hover:text-indigo-600 mb-6 transition-colors"
        >
          <ArrowLeft className="mr-2 h-4 w-4" /> Quay lại Bảng điều khiển
        </button>

        <div className="bg-white shadow-sm rounded-3xl overflow-hidden border border-gray-100">
          {/* Header */}
          <div className="p-8 border-b border-gray-100">
            <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4 mb-4">
              <h1 className="text-2xl font-bold text-gray-900">
                {report.title}
              </h1>
              <div className="flex-shrink-0">
                {getStatusBadge(report.currentStatus)}
              </div>
            </div>

            <div className="flex flex-wrap gap-4 text-sm text-gray-500">
              <div className="flex items-center">
                <Calendar className="mr-1.5 h-4 w-4 text-gray-400" />
                {new Date(report.createdAt).toLocaleDateString()}
              </div>
              <div className="flex items-center">
                <MapPin className="mr-1.5 h-4 w-4 text-gray-400" />
                {report.administrativeZoneName}
              </div>
              <div className="flex items-center">
                <Tag className="mr-1.5 h-4 w-4 text-gray-400" />
                {report.categoryName}
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-0">
            {/* Image Section */}
            <div className="lg:col-span-2 border-b lg:border-b-0 lg:border-r border-gray-100 bg-gray-50/50">
              {report.incidentImageUrl ? (
                <div className="aspect-[4/3] w-full bg-gray-900 group relative">
                  <img
                    src={report.incidentImageUrl?.replace(
                      "http://minio:9000",
                      "http://localhost:9000",
                    )}
                    alt="Incident Evidence"
                    className="w-full h-full object-contain"
                    onError={(e) => {
                      const target = e.target as HTMLImageElement;
                      target.onerror = null;
                      target.src =
                        "https://images.unsplash.com/photo-1517424666016-1f6b158ee6e1?auto=format&fit=crop&q=80&w=800"; // Default placeholder
                    }}
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                </div>
              ) : (
                <div className="aspect-[4/3] w-full flex items-center justify-center bg-gray-100">
                  <div className="text-center text-gray-400">
                    <Info className="mx-auto h-12 w-12 mb-2 opacity-50" />
                    <p>Không có hình ảnh bằng chứng</p>
                  </div>
                </div>
              )}
            </div>

            {/* Details Sidebar */}
            <div className="p-8 lg:col-span-1">
              <h3 className="text-sm font-semibold text-gray-900 uppercase tracking-wider mb-4 border-b border-gray-100 pb-2">
                Chi tiết Sự cố
              </h3>

              <div className="space-y-6">
                <div>
                  <h4 className="text-xs font-medium text-gray-500 uppercase">
                    Mô tả
                  </h4>
                  <p className="mt-2 text-sm text-gray-800 whitespace-pre-wrap leading-relaxed">
                    {report.description || (
                      <span className="text-gray-400 italic">
                        Không có mô tả chi tiết.
                      </span>
                    )}
                  </p>
                </div>

                <div>
                  <h4 className="text-xs font-medium text-gray-500 uppercase">
                    Thông tin Vị trí
                  </h4>
                  <div className="mt-2 bg-gray-50 rounded-lg p-3 border border-gray-100">
                    <p className="text-sm font-medium text-gray-900 mb-1">
                      {report.administrativeZoneName}
                    </p>
                    <div className="flex flex-col gap-1 text-xs font-mono text-gray-500 mt-2">
                      <span className="flex justify-between">
                        <span>Lat:</span> <span>{report.latitude}</span>
                      </span>
                      <span className="flex justify-between">
                        <span>Lng:</span> <span>{report.longitude}</span>
                      </span>
                    </div>
                  </div>
                </div>

                <div className="pt-6 mt-6 border-t border-gray-100">
                  <h4 className="text-xs font-medium text-gray-500 uppercase mb-3">
                    Thao tác Nhân viên
                  </h4>

                  {report.currentStatus === "newly_received" && (
                    <div className="space-y-2">
                      <button
                        onClick={handleAccept}
                        disabled={actionLoading}
                        className="w-full flex items-center justify-center bg-blue-50 text-blue-700 font-medium py-2 rounded-lg text-sm border border-blue-200 hover:bg-blue-100 transition-colors"
                      >
                        <CheckCircle className="w-4 h-4 mr-2" /> Tiếp nhận &
                        Đang xử lý
                      </button>

                      {!showRejectInput ? (
                        <button
                          onClick={() => setShowRejectInput(true)}
                          className="w-full flex items-center justify-center bg-white text-red-600 font-medium py-2 rounded-lg text-sm border border-red-200 hover:bg-red-50 transition-colors"
                        >
                          <XCircle className="w-4 h-4 mr-2" /> Từ chối báo cáo
                        </button>
                      ) : (
                        <div className="mt-4 space-y-2 animate-fade-in">
                          <textarea
                            value={rejectNote}
                            onChange={(e) => setRejectNote(e.target.value)}
                            placeholder="Lý do từ chối báo cáo..."
                            className="w-full border-gray-200 rounded-lg text-sm py-2 px-3 focus:ring-red-500 focus:border-red-500"
                            rows={3}
                          />
                          <div className="flex gap-2">
                            <button
                              onClick={handleReject}
                              disabled={actionLoading || !rejectNote}
                              className="flex-1 bg-red-600 text-white font-medium py-1.5 rounded-lg text-sm hover:bg-red-700 disabled:opacity-50"
                            >
                              Xác nhận từ chối
                            </button>
                            <button
                              onClick={() => setShowRejectInput(false)}
                              className="px-3 bg-gray-100 text-gray-700 font-medium py-1.5 rounded-lg text-sm hover:bg-gray-200"
                            >
                              Hủy
                            </button>
                          </div>
                        </div>
                      )}
                    </div>
                  )}

                  {report.currentStatus === "in_progress" && (
                    <div className="space-y-3">
                      {!showResolveInput ? (
                        <button
                          onClick={() => setShowResolveInput(true)}
                          className="w-full flex items-center justify-center bg-green-50 text-green-700 font-medium py-2 rounded-lg text-sm border border-green-200 hover:bg-green-100 transition-colors"
                        >
                          <CheckCircle className="w-4 h-4 mr-2" /> Đánh dấu đã
                          giải quyết
                        </button>
                      ) : (
                        <div className="space-y-3 animate-fade-in bg-green-50/50 p-3 rounded-xl border border-green-100">
                          <label className="block text-sm font-medium text-gray-700">
                            Hình ảnh minh chứng{" "}
                            <span className="text-red-500">*</span>
                          </label>
                          <input
                            type="file"
                            accept="image/jpeg, image/png"
                            onChange={(e) => {
                              if (e.target.files && e.target.files[0]) {
                                setResolveImage(e.target.files[0]);
                              }
                            }}
                            className="block w-full text-sm text-gray-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-green-100 file:text-green-700 hover:file:bg-green-200"
                          />

                          <label className="block text-sm font-medium text-gray-700 mt-2">
                            Ghi chú (Tùy chọn)
                          </label>
                          <textarea
                            value={resolveNote}
                            onChange={(e) => setResolveNote(e.target.value)}
                            placeholder="Chi tiết cách giải quyết..."
                            className="w-full border-gray-200 rounded-lg text-sm py-2 px-3 focus:ring-green-500 focus:border-green-500"
                            rows={2}
                          />

                          <div className="flex gap-2 pt-2">
                            <button
                              onClick={handleResolve}
                              disabled={actionLoading || !resolveImage}
                              className="flex-1 bg-green-600 text-white font-medium py-2 rounded-lg text-sm hover:bg-green-700 disabled:opacity-50"
                            >
                              Xác nhận giải quyết
                            </button>
                            <button
                              onClick={() => setShowResolveInput(false)}
                              className="px-4 bg-white border border-gray-200 text-gray-700 font-medium py-2 rounded-lg text-sm hover:bg-gray-50"
                            >
                              Hủy
                            </button>
                          </div>
                        </div>
                      )}
                    </div>
                  )}

                  {(report.currentStatus === "resolved" ||
                    report.currentStatus === "rejected") && (
                    <div className="text-center text-sm text-gray-500 italic py-2">
                      Báo cáo này đã đóng và không thể thay đổi trạng thái.
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
