import { useEffect, useState } from "react";
import { IncidentAPI, type ReportResponse } from "../../api/services";
import { useAuth } from "../../contexts/AuthContext";
import {
  LogOut,
  LayoutDashboard,
  TriangleAlert,
  User,
  AlertCircle,
  MapPin,
  Bell,
  Building2,
} from "lucide-react";
import StatCards from "./components/dashboard/StatCards";
import IncidentTable from "./components/dashboard/IncidentTable";
import QuickTips from "./components/dashboard/QuickTips";
import { Link } from "react-router-dom";

export default function StaffDashboard() {
  const { user, logout } = useAuth();
  const [reports, setReports] = useState<ReportResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Staff Filters
  const [filterStatus, setFilterStatus] = useState("");
  const [filterPriority, setFilterPriority] = useState("");
  const [page, setPage] = useState(0);

  useEffect(() => {
    fetchReports();
  }, [user, filterStatus, filterPriority, page]);

  const fetchReports = async () => {
    setLoading(true);
    try {
      const res = await IncidentAPI.getAllReports({
        status: filterStatus || undefined,
        priority: filterPriority || undefined,
        page: page,
        size: 10,
      });
      setReports(res.data.data.content);
    } catch (err: any) {
      setError(err.response?.data?.message || "Lỗi khi tải danh sách báo cáo.");
    } finally {
      setLoading(false);
    }
  };

  const pendingCount = reports.filter(r => r.currentStatus === 'newly_received').length;
  const processingCount = reports.filter(r => r.currentStatus === 'in_progress').length;
  const criticalCount = reports.filter(r => r.priority === 'critical').length;


  return (
    <div className="min-h-screen bg-surface text-on-surface flex font-body">
      {/* SideNavBar (The Anchor) */}
      <aside className="hidden md:flex flex-col h-screen p-4 space-y-2 w-64 fixed left-0 top-0 bg-[#ffffff] border-r border-surface-container z-50">
        <div className="px-4">
          <div className="flex items-center gap-3 group cursor-pointer">
            <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center text-white shadow-lg group-hover:rotate-12 transition-transform duration-500">
              <Building2 size={20} />
            </div>
            <span className="font-headline font-extrabold text-xl tracking-tight text-primary">CityVoice</span>
          </div>
        </div>
        <nav className="flex-1 space-y-1 py-5">
          <Link to="/" className="flex items-center px-4 py-3 text-on-surface hover:text-primary hover:bg-primary/10 transition-all duration-200 cursor-pointer text-sm font-medium rounded-lg">
            <LayoutDashboard className="mr-3 h-5 w-5" />
            Dashboard
          </Link>

        </nav>
        <div className="pt-4 mt-auto border-t border-surface-container">
          <div className="flex items-center px-4 py-3 mb-4">
            <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold">
              {user?.fullName?.charAt(0) || user?.email?.charAt(0) || 'S'}
            </div>
            <div className="ml-3 overflow-hidden">
              <p className="text-sm font-bold truncate">{user?.fullName || 'Staff Member'}</p>
              <p className="text-xs text-on-surface-variant truncate">
                Staff
              </p>
            </div>
          </div>
          <button onClick={logout} className="w-full flex items-center px-4 py-3 text-on-surface hover:bg-red-50 hover:text-red-600 transition-all duration-200 cursor-pointer text-sm font-medium rounded-lg">
            <LogOut className="mr-3 h-5 w-5" />
            Đăng xuất
          </button>
        </div>
      </aside>

      {/* Main Content Canvas */}
      <main className="flex-1 md:ml-64 min-h-screen bg-surface flex flex-col">
        {/* TopAppBar */}
        <header className="sticky top-0 w-full flex items-center justify-between px-6 h-16 bg-[#f7fafe]/70 backdrop-blur-xl z-40 border-b border-surface-container/50">
          <div className="flex items-center">
            <h1 className="text-xl font-bold tracking-tight text-on-surface font-headline antialiased">
              Quản lý báo cáo sự cố
            </h1>
          </div>
          <div className="flex items-center space-x-4">
            <div className="relative hidden sm:block">
              <span className="absolute inset-y-0 left-0 pl-3 flex items-center text-outline">
                <MapPin className="text-sm h-4 w-4" />
              </span>
              <input
                className="bg-surface-container-low border-none rounded-full py-2 pl-10 pr-4 text-sm focus:ring-2 focus:ring-primary/40 w-64 transition-all"
                placeholder="Tìm kiếm sự cố..."
                type="text"
              />
            </div>
            <button className="p-2 text-on-surface-variant hover:bg-surface-container-low rounded-full transition-colors active:scale-95">
              <Bell className="h-5 w-5" />
            </button>
            <button className="p-2 text-on-surface-variant hover:bg-surface-container-low rounded-full transition-colors active:scale-95">
              <User className="h-5 w-5" />
            </button>
          </div>
        </header>

        {/* Content Body */}
        <div className="p-6 md:p-10 max-w-7xl mx-auto w-full space-y-8">
          {error && (
            <div className="bg-error-container text-[#93000a] p-4 rounded-xl flex items-center">
              <AlertCircle className="h-5 w-5 mr-3" />
              <p className="text-sm font-medium">{error}</p>
            </div>
          )}

          {/* Hero Stats / Summary Section */}
          <StatCards
            pendingCount={pendingCount}
            processingCount={processingCount}
            criticalCount={criticalCount}
            totalReports={reports.length}
          />

          {/* Filters and Table Container */}
          <IncidentTable
            reports={reports}
            loading={loading}
            filterStatus={filterStatus}
            setFilterStatus={setFilterStatus}
            filterPriority={filterPriority}
            setFilterPriority={setFilterPriority}
            page={page}
            setPage={setPage}
          />

          {/* Asymmetric Design Element: Quick Tips / Manuals */}
          <QuickTips />
        </div>

        {/* Mobile Sticky Nav */}
        <nav className="md:hidden fixed bottom-0 w-full bg-surface-container-lowest flex justify-around items-center h-16 shadow-[0_-4px_16px_rgba(0,0,0,0.05)] border-t border-surface-container z-50">
          <button className="flex flex-col items-center justify-center w-full text-on-surface-variant">
            <LayoutDashboard className="h-5 w-5" />
            <span className="text-[10px] mt-1 font-medium">Dashboard</span>
          </button>
          <button className="flex flex-col items-center justify-center w-full text-primary">
            <TriangleAlert className="h-5 w-5 fill-current" />
            <span className="text-[10px] mt-1 font-bold">Sự cố</span>
          </button>
          <button className="flex flex-col items-center justify-center w-full text-on-surface-variant">
            <Bell className="h-5 w-5" />
            <span className="text-[10px] mt-1 font-medium">Thông báo</span>
          </button>
          <button onClick={logout} className="flex flex-col items-center justify-center w-full text-on-surface-variant">
            <LogOut className="h-5 w-5" />
            <span className="text-[10px] mt-1 font-medium">Thoát</span>
          </button>
        </nav>
      </main>
    </div>
  );
}

