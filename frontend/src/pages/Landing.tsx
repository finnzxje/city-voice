import { Link, Navigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import {
  MapPin,
  Activity,
  Shield,
  Users,
  ArrowRight,
  CheckCircle,
  Clock,
  AlertCircle,
  TrendingUp,
} from "lucide-react";
import img1 from "../assets/image1.png";
import img2 from "../assets/image2.png";
import img3 from "../assets/image3.png";
import img4 from "../assets/image4.png";
import img5 from "../assets/image5.png";
const EXAMPLES = [
  {
    id: 1,
    category: "Đường & Vỉa hè",
    tag: "Đã giải quyết",
    tagStatus: "resolved",
    icon: "🕳️",
    district: "Quận Bình Thạnh",
    title: "Ổ gà lớn trên đường Đinh Bộ Lĩnh",
    description:
      "Người dân báo cáo ổ gà sâu 15cm gây nguy hiểm cho xe máy vào ban đêm, đặc biệt sau mưa lớn.",
    before: img1,
    after: img2,
    resolvedIn: "3 ngày",
    upvotes: 47,
  },
  {
    id: 2,
    category: "Chiếu sáng công cộng",
    tag: "Đang xử lý",
    tagStatus: "pending",
    icon: "💡",
    district: "Quận 3",
    title: "Đèn đường hỏng tại Hẻm 12 Lý Chính Thắng",
    description:
      "4 cột đèn liên tiếp không hoạt động trong 2 tuần, gây mất an toàn cho người đi bộ ban đêm.",
    before: img3,
    after: null,
    resolvedIn: null,
    upvotes: 31,
    assignedTo: "Công ty Điện lực TP.HCM",
  },
  {
    id: 3,
    category: "Thoát nước",
    tag: "Đã giải quyết",
    tagStatus: "resolved",
    icon: "🌊",
    district: "Quận 7",
    title: "Cống thoát nước tắc nghẽn gây ngập cục bộ",
    description:
      "Ngập nước 30–40cm mỗi khi mưa lớn tại giao lộ Nguyễn Lương Bằng – Lê Văn Lương, ảnh hưởng giao thông giờ cao điểm.",
    before: img4,
    after: img5,
    resolvedIn: "5 ngày",
    upvotes: 89,
  },
];

const STATS = [
  {
    label: "Báo cáo đã tiếp nhận",
    value: "12.400+",
    icon: <Activity size={20} />,
  },
  {
    label: "Sự cố đã giải quyết",
    value: "9.800+",
    icon: <CheckCircle size={20} />,
  },
  { label: "Thời gian xử lý TB", value: "4,2 ngày", icon: <Clock size={20} /> },
  {
    label: "Quận/huyện tham gia",
    value: "22 / 22",
    icon: <MapPin size={20} />,
  },
];

function TagBadge({ status, label }: { status: any; label: any }) {
  if (status === "resolved") {
    return (
      <span className="inline-flex items-center gap-1 text-xs font-semibold px-2.5 py-1 rounded-full bg-green-100 text-green-700">
        <CheckCircle size={11} /> {label}
      </span>
    );
  }
  return (
    <span className="inline-flex items-center gap-1 text-xs font-semibold px-2.5 py-1 rounded-full bg-amber-100 text-amber-700">
      <Clock size={11} /> {label}
    </span>
  );
}

export default function Landing() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="h-screen w-full flex items-center justify-center bg-gray-50 text-gray-500">
        Loading CityVoice...
      </div>
    );
  }

  if (isAuthenticated) {
    return <Navigate to="/" replace />;
  }

  return (
    <div className="min-h-screen bg-white">
      {/* Navigation */}
      <nav className="absolute top-0 w-full z-50 bg-white/50 backdrop-blur-md border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center gap-2">
              <div className="bg-indigo-600 p-2 rounded-xl text-white transform rotate-3 shadow-sm">
                <Activity size={24} className="-rotate-3" />
              </div>
              <span className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-indigo-600 to-blue-600">
                CityVoice
              </span>
            </div>
            <div className="flex items-center gap-4">
              <Link
                to="/login"
                className="text-gray-600 hover:text-indigo-600 font-medium transition-colors"
              >
                Đăng nhập
              </Link>
              <Link
                to="/register"
                className="bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2 rounded-xl font-medium transition-all shadow-md shadow-indigo-200 hover:shadow-lg hover:-translate-y-0.5"
              >
                Đăng ký
              </Link>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <div className="relative pt-32 pb-20 lg:pt-48 lg:pb-32 overflow-hidden">
        <div className="absolute top-0 right-0 -translate-y-12 translate-x-1/3 blur-3xl opacity-30 pointer-events-none">
          <div className="aspect-square w-96 bg-gradient-to-br from-indigo-400 to-purple-400 rounded-full mix-blend-multiply animate-blob"></div>
        </div>
        <div className="absolute top-0 left-0 translate-y-24 -translate-x-1/3 blur-3xl opacity-30 pointer-events-none">
          <div className="aspect-square w-96 bg-gradient-to-tr from-blue-400 to-teal-400 rounded-full mix-blend-multiply animate-blob animation-delay-2000"></div>
        </div>

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className="text-center max-w-4xl mx-auto">
            <h1 className="text-5xl md:text-6xl lg:text-7xl font-extrabold text-gray-900 tracking-tight leading-tight mb-8">
              Cùng người dân kiến tạo{" "}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-600 to-teal-500">
                Thành phố Hồ Chí Minh
              </span>
            </h1>
            <p className="text-xl md:text-2xl text-gray-600 mb-10 max-w-3xl mx-auto leading-relaxed">
              Báo cáo sự cố hạ tầng tức thì. Theo dõi tiến độ giải quyết theo
              thời gian thực. Cùng chung tay để thành phố của chúng ta trở nên
              tốt đẹp và an toàn hơn - bắt đầu từ một báo cáo.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
              <Link
                to="/register"
                className="group w-full sm:w-auto flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white px-8 py-4 rounded-2xl font-semibold text-lg transition-all shadow-xl shadow-indigo-200 hover:shadow-2xl hover:-translate-y-1"
              >
                Bắt đầu ngay
                <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
              </Link>
              <Link
                to="/login"
                className="w-full sm:w-auto flex items-center justify-center bg-white hover:bg-gray-50 text-gray-700 border border-gray-200 px-8 py-4 rounded-2xl font-semibold text-lg transition-all hover:shadow-md"
              >
                Cổng nhân viên
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Stats Bar */}
      <div className="bg-indigo-600 py-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
            {STATS.map((s) => (
              <div key={s.label} className="flex flex-col items-center gap-1">
                <div className="text-indigo-200 mb-1">{s.icon}</div>
                <div className="text-3xl font-extrabold text-white">
                  {s.value}
                </div>
                <div className="text-indigo-200 text-sm font-medium">
                  {s.label}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="bg-gray-50 py-24 sm:py-32">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl">
              Cách CityVoice hoạt động
            </h2>
            <p className="mt-4 text-lg text-gray-600">
              Quy trình quản lý vòng đời cơ sở hạ tầng đô thị minh bạch và hiệu
              quả.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-12 max-w-5xl mx-auto">
            <div className="text-center group">
              <div className="mx-auto w-16 h-16 bg-blue-100 text-blue-600 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 group-hover:bg-blue-600 group-hover:text-white transition-all duration-300 shadow-sm">
                <MapPin size={32} />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">
                1. Báo cáo dễ dàng
              </h3>
              <p className="text-gray-600 leading-relaxed">
                Chụp ảnh và gửi đi. Chúng tôi tự động trích xuất tọa độ GPS của
                bạn để xác định chính xác vị trí tại khu vực TP.HCM.
              </p>
            </div>

            <div className="text-center group">
              <div className="mx-auto w-16 h-16 bg-teal-100 text-teal-600 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 group-hover:bg-teal-600 group-hover:text-white transition-all duration-300 shadow-sm">
                <Users size={32} />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">
                2. Tiếp nhận & Phân loại
              </h3>
              <p className="text-gray-600 leading-relaxed">
                Các cơ quan chức năng thuộc thành phố sẽ liên tục kiểm tra báo
                cáo của bạn, chỉ định mức độ ưu tiên và điều động đội ngũ xử lý
                phù hợp.
              </p>
            </div>

            <div className="text-center group">
              <div className="mx-auto w-16 h-16 bg-indigo-100 text-indigo-600 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 group-hover:bg-indigo-600 group-hover:text-white transition-all duration-300 shadow-sm">
                <Shield size={32} />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">
                3. Sự cố được giải quyết
              </h3>
              <p className="text-gray-600 leading-relaxed">
                Nhận thông báo ngay khi sự cố được khắc phục xong, đi kèm bằng
                chứng hình ảnh nghiệm thu thực tế từ đội ngũ nhân viên hiện
                trường.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* ── REAL-WORLD EXAMPLES SECTION ── */}
      <div className="bg-white py-24 sm:py-32">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          {/* Header */}
          <div className="text-center mb-16">
            <span className="inline-block text-sm font-semibold text-indigo-600 bg-indigo-50 px-4 py-1.5 rounded-full mb-4 tracking-wide uppercase">
              Từ cộng đồng
            </span>
            <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl">
              Những báo cáo thực tế đã tạo ra thay đổi
            </h2>
            <p className="mt-4 text-lg text-gray-600 max-w-2xl mx-auto">
              Mỗi báo cáo là một hành động cụ thể. Xem người dân TP.HCM đã phát
              hiện và giải quyết vấn đề như thế nào.
            </p>
          </div>

          {/* Cards */}
          <div className="grid md:grid-cols-3 gap-8">
            {EXAMPLES.map((ex) => (
              <div
                key={ex.id}
                className="bg-white border border-gray-100 rounded-3xl shadow-sm hover:shadow-xl transition-all duration-300 hover:-translate-y-1 overflow-hidden flex flex-col"
              >
                {/* Image area */}
                <div className="relative bg-gray-100 h-44 flex items-center justify-center overflow-hidden">
                  {ex.tagStatus === "resolved" ? (
                    <div className="w-full h-full flex">
                      <div className="flex-1 relative">
                        <img
                          src={ex.before}
                          alt="Trước"
                          className="w-full h-full object-cover"
                        />
                        <span className="absolute bottom-2 left-2 text-[10px] font-bold bg-black/60 text-white px-2 py-0.5 rounded-full">
                          TRƯỚC
                        </span>
                      </div>
                      <div className="w-px bg-white/60 z-10" />
                      <div className="flex-1 relative">
                        <img
                          src={ex.after || undefined}
                          alt="Sau"
                          className="w-full h-full object-cover"
                        />
                        <span className="absolute bottom-2 right-2 text-[10px] font-bold bg-green-600 text-white px-2 py-0.5 rounded-full">
                          SAU
                        </span>
                      </div>
                    </div>
                  ) : (
                    <div className="w-full h-full relative">
                      <img
                        src={ex.before}
                        alt="Ảnh báo cáo"
                        className="w-full h-full object-cover"
                      />
                    </div>
                  )}

                  {/* Category chip */}
                  <div className="absolute top-3 left-3">
                    <span className="text-xs font-semibold bg-white/90 backdrop-blur-sm text-gray-700 px-2.5 py-1 rounded-full shadow-sm">
                      {ex.icon} {ex.category}
                    </span>
                  </div>
                </div>

                {/* Content */}
                <div className="p-5 flex flex-col flex-1">
                  <div className="flex items-center justify-between mb-3">
                    <TagBadge status={ex.tagStatus} label={ex.tag} />
                    <span className="text-xs text-gray-400 flex items-center gap-1">
                      <MapPin size={11} /> {ex.district}
                    </span>
                  </div>

                  <h3 className="font-semibold text-gray-900 mb-2 leading-snug">
                    {ex.title}
                  </h3>
                  <p className="text-sm text-gray-500 leading-relaxed flex-1">
                    {ex.description}
                  </p>

                  {/* Footer meta */}
                  <div className="mt-4 pt-4 border-t border-gray-100 flex items-center justify-between text-sm">
                    <div className="flex items-center gap-1 text-gray-500">
                      <TrendingUp size={13} className="text-indigo-400" />
                      <span>{ex.upvotes} người ủng hộ</span>
                    </div>
                    {ex.resolvedIn ? (
                      <span className="flex items-center gap-1 text-green-600 font-medium">
                        <CheckCircle size={13} />
                        Xử lý trong {ex.resolvedIn}
                      </span>
                    ) : (
                      <span className="flex items-center gap-1 text-amber-600 font-medium text-xs">
                        <AlertCircle size={13} />
                        {ex.assignedTo}
                      </span>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Category tags */}
          <div className="mt-16 text-center">
            <p className="text-sm font-semibold text-gray-500 mb-4 uppercase tracking-wider">
              Các loại sự cố thường gặp
            </p>
            <div className="flex flex-wrap justify-center gap-3">
              {[
                "🕳️ Ổ gà, hư đường",
                "💡 Đèn đường hỏng",
                "🌊 Ngập nước, tắc cống",
                "🗑️ Rác thải tồn đọng",
                "🌳 Cây ngã, gãy cành",
                "🚧 Hư hỏng vỉa hè",
                "🚰 Bể đường ống nước",
                "📶 Hư cơ sở hạ tầng khác",
              ].map((tag) => (
                <span
                  key={tag}
                  className="text-sm bg-gray-50 border border-gray-200 text-gray-600 px-4 py-2 rounded-full hover:border-indigo-300 hover:bg-indigo-50 hover:text-indigo-700 transition-colors cursor-default"
                >
                  {tag}
                </span>
              ))}
            </div>
          </div>

          {/* CTA inline */}
          <div className="mt-16 bg-gradient-to-br from-indigo-600 to-blue-600 rounded-3xl p-10 text-center shadow-2xl shadow-indigo-200">
            <h3 className="text-2xl font-bold text-white mb-3">
              Bạn thấy sự cố nào gần nhà?
            </h3>
            <p className="text-indigo-100 mb-6">
              Chỉ cần 30 giây — chụp ảnh, mô tả ngắn, gửi đi. Đội ngũ của thành
              phố sẽ tiếp nhận ngay.
            </p>
            <Link
              to="/register"
              className="inline-flex items-center gap-2 bg-white text-indigo-700 font-semibold px-8 py-3 rounded-2xl hover:bg-indigo-50 transition-all shadow-lg hover:shadow-xl hover:-translate-y-0.5"
            >
              Gửi báo cáo đầu tiên <ArrowRight size={18} />
            </Link>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-100 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center text-gray-500">
          <p>
            © {new Date().getFullYear()} Nền tảng CityVoice - Thành phố Hồ Chí
            Minh.
          </p>
        </div>
      </footer>
    </div>
  );
}
