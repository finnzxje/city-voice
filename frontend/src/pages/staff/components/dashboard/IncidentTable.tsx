import { Eye, MapPin, ChevronLeft, ChevronRight, ChevronDown, Filter } from "lucide-react";
import { type ReportResponse } from "../../../../api/services";
import { useNavigate } from "react-router-dom";

interface IncidentTableProps {
  reports: ReportResponse[];
  loading: boolean;
  filterStatus: string;
  setFilterStatus: (val: string) => void;
  filterPriority: string;
  setFilterPriority: (val: string) => void;
  page: number;
  setPage: (val: number | ((prev: number) => number)) => void;
}

export default function IncidentTable({
  reports,
  loading,
  filterStatus,
  setFilterStatus,
  filterPriority,
  setFilterPriority,
  page,
  setPage
}: IncidentTableProps) {
  const navigate = useNavigate();

  const getStatusDisplay = (status: string) => {
    switch (status) {
      case "newly_received":
        return { label: "Mới tiếp nhận", classes: "bg-orange-100 text-orange-800", dot: "bg-orange-500" };
      case "in_progress":
        return { label: "Đang xử lý", classes: "bg-blue-100 text-blue-800", dot: "bg-blue-500" };
      case "resolved":
        return { label: "Đã giải quyết", classes: "bg-green-100 text-green-800", dot: "bg-green-500" };
      case "rejected":
        return { label: "Từ chối", classes: "bg-red-100 text-red-800", dot: "bg-red-500" };
      default:
        return { label: status, classes: "bg-gray-100 text-gray-800", dot: "bg-gray-500" };
    }
  };

  const getPriorityDisplay = (priority: string | undefined | null) => {
    switch (priority) {
      case "critical": return "Nghiêm trọng";
      case "high": return "Cao";
      case "medium": return "Trung bình";
      case "low": return "Thấp";
      default: return "Chưa phân loại";
    }
  };

  const getPriorityColor = (priority: string | undefined | null) => {
    switch (priority) {
      case "critical": return "bg-error-container text-[#93000a]";
      case "high": return "bg-orange-100 text-orange-800";
      case "medium": return "bg-[#e0e3e7] text-[#424656]";
      case "low": return "bg-[#e0e3e7] text-[#424656] opacity-60";
      default: return "bg-[#e0e3e7] text-[#424656]";
    }
  };

  return (
    <div className="bg-surface-container-lowest rounded-xl overflow-hidden shadow-sm border border-surface-container/50">
      {/* Filter Bar */}
      <div className="p-6 bg-surface-container-low flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative">
            <select
              value={filterStatus}
              onChange={(e) => { setFilterStatus(e.target.value); setPage(0); }}
              className="appearance-none bg-surface-container-highest text-sm font-medium px-4 py-2 pr-10 rounded-lg border-none focus:ring-2 focus:ring-primary/40 cursor-pointer"
            >
              <option value="">Tất cả trạng thái</option>
              <option value="newly_received">Mới tiếp nhận</option>
              <option value="in_progress">Đang xử lý</option>
              <option value="resolved">Đã giải quyết</option>
              <option value="rejected">Từ chối</option>
            </select>
            <ChevronDown className="absolute right-3 top-2.5 pointer-events-none text-outline h-4 w-4" />
          </div>
          <div className="relative">
            <select
              value={filterPriority}
              onChange={(e) => { setFilterPriority(e.target.value); setPage(0); }}
              className="appearance-none bg-surface-container-highest text-sm font-medium px-4 py-2 pr-10 rounded-lg border-none focus:ring-2 focus:ring-primary/40 cursor-pointer"
            >
              <option value="">Tất cả ưu tiên</option>
              <option value="critical">Nghiêm trọng (Critical)</option>
              <option value="high">Cao (High)</option>
              <option value="medium">Trung bình (Medium)</option>
              <option value="low">Thấp (Low)</option>
            </select>
            <ChevronDown className="absolute right-3 top-2.5 pointer-events-none text-outline h-4 w-4" />
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button className="flex items-center px-4 py-2 text-sm font-semibold bg-primary hover:bg-primary-container text-on-primary rounded-lg transition-all active:scale-95 shadow-sm">
            <Filter className="h-4 w-4 mr-2" />
            Lọc kết quả
          </button>
        </div>
      </div>

      {/* Incident List Table */}
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-surface-container-low/50">
              <th className="px-6 py-4 text-xs font-bold text-on-surface-variant uppercase tracking-wider">Mã ID</th>
              <th className="px-6 py-4 text-xs font-bold text-on-surface-variant uppercase tracking-wider">Tiêu đề sự cố</th>
              <th className="px-6 py-4 text-xs font-bold text-on-surface-variant uppercase tracking-wider">Danh mục</th>
              <th className="px-6 py-4 text-xs font-bold text-on-surface-variant uppercase tracking-wider">Trạng thái</th>
              <th className="px-6 py-4 text-xs font-bold text-on-surface-variant uppercase tracking-wider">Mức ưu tiên</th>
              <th className="px-6 py-4 text-xs font-bold text-on-surface-variant uppercase tracking-wider ">Tác động</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-surface-container">
            {loading ? (
              <tr>
                <td colSpan={6} className="px-6 py-12 text-center text-outline">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
                  Đang tải dữ liệu...
                </td>
              </tr>
            ) : reports.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-6 py-12 text-center text-outline">
                  <MapPin className="mx-auto h-8 w-8 mb-2 opacity-50" />
                  Không tìm thấy sự cố nào.
                </td>
              </tr>
            ) : (
              reports.map(report => {
                const statusUi = getStatusDisplay(report.currentStatus);
                return (
                  <tr key={report.id} className="hover:bg-surface-container-low transition-colors group">
                    <td className="px-6 py-4 font-mono text-sm text-outline">#{report.id.substring(0, 8)}</td>
                    <td className="px-6 py-4">
                      <p className="text-sm font-bold group-hover:text-primary transition-colors line-clamp-1">{report.title}</p>
                      <p className="text-xs text-on-surface-variant line-clamp-1 mt-1">{report.administrativeZoneName}</p>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-[11px] font-medium px-2 py-1 bg-surface-container-highest rounded text-on-surface">
                        {report.categoryName}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center text-[10px] font-bold px-2 py-1 rounded-full ${statusUi.classes}`}>
                        <span className={`w-1.5 h-1.5 rounded-full mr-1.5 ${statusUi.dot}`}></span>
                        {statusUi.label}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center text-[10px] font-bold px-2 py-1 rounded-full ${getPriorityColor(report.priority)}`}>
                        {getPriorityDisplay(report.priority)}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <button
                        onClick={() => navigate(`/reports/${report.id}`)}
                        className="p-2 hover:bg-surface-container-highest rounded-lg transition-colors text-primary"
                        title="Xem chi tiết"
                      >
                        <Eye className="h-4 w-4" />
                      </button>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {!loading && reports.length > 0 && (
        <div className="px-6 py-4 bg-surface-container-low/30 flex items-center justify-between border-t border-surface-container">
          <p className="text-xs font-medium text-on-surface-variant">Hiển thị {reports.length} báo cáo trang hiện tại</p>
          <div className="flex items-center space-x-2">
            <button
              disabled={page === 0}
              onClick={() => setPage(p => Math.max(0, p - 1))}
              className="p-1.5 rounded-lg hover:bg-surface-container-highest disabled:opacity-30"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
            <button className="w-8 h-8 rounded-lg bg-primary text-on-primary text-xs font-bold">{page + 1}</button>
            <button
              onClick={() => setPage(p => p + 1)}
              disabled={reports.length < 10}
              className="p-1.5 rounded-lg hover:bg-surface-container-highest disabled:opacity-30"
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
