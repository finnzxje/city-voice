import { useEffect, useState, useMemo } from "react";
import {
  AnalyticsAPI,
  IncidentAPI,
  type AnalyticsStats,
  type HeatmapPoint,
  type Category,
} from "../../api/services";
import { apiClient } from "../../api/axiosClient";
import {
  BarChart3,
  MapPin,
  TrendingUp,
  Clock,
  CheckCircle,
  AlertCircle,
  FileSpreadsheet,
  FileText,
  Filter,
  XCircle,
  Inbox,
  Layers,
  Activity,
} from "lucide-react";
import toast from "react-hot-toast";
import IncidentHeatmap from "../../components/IncidentHeatmap";



/* ─── Priority config ───────────────────────────────────────────── */
const PRIORITY_CONFIG: Record<string, { label: string; color: string; bg: string }> = {
  critical: { label: "Nghiêm trọng", color: "bg-red-500", bg: "bg-red-50 text-red-700 border-red-200" },
  high: { label: "Cao", color: "bg-orange-500", bg: "bg-orange-50 text-orange-700 border-orange-200" },
  medium: { label: "Trung bình", color: "bg-amber-400", bg: "bg-amber-50 text-amber-700 border-amber-200" },
  low: { label: "Thấp", color: "bg-sky-400", bg: "bg-sky-50 text-sky-700 border-sky-200" },
};

/* ─── Status config ────────────────────────────────────────────── */
const STATUS_CONFIG: Record<string, { label: string; dot: string }> = {
  newly_received: { label: "Mới tiếp nhận", dot: "bg-yellow-400" },
  in_progress: { label: "Đang xử lý", dot: "bg-blue-500" },
  resolved: { label: "Đã giải quyết", dot: "bg-emerald-500" },
  rejected: { label: "Từ chối", dot: "bg-red-500" },
};

/* ═══════════════════════════════════════════════════════════════════
   MANAGER DASHBOARD
   ═══════════════════════════════════════════════════════════════════ */
