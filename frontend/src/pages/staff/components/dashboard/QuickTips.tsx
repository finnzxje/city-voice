import { Rocket, ShieldCheck, Phone, Mail } from "lucide-react";

export default function QuickTips() {
  return (
    <div className="flex flex-col lg:flex-row gap-8 mt-12 pb-12">
      <div className="lg:w-2/3">
        <h3 className="text-xl font-bold font-headline mb-6">Hướng dẫn Quy trình Xử lý</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="group p-5 rounded-xl bg-gradient-to-br from-primary to-primary-container text-on-primary shadow-md">
            <Rocket className="h-8 w-8 mb-4 opacity-90" />
            <h4 className="text-lg font-bold mb-2 font-headline">Ưu tiên Critical</h4>
            <p className="text-sm opacity-90 leading-relaxed font-medium">Đối với các sự cố Critical, nhân viên phải phản hồi trong vòng 15 phút và thực hiện phân công ngay lập tức cho đội hiện trường.</p>
          </div>
          <div className="p-5 rounded-xl bg-surface-container-high border border-outline-variant/20">
            <ShieldCheck className="h-8 w-8 mb-4 text-[#445ba1]" />
            <h4 className="text-lg font-bold mb-2 text-on-surface font-headline">Kiểm tra Xác thực</h4>
            <p className="text-sm text-on-surface-variant leading-relaxed">Luôn đối chiếu hình ảnh thực tế đính kèm từ người dân trước khi chuyển trạng thái "Đang xử lý".</p>
          </div>
        </div>
      </div>

      {/* Glassmorphism help card */}
      <div className="lg:w-1/3 flex flex-col justify-center relative overflow-hidden rounded-2xl bg-surface-container-highest p-8 border border-surface-container">
        <div className="absolute -right-10 -top-10 w-40 h-40 bg-primary/10 rounded-full blur-3xl"></div>
        <div className="relative z-10">
          <h3 className="text-lg font-bold mb-4 font-headline">Hỗ trợ Kỹ thuật</h3>
          <p className="text-sm text-on-surface-variant mb-6">Bạn gặp khó khăn trong việc vận hành hệ thống? Liên hệ ngay với bộ phận IT chuyên trách.</p>
          <div className="flex flex-col gap-3">
            <div className="flex items-center gap-3 text-sm font-medium">
              <Phone className="h-4 w-4 text-primary" />
              1900 8888 (Ext 102)
            </div>
            <div className="flex items-center gap-3 text-sm font-medium">
              <Mail className="h-4 w-4 text-primary" />
              tech-support@civicarchitect.gov
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
