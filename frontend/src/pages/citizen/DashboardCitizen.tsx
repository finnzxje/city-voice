import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { IncidentAPI, type ReportResponse } from "../../api/services";
import { useAuth } from "../../contexts/AuthContext";
import {
  PlusCircle,
  Map as MapIcon,
  List,
  AlertCircle,
  MapPin,
  ExternalLink,
  LogOut,
} from "lucide-react";

export default function CitizenDashboard() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [reports, setReports] = useState<ReportResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [viewMode, setViewMode] = useState<"list" | "map">("list");

  useEffect(() => {
    fetchReports();
  }, [user]);

  const fetchReports = async () => {
    setLoading(true);
    try {
      const res = await IncidentAPI.getMyReports();
      setReports(res.data.data);
    } catch (err: any) {
      setError(err.response?.data?.message || "Lỗi khi tải danh sách báo cáo.");
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case "newly_received":
        return "bg-yellow-100 text-yellow-800 border-yellow-200";
      case "in_progress":
        return "bg-blue-100 text-blue-800 border-blue-200";
      case "resolved":
        return "bg-green-100 text-green-800 border-green-200";
      case "rejected":
        return "bg-red-100 text-red-800 border-red-200";
      default:
        return "bg-gray-100 text-gray-800 border-gray-200";
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <header className="bg-white/80 backdrop-blur-lg border-b border-gray-200 sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16 items-center">
            <div className="flex items-center">
              <div className="flex-shrink-0 flex items-center gap-3">
                <div className="h-8 w-8 bg-indigo-600 rounded-lg flex items-center justify-center transform rotate-3">
                  <MapPin className="text-white h-5 w-5 transform -rotate-3" />
                </div>
                <span className="font-bold text-xl text-gray-900 tracking-tight">
                  CityVoice
                </span>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm font-medium text-gray-500 hidden sm:block">
                Xin chào, {user?.fullName || user?.email}
              </span>
              <button
                onClick={() => navigate("/reports/new")}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-xl shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 transition-colors"
              >
                <PlusCircle className="-ml-1 mr-2 h-4 w-4" />
                Báo cáo mới
              </button>
              <button
                onClick={logout}
                className="p-2 text-gray-400 hover:text-red-500 transition-colors rounded-lg hover:bg-red-50"
                title="Đăng xuất"
              >
                <LogOut className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 w-full max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex justify-between items-end mb-6">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Báo cáo sự cố</h1>
            <p className="mt-1 text-sm text-gray-500">
              Các báo cáo bạn đã gửi
            </p>
          </div>

          <div className="flex gap-4 items-center">
            <div className="bg-white rounded-lg p-1 shadow-sm border border-gray-200 flex">
              <button
                onClick={() => setViewMode("list")}
                className={`flex items-center px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
                  viewMode === "list"
                    ? "bg-indigo-50 text-indigo-700"
                    : "text-gray-500 hover:text-gray-700"
                }`}
              >
                <List className="h-4 w-4 mr-2" /> List
              </button>
              <button
                onClick={() => setViewMode("map")}
                className={`flex items-center px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
                  viewMode === "map"
                    ? "bg-indigo-50 text-indigo-700"
                    : "text-gray-500 hover:text-gray-700"
                }`}
              >
                <MapIcon className="h-4 w-4 mr-2" /> Map
              </button>
            </div>
          </div>
        </div>

        {error && (
          <div className="mb-6 bg-red-50 border-l-4 border-red-400 p-4 rounded-md flex">
            <AlertCircle className="h-5 w-5 text-red-500 mr-3" />
            <p className="text-sm text-red-700">{error}</p>
          </div>
        )}

        {loading ? (
          <div className="py-12 flex justify-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
          </div>
        ) : reports.length === 0 ? (
          <div className="text-center py-16 bg-white rounded-2xl border border-gray-200 border-dashed">
            <MapPin className="mx-auto h-12 w-12 text-gray-300" />
            <h3 className="mt-2 text-sm font-medium text-gray-900">
              Không tìm thấy báo cáo
            </h3>
            <p className="mt-1 text-sm text-gray-500">
              Bạn chưa gửi báo cáo sự cố nào.
            </p>
            <div className="mt-6">
              <button
                onClick={() => navigate("/reports/new")}
                className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <PlusCircle className="-ml-1 mr-2 h-5 w-5" aria-hidden="true" />
                Báo cáo mới
              </button>
            </div>
          </div>
        ) : viewMode === "list" ? (
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {reports.map((report) => (
              <div
                key={report.id}
                className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-shadow group flex flex-col"
              >
                {report.incidentImageUrl ? (
                  <div className="aspect-video w-full bg-gray-100 relative overflow-hidden">
                    <img
                      src={report.incidentImageUrl?.replace(
                        "http://minio:9000",
                        "http://localhost:9000",
                      )}
                      alt={report.title}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      onError={(e) => {
                        const target = e.target as HTMLImageElement;
                        target.onerror = null;
                        target.src =
                          "https://images.unsplash.com/photo-1517424666016-1f6b158ee6e1?auto=format&fit=crop&q=80&w=600";
                      }}
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent" />
                    <div className="absolute bottom-3 left-3 flex space-x-2">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-white/90 text-gray-800 shadow-sm">
                        {report.categoryName}
                      </span>
                    </div>
                  </div>
                ) : (
                  <div className="aspect-video w-full bg-gray-100 flex items-center justify-center">
                    <MapPin className="h-10 w-10 text-gray-300" />
                  </div>
                )}

                <div className="p-5 flex-1 flex flex-col">
                  <div className="flex justify-between items-start mb-2">
                    <h3 className="text-lg font-semibold text-gray-900 group-hover:text-indigo-600 transition-colors line-clamp-1">
                      {report.title}
                    </h3>
                  </div>

                  <p className="text-sm text-gray-500 line-clamp-2 mb-4 flex-1">
                    {report.description || "Không có mô tả."}
                  </p>

                  <div className="mt-auto space-y-3">
                    <div className="flex items-center text-xs text-gray-500">
                      <MapPin className="mr-1.5 h-3.5 w-3.5 flex-shrink-0 text-gray-400" />
                      <span className="truncate">
                        {report.administrativeZoneName}
                      </span>
                    </div>

                    <div className="flex items-center justify-between pt-3 border-t border-gray-50">
                      <span
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-md text-xs font-semibold border ${getStatusColor(
                          report.currentStatus,
                        )}`}
                      >
                        {report.currentStatus.replace("_", " ").toUpperCase()}
                      </span>

                      <button
                        onClick={() => navigate(`/reports/${report.id}`)}
                        className="text-indigo-600 hover:text-indigo-800 text-sm font-medium flex items-center"
                      >
                        Chi tiết
                        <ExternalLink className="ml-1 h-3.5 w-3.5" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden h-[600px] flex items-center justify-center">
            <div className="text-center p-8">
              <MapIcon className="mx-auto h-12 w-12 text-indigo-300 mb-4" />
              <h3 className="text-lg font-medium text-gray-900">
                Chế độ Bản đồ
              </h3>
              <p className="mt-2 text-sm text-gray-500 max-w-sm mx-auto">
                Bản đồ tương tác với các điểm báo cáo sự cố (Sẽ tích hợp React
                Leaflet tại đây).
              </p>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
