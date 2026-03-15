import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { IncidentAPI, type ReportResponse } from "../../api/services";
import {
  ArrowLeft,
  MapPin,
  Calendar,
  Tag,
  Info,
  AlertCircle,
} from "lucide-react";

export default function CitizenReportDetails() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();

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
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
