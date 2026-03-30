import { useEffect, useState } from "react";
import { IncidentAPI, type ReportResponse } from "../../api/services";
import { useAuth } from "../../contexts/AuthContext";
import { AlertCircle } from "lucide-react";
import IncidentTable from "./components/dashboard/IncidentTable";
import StatCards from "./components/dashboard/StatCards";
import QuickTips from "./components/dashboard/QuickTips";

const ReportManager = () => {
    const { user } = useAuth();
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
    )
}

export default ReportManager