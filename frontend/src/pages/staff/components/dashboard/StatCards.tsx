import { TrendingUp, CheckCircle2 } from "lucide-react";

interface StatCardsProps {
  pendingCount: number;
  processingCount: number;
  criticalCount: number;
  totalReports: number;
}

export default function StatCards({ pendingCount, processingCount, criticalCount, totalReports }: StatCardsProps) {
  return (
    <section className="grid grid-cols-1 md:grid-cols-4 gap-6">
      <div className="bg-surface-container-lowest p-6 rounded-xl transition-all hover:translate-y-[-2px] shadow-sm border border-surface-container/50">
        <p className="text-xs text-on-surface-variant font-medium uppercase tracking-wider">Chờ tiếp nhận</p>
        <div className="flex items-end justify-between mt-2">
          <h3 className="text-3xl font-extrabold text-primary font-headline">{pendingCount}</h3>
          <span className="text-[10px] px-2 py-1 bg-[#dbe1ff] text-[#00174c] rounded-full font-bold">+ Mới</span>
        </div>
      </div>
      <div className="bg-surface-container-lowest p-6 rounded-xl transition-all hover:translate-y-[-2px] shadow-sm border border-surface-container/50">
        <p className="text-xs text-on-surface-variant font-medium uppercase tracking-wider">Đang xử lý</p>
        <div className="flex items-end justify-between mt-2">
          <h3 className="text-3xl font-extrabold text-[#445ba1] font-headline">{processingCount}</h3>
          <TrendingUp className="text-[#445ba1] h-5 w-5" />
        </div>
      </div>
      <div className="bg-surface-container-lowest p-6 rounded-xl transition-all hover:translate-y-[-2px] shadow-sm border border-surface-container/50">
        <p className="text-xs text-on-surface-variant font-medium uppercase tracking-wider">Mức độ Nghiêm trọng</p>
        <div className="flex items-end justify-between mt-2">
          <h3 className="text-3xl font-extrabold text-error font-headline">{criticalCount}</h3>
          <span className="text-[10px] px-2 py-1 bg-error-container text-[#93000a] rounded-full font-bold">Focus</span>
        </div>
      </div>
      <div className="bg-surface-container-lowest p-6 rounded-xl transition-all hover:translate-y-[-2px] shadow-sm border border-surface-container/50">
        <p className="text-xs text-on-surface-variant font-medium uppercase tracking-wider">Tổng Báo Cáo</p>
        <div className="flex items-end justify-between mt-2">
          <h3 className="text-3xl font-extrabold text-[#832700] font-headline">{totalReports}</h3>
          <CheckCircle2 className="text-[#832700] h-5 w-5" />
        </div>
      </div>
    </section>
  );
}