export default function ManagerDashboard() {
  const [stats, setStats] = useState<AnalyticsStats | null>(null);
  const [heatmapPoints, setHeatmapPoints] = useState<HeatmapPoint[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [showFilters, setShowFilters] = useState(false);

  const [filters, setFilters] = useState({
    from: "",
    to: "",
    categoryId: "",
    zoneId: "",
    priority: "",
  });

  useEffect(() => {
    IncidentAPI.getCategories()
      .then((res) => { if (res.data?.data) setCategories(res.data.data); })
      .catch(() => { });
  }, []);

  useEffect(() => {
    fetchData();
  }, [filters]);

  const filteredParams = useMemo(() =>
    Object.fromEntries(Object.entries(filters).filter(([_, v]) => v !== "")),
    [filters]
  );

  const fetchData = async () => {
    setLoading(true);
    try {
      const [statsRes, heatRes] = await Promise.all([
        AnalyticsAPI.getStats(filteredParams),
        AnalyticsAPI.getHeatmap(filteredParams),
      ]);
      if (statsRes.data?.data) setStats(statsRes.data.data);
      if (heatRes.data?.data) setHeatmapPoints(heatRes.data.data);
    } catch (err: any) {
      console.error(err);
      toast.error("Không thể tải dữ liệu thống kê.");
    } finally {
      setLoading(false);
    }
  };

  const activeFilterCount = Object.values(filters).filter((v) => v !== "").length;

  const clearFilters = () => setFilters({ from: "", to: "", categoryId: "", zoneId: "", priority: "" });

  const downloadExport = async (type: "excel" | "pdf") => {
    const filterString = new URLSearchParams(
      Object.entries(filters).filter(([_, v]) => v !== "") as any
    ).toString();
    const url = `/analytics/export/${type}?${filterString}`;
    try {
      const toastId = toast.loading(`Đang tạo tệp ${type.toUpperCase()}...`);
      const response = await apiClient.get(url, {
        responseType: "blob",
        headers: {
          Accept:
            type === "excel"
              ? "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
              : "application/pdf",
        },
      });
      const disposition = response.headers["content-disposition"];
      let filename = `cityvoice-reports.${type === "excel" ? "xlsx" : "pdf"}`;
      if (disposition && disposition.indexOf("filename=") !== -1) {
        filename = disposition.split("filename=")[1].replace(/"/g, "");
      }
      const blob = new Blob([response.data]);
      const downloadUrl = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = downloadUrl;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(downloadUrl);
      toast.success("Tải xuống thành công!", { id: toastId });
    } catch (error) {
      console.error("Lỗi khi tải xuống:", error);
      toast.error("Xuất dữ liệu thất bại.");
    }
  };

  /* ── Donut chart SVG for status breakdown ── */
  const StatusDonut = () => {
    if (!stats) return null;
    const data = [
      { key: "newly_received", value: stats.newlyReceived },
      { key: "in_progress", value: stats.inProgress },
      { key: "resolved", value: stats.resolved },
      { key: "rejected", value: stats.rejected },
    ].filter((d) => d.value > 0);

    const total = data.reduce((s, d) => s + d.value, 0);
    if (total === 0) return <p className="text-sm text-gray-400 text-center py-8">Chưa có dữ liệu</p>;

    const colors: Record<string, string> = {
      newly_received: "#facc15",
      in_progress: "#3b82f6",
      resolved: "#10b981",
      rejected: "#ef4444",
    };

    let cumulative = 0;
    const radius = 40;
    const circumference = 2 * Math.PI * radius;

    return (
      <div className="flex items-center gap-6">
        <svg width="120" height="120" viewBox="0 0 120 120" className="shrink-0">
          {data.map((d) => {
            const pct = d.value / total;
            const offset = circumference * (1 - cumulative);
            cumulative += pct;
            return (
              <circle
                key={d.key}
                cx="60" cy="60" r={radius}
                fill="none"
                stroke={colors[d.key]}
                strokeWidth="16"
                strokeDasharray={`${circumference * pct} ${circumference * (1 - pct)}`}
                strokeDashoffset={offset}
                transform="rotate(-90 60 60)"
                className="transition-all duration-500"
              />
            );
          })}
          <text x="60" y="56" textAnchor="middle" className="fill-gray-900 text-2xl font-bold" style={{ fontSize: 22 }}>
            {total}
          </text>
          <text x="60" y="74" textAnchor="middle" className="fill-gray-400" style={{ fontSize: 10 }}>
            tổng cộng
          </text>
        </svg>
        <div className="space-y-2 flex-1">
          {data.map((d) => (
            <div key={d.key} className="flex items-center gap-2">
              <span className={`h-2.5 w-2.5 rounded-full shrink-0`} style={{ backgroundColor: colors[d.key] }} />
              <span className="text-sm text-gray-600 flex-1">{STATUS_CONFIG[d.key]?.label || d.key}</span>
              <span className="text-sm font-semibold text-gray-900">{d.value}</span>
            </div>
          ))}
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-linear-to-br from-slate-50 via-gray-50 to-purple-50/30 flex flex-col">
      {/* ══ MAIN ══ */}
      <main className="flex-1 w-full space-y-6">

        {/* ── Title + Actions ── */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Tổng quan Phân tích</h1>
            <p className="mt-0.5 text-sm text-gray-500">
              Dữ liệu sự cố toàn thành phố Hồ Chí Minh
            </p>
          </div>
          <div className="flex flex-wrap gap-2">
            <button
              onClick={() => setShowFilters(!showFilters)}
              className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-medium border transition-all ${showFilters || activeFilterCount > 0
                ? "bg-primary text-white border-primary shadow-sm"
                : "bg-white text-gray-600 border-gray-200 hover:bg-gray-50"
                }`}
            >
              <Filter className="h-4 w-4" />
              Bộ lọc
              {activeFilterCount > 0 && (
                <span className="ml-1 bg-primary text-white text-[10px] font-bold h-5 w-5 rounded-full flex items-center justify-center">
                  {activeFilterCount}
                </span>
              )}
            </button>
            <button
              onClick={() => downloadExport("excel")}
              className="flex items-center gap-2 px-4 py-2.5 bg-white text-gray-600 border border-gray-200 rounded-xl text-sm font-medium hover:bg-emerald-50 hover:text-emerald-700 hover:border-emerald-200 transition-all"
            >
              <FileSpreadsheet className="h-4 w-4" /> Excel
            </button>
            <button
              onClick={() => downloadExport("pdf")}
              className="flex items-center gap-2 px-4 py-2.5 bg-white text-gray-600 border border-gray-200 rounded-xl text-sm font-medium hover:bg-rose-50 hover:text-rose-700 hover:border-rose-200 transition-all"
            >
              <FileText className="h-4 w-4" /> PDF
            </button>
          </div>
        </div>

        {/* ── Filter Panel ── */}
        {showFilters && (
          <div className="bg-white/80 backdrop-blur-sm p-5 rounded-2xl shadow-sm border border-gray-200/80 animate-in slide-in-from-top-2 duration-200">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-sm font-semibold text-gray-700 flex items-center gap-2">
                <Filter className="h-4 w-4 text-primary" /> Bộ lọc dữ liệu
              </h3>
              {activeFilterCount > 0 && (
                <button onClick={clearFilters} className="text-xs text-gray-400 hover:text-red-500 flex items-center gap-1 transition-colors">
                  <XCircle className="h-3.5 w-3.5" /> Xóa tất cả
                </button>
              )}
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5">Từ ngày</label>
                <input type="date" value={filters.from}
                  onChange={(e) => setFilters((p) => ({ ...p, from: e.target.value }))}
                  className="w-full text-sm px-3 py-2 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-shadow"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5">Đến ngày</label>
                <input type="date" value={filters.to}
                  onChange={(e) => setFilters((p) => ({ ...p, to: e.target.value }))}
                  className="w-full text-sm px-3 py-2 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-shadow"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5">Mức độ ưu tiên</label>
                <select value={filters.priority}
                  onChange={(e) => setFilters((p) => ({ ...p, priority: e.target.value }))}
                  className="w-full text-sm px-3 py-2 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-shadow bg-white"
                >
                  <option value="">Tất cả</option>
                  <option value="critical">🔴 Nghiêm trọng</option>
                  <option value="high">🟠 Cao</option>
                  <option value="medium">🟡 Trung bình</option>
                  <option value="low">🔵 Thấp</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5">Danh mục</label>
                <select value={filters.categoryId}
                  onChange={(e) => setFilters((p) => ({ ...p, categoryId: e.target.value }))}
                  className="w-full text-sm px-3 py-2 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-shadow bg-white"
                >
                  <option value="">Tất cả</option>
                  {categories.map((c) => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5">Zone ID</label>
                <input type="number" placeholder="VD: 1" value={filters.zoneId}
                  onChange={(e) => setFilters((p) => ({ ...p, zoneId: e.target.value }))}
                  className="w-full text-sm px-3 py-2 border border-gray-200 rounded-xl focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-shadow"
                />
              </div>
            </div>
          </div>
        )}

        {loading ? (
          <div className="py-20 flex flex-col items-center gap-3">
            <div className="animate-spin rounded-full h-10 w-10 border-[3px] border-gray-200 border-t-primary"></div>
            <p className="text-sm text-gray-400">Đang tải dữ liệu...</p>
          </div>
        ) : stats ? (
          <>
            {/* ── KPI CARDS ── */}
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              {/* Total */}
              <div className="bg-white rounded-2xl border border-gray-200/80 p-5 shadow-sm hover:shadow-md transition-shadow">
                <div className="flex items-center justify-between mb-3">
                  <div className="h-10 w-10 rounded-xl bg-linear-to-br from-indigo-50 to-violet-100 flex items-center justify-center">
                    <Layers className="h-5 w-5 text-indigo-600" />
                  </div>
                  <span className="text-[11px] font-semibold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full flex items-center gap-1">
                    <TrendingUp className="h-3 w-3" /> Tổng
                  </span>
                </div>
                <h3 className="text-3xl font-extrabold text-gray-900">{stats.totalReports}</h3>
                <p className="text-xs text-gray-500 mt-1 font-medium">Sự cố phát sinh</p>
              </div>

              {/* Resolved */}
              <div className="bg-white rounded-2xl border border-gray-200/80 p-5 shadow-sm hover:shadow-md transition-shadow">
                <div className="flex items-center justify-between mb-3">
                  <div className="h-10 w-10 rounded-xl bg-linear-to-br from-emerald-50 to-green-100 flex items-center justify-center">
                    <CheckCircle className="h-5 w-5 text-emerald-600" />
                  </div>
                </div>
                <div className="flex items-baseline gap-1.5">
                  <h3 className="text-3xl font-extrabold text-gray-900">{stats.completionRate?.toFixed(1) || 0}</h3>
                  <span className="text-lg font-bold text-gray-400">%</span>
                </div>
                <p className="text-xs text-gray-500 mt-1 font-medium">
                  Tỷ lệ hoàn thành ({stats.resolved}/{stats.totalReports})
                </p>
              </div>

              {/* Resolution Time */}
              <div className="bg-white rounded-2xl border border-gray-200/80 p-5 shadow-sm hover:shadow-md transition-shadow">
                <div className="flex items-center justify-between mb-3">
                  <div className="h-10 w-10 rounded-xl bg-linear-to-br from-sky-50 to-blue-100 flex items-center justify-center">
                    <Clock className="h-5 w-5 text-sky-600" />
                  </div>
                </div>
                <div className="flex items-baseline gap-1.5">
                  <h3 className="text-3xl font-extrabold text-gray-900">{stats.averageResolutionHours?.toFixed(1) || "0.0"}</h3>
                  <span className="text-sm font-semibold text-gray-400">giờ</span>
                </div>
                <p className="text-xs text-gray-500 mt-1 font-medium">TG giải quyết trung bình</p>
              </div>

              {/* In Progress */}
              <div className="bg-white rounded-2xl border border-gray-200/80 p-5 shadow-sm hover:shadow-md transition-shadow">
                <div className="flex items-center justify-between mb-3">
                  <div className="h-10 w-10 rounded-xl bg-linear-to-br from-amber-50 to-yellow-100 flex items-center justify-center">
                    <Activity className="h-5 w-5 text-amber-600" />
                  </div>
                </div>
                <h3 className="text-3xl font-extrabold text-gray-900">{stats.inProgress}</h3>
                <p className="text-xs text-gray-500 mt-1 font-medium">Đang được xử lý</p>
              </div>
            </div>

            {/* ── HEATMAP + MARKERS ── */}
            <IncidentHeatmap points={heatmapPoints} />

            {/* ── BREAKDOWN GRID ── */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
              {/* Status Donut Chart */}
              <div className="bg-white rounded-2xl border border-gray-200/80 p-6 shadow-sm">
                <h3 className="text-sm font-semibold text-gray-700 mb-5 flex items-center gap-2">
                  <Activity className="h-4 w-4 text-primary" />
                  Phân bố Trạng thái
                </h3>
                <StatusDonut />
              </div>

              {/* By Zone */}
              <div className="bg-white rounded-2xl border border-gray-200/80 p-6 shadow-sm">
                <h3 className="text-sm font-semibold text-gray-700 mb-5 flex items-center gap-2">
                  <MapPin className="h-4 w-4 text-primary" />
                  Top Khu vực
                </h3>
                <div className="space-y-3">
                  {Object.entries(stats.byZone || {}).sort((a, b) => b[1] - a[1]).slice(0, 6).map(([zone, count], idx) => (
                    <div key={idx}>
                      <div className="flex justify-between text-sm mb-1">
                        <span className="text-gray-600 truncate mr-2">{zone}</span>
                        <span className="font-semibold text-gray-900 shrink-0">{count}</span>
                      </div>
                      <div className="w-full bg-gray-100 rounded-full h-1.5">
                        <div
                          className="bg-linear-to-r from-primary to-primary-container h-1.5 rounded-full transition-all duration-500"
                          style={{ width: `${Math.max((count / stats.totalReports) * 100, 4)}%` }}
                        />
                      </div>
                    </div>
                  ))}
                  {Object.keys(stats.byZone || {}).length === 0 && (
                    <div className="text-sm text-gray-400 py-6 text-center flex flex-col items-center">
                      <Inbox className="h-8 w-8 text-gray-200 mb-2" />
                      Chưa có dữ liệu
                    </div>
                  )}
                </div>
              </div>

              {/* By Priority */}
              <div className="bg-white rounded-2xl border border-gray-200/80 p-6 shadow-sm">
                <h3 className="text-sm font-semibold text-gray-700 mb-5 flex items-center gap-2">
                  <AlertCircle className="h-4 w-4 text-primary" />
                  Mức độ Ưu tiên
                </h3>
                <div className="space-y-3">
                  {Object.entries(stats.byPriority || {}).sort((a, b) => b[1] - a[1]).map(([prio, count], idx) => {
                    const cfg = PRIORITY_CONFIG[prio];
                    return (
                      <div key={idx} className={`flex items-center justify-between p-3 rounded-xl border ${cfg?.bg || "bg-gray-50 text-gray-600 border-gray-200"}`}>
                        <span className="text-sm font-medium">{cfg?.label || prio}</span>
                        <span className="text-lg font-bold">{count}</span>
                      </div>
                    );
                  })}
                  {Object.keys(stats.byPriority || {}).length === 0 && (
                    <div className="text-sm text-gray-400 py-6 text-center flex flex-col items-center">
                      <Inbox className="h-8 w-8 text-gray-200 mb-2" />
                      Chưa có dữ liệu
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* ── By Category ── */}
            {Object.keys(stats.byCategory || {}).length > 0 && (
              <div className="bg-white rounded-2xl border border-gray-200/80 p-6 shadow-sm">
                <h3 className="text-sm font-semibold text-gray-700 mb-5 flex items-center gap-2">
                  <BarChart3 className="h-4 w-4 text-primary" />
                  Phân loại theo Danh mục
                </h3>
                <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
                  {Object.entries(stats.byCategory).sort((a, b) => b[1] - a[1]).map(([cat, count], idx) => {
                    const catColors = [
                      "from-primary to-primary-container",
                      "from-sky-500 to-blue-600",
                      "from-emerald-500 to-green-600",
                      "from-amber-500 to-orange-600",
                      "from-rose-500 to-pink-600",
                      "from-teal-500 to-cyan-600",
                    ];
                    return (
                      <div key={idx} className="relative overflow-hidden bg-gray-50 rounded-xl p-4 border border-gray-100 hover:shadow-md transition-shadow group">
                        <div className={`absolute top-0 left-0 h-1 w-full bg-linear-to-r ${catColors[idx % catColors.length]}`} />
                        <p className="text-2xl font-extrabold text-gray-900 mb-1">{count}</p>
                        <p className="text-xs text-gray-500 font-medium truncate">{cat}</p>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}
          </>
        ) : (
          <div className="text-center py-20 text-gray-400 flex flex-col items-center">
            <Inbox className="h-16 w-16 text-gray-200 mb-4" />
            <p className="text-lg font-medium text-gray-500">Không có dữ liệu hiển thị</p>
            <p className="text-sm mt-1">Hãy thử điều chỉnh bộ lọc hoặc kiểm tra kết nối backend.</p>
          </div>
        )}
      </main>
    </div>
  );
}
