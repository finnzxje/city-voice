import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { IncidentAPI, type ReportResponse } from "../../api/services";
import { useAuth } from "../../contexts/AuthContext";
import {
  Map as MapIcon,
  List,
  AlertCircle,
  Mail,
  Clock,
  CheckCircle2,
  XCircle,
  BarChart3,
  Camera,
  ChevronDown,
  PackageOpen,
} from "lucide-react";
import Header from "../../components/Header";
import Footer from "../../components/Footer";
import IncidentHeatmap from "../../components/IncidentHeatmap";

export default function DashboardCitizen() {
  const { user } = useAuth();
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

  const getStatusDisplay = (status: string) => {
    switch (status) {
      case "newly_received":
        return {
          label: "Mới tiếp nhận",
          bg: "bg-blue-100",
          text: "text-blue-700",
          icon: <Mail size={14} />,
        };
      case "in_progress":
        return {
          label: "Đang xử lý",
          bg: "bg-amber-100",
          text: "text-amber-700",
          icon: <Clock size={14} />,
        };
      case "resolved":
        return {
          label: "Đã giải quyết",
          bg: "bg-green-100",
          text: "text-green-700",
          icon: <CheckCircle2 size={14} />,
        };
      case "rejected":
        return {
          label: "Từ chối",
          bg: "bg-red-100",
          text: "text-red-700",
          icon: <XCircle size={14} />,
        };
      default:
        return {
          label: status,
          bg: "bg-gray-100",
          text: "text-gray-700",
          icon: "info",
        };
    }
  };

  // Metrics
  const totalReports = reports.length;
  const resolvedReports = reports.filter((r) => r.currentStatus === "resolved").length;
  const inProgressReports = reports.filter((r) => r.currentStatus === "in_progress").length;

  return (
    <div className="bg-surface text-on-surface min-h-screen flex flex-col">
      <Header />

      <main className="pt-24 pb-20 px-6 max-w-7xl mx-auto flex-1 w-full">
        {/* Hero / Header Section */}
        <header className="mb-12 flex justify-between items-end">
          <div>
            <h1 className="text-4xl font-extrabold tracking-tight text-on-surface mb-2 font-headline">
              Báo cáo của tôi
            </h1>
            <p className="text-on-surface-variant text-lg max-w-2xl font-body">
              Theo dõi trạng thái và tiến độ xử lý các phản ánh của bạn về các
              vấn đề trong thành phố.
            </p>
          </div>
          <div className="flex gap-4 items-center">
            <div className="bg-white rounded-lg p-1 shadow-sm border border-gray-200 flex">
              <button
                onClick={() => setViewMode("list")}
                className={`flex items-center px-4 py-2 rounded-md text-sm font-medium transition-colors ${viewMode === "list"
                  ? "bg-primary-container/20 text-primary"
                  : "text-gray-500 hover:text-gray-700"
                  }`}
              >
                <List className="h-4 w-4 mr-2" /> List
              </button>
              <button
                onClick={() => setViewMode("map")}
                className={`flex items-center px-4 py-2 rounded-md text-sm font-medium transition-colors ${viewMode === "map"
                  ? "bg-primary-container/20 text-primary"
                  : "text-gray-500 hover:text-gray-700"
                  }`}
              >
                <MapIcon className="h-4 w-4 mr-2" /> Map
              </button>
            </div>
          </div>
        </header>

        {error && (
          <div className="mb-6 bg-red-50 border-l-4 border-red-400 p-4 rounded-md flex">
            <AlertCircle className="h-5 w-5 text-red-500 mr-3" />
            <p className="text-sm text-red-700">{error}</p>
          </div>
        )}

        {/* Summary Metrics: Bento Style */}
        <section className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-16">
          <div className="bg-surface-container-lowest p-8 rounded-xl flex flex-col justify-between border-b-4 border-primary ">
            <BarChart3 className="text-primary" size={32} />
            <p className="text-on-surface-variant font-medium text-sm font-body">
              Tổng số báo cáo
            </p>
            <h2 className="text-5xl font-extrabold text-on-surface font-headline">
              {loading ? "-" : String(totalReports).padStart(2, "0")}
            </h2>
          </div>
          <div className="bg-surface-container-lowest p-8 rounded-xl flex flex-col justify-between border-b-4 border-green-500">
            <CheckCircle2 className="text-green-600" size={32} />
            <p className="text-on-surface-variant font-medium text-sm font-body">
              Đã xử lý xong
            </p>
            <h2 className="text-5xl font-extrabold text-on-surface font-headline">
              {loading ? "-" : String(resolvedReports).padStart(2, "0")}
            </h2>
          </div>
          <div className="bg-surface-container-lowest p-8 gap-2 rounded-xl flex flex-col justify-between border-b-4 border-amber-500">

            <Clock className="text-amber-600" size={32} />
            <p className="text-on-surface-variant font-medium text-sm font-body">
              Đang giải quyết
            </p>

            <h2 className="text-5xl font-extrabold text-on-surface font-headline">
              {loading ? "-" : String(inProgressReports).padStart(2, "0")}
            </h2>
          </div>
        </section>

        {loading ? (
          <div className="py-12 flex justify-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
          </div>
        ) : viewMode === "list" ? (
          <section className="space-y-6">
            <div className="flex items-center justify-between mb-4 px-2">
              <h3 className="text-xl font-bold font-headline text-on-surface">
                Danh sách phản ánh
              </h3>
            </div>
            <div className="space-y-4">
              {reports.length === 0 ? (
                <div className="text-center py-16 bg-white rounded-2xl border border-gray-200 border-dashed">
                  <PackageOpen size={48} strokeWidth={1.5} className="text-slate-300 mx-auto" />
                  <h3 className="mt-2 text-sm font-medium text-gray-900 font-headline">
                    Không có báo cáo nào
                  </h3>
                  <p className="mt-1 text-sm text-gray-500 font-body">
                    Bạn chưa gửi báo cáo sự cố nào.
                  </p>
                </div>
              ) : (
                reports.map((report) => {
                  const statusInfo = getStatusDisplay(report.currentStatus);

                  return (
                    <div
                      key={report.id}
                      className="bg-surface-container-lowest hover:bg-surface-container-low transition-colors duration-200 p-5 rounded-xl flex flex-col md:flex-row md:items-center justify-between gap-4 font-body border border-gray-50 shadow-sm"
                    >
                      <div className="flex items-start gap-4 flex-1">
                        {report.incidentImageUrl ? (
                          <div className="h-16 w-16 rounded-lg bg-surface-container overflow-hidden shrink-0">
                            <img
                              className="w-full h-full object-cover"
                              src={report.incidentImageUrl.replace(
                                "http://minio:9000",
                                "http://localhost:9000"
                              )}
                              alt={report.title}
                              onError={(e) => {
                                const target = e.target as HTMLImageElement;
                                target.onerror = null;
                                target.src =
                                  "https://images.unsplash.com/photo-1517424666016-1f6b158ee6e1?auto=format&fit=crop&q=80&w=600";
                              }}
                            />
                          </div>
                        ) : (
                          <div className="h-16 w-16 rounded-lg bg-surface-container flex items-center justify-center shrink-0">
                            <span className="material-symbols-outlined text-slate-400">
                              no_photography
                            </span>
                          </div>
                        )}
                        <div>
                          <p className="text-xs font-bold text-primary tracking-widest uppercase mb-1">
                            #REP-{report.id.substring(0, 4).toUpperCase()}
                          </p>
                          <h4 className="text-base font-bold text-on-surface font-headline line-clamp-1">
                            {report.title}
                          </h4>
                          <p className="text-sm text-on-surface-variant mt-1 line-clamp-1">
                            {report.administrativeZoneName} - {report.categoryName}
                          </p>
                        </div>
                      </div>
                      <div className="flex flex-wrap items-center gap-6">
                        <div className="flex flex-col md:items-end">
                          <p className="text-[10px] uppercase font-bold text-outline mb-1">
                            Ngày báo cáo
                          </p>
                          <p className="text-sm font-medium">
                            {new Date(report.createdAt).toLocaleDateString("vi-VN")}
                          </p>
                        </div>
                        <div className="min-w-[140px] flex justify-end">
                          <span
                            className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-bold ${statusInfo.bg} ${statusInfo.text}`}
                          >
                            <span className="material-symbols-outlined text-xs mr-1">
                              {statusInfo.icon}
                            </span>
                            {statusInfo.label}
                          </span>
                        </div>
                        <button
                          onClick={() => navigate(`/reports/${report.id}`)}
                          className="px-4 py-2 text-sm font-bold bg-primary text-white hover:bg-primary-container rounded-lg transition-all shadow-sm active:scale-95"
                        >
                          View Details
                        </button>
                      </div>
                    </div>
                  );
                })
              )}
            </div>

            {reports.length > 0 && (
              <div className="mt-12 flex justify-center">
                <button className="px-6 py-3 text-sm font-bold bg-white text-on-surface border border-outline-variant hover:bg-surface-container-low rounded-full transition-all flex items-center gap-2">
                  Xem thêm báo cáo cũ
                  <ChevronDown size={18} />
                </button>
              </div>
            )}
          </section>
        ) : (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden min-h-[500px]">
            <IncidentHeatmap
              points={reports
                .filter((r) => r.latitude && r.longitude)
                .map((r) => ({
                  latitude: r.latitude,
                  longitude: r.longitude,
                  priority: r.priority || "low",
                  category: r.categoryName,
                }))}
            />
          </div>
        )}

        {/* Call to Action Section */}
        <section className="mt-20 p-10 bg-linear-to-br from-primary to-primary-container rounded-3xl text-white relative overflow-hidden shadow-xl">
          <div className="relative z-10 max-w-xl">
            <h3 className="text-3xl font-bold mb-4 font-headline">
              Bạn phát hiện sự cố mới?
            </h3>
            <p className="text-blue-100 text-lg mb-8 font-body">
              Chụp ảnh và gửi báo cáo ngay để cùng chung tay xây dựng thành phố
              văn minh, sạch đẹp hơn.
            </p>
            <button
              onClick={() => navigate("/reports/new")}
              className="px-8 py-4 bg-white text-primary font-bold rounded-xl hover:shadow-lg transition-all flex items-center gap-2 font-body"
            >
              <Camera size={24} />
              Tạo báo cáo mới
            </button>
          </div>
          {/* Decorative circle */}
          <div className="absolute -right-20 -bottom-20 w-80 h-80 bg-white/10 rounded-full blur-3xl"></div>
        </section>
      </main>

      <Footer />
    </div>
  );
}
