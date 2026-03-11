import { Link, Navigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import { MapPin, Activity, Shield, Users, ArrowRight } from "lucide-react";

export default function Landing() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="h-screen w-full flex items-center justify-center bg-gray-50 text-gray-500">
        Loading CityVoice...
      </div>
    );
  }

  // If already logged in, go straight to dashboard
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
        {/* Decorative blobs */}
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
              thời gian thực. Cùng chung tay để thành phố của chúng ta trở nên tốt
              đẹp và an toàn hơn - bắt đầu từ một báo cáo.
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

      {/* Features Section */}
      <div className="bg-gray-50 py-24 sm:py-32">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl font-bold text-gray-900 sm:text-4xl">
              Cách CityVoice hoạt động
            </h2>
            <p className="mt-4 text-lg text-gray-600">
              Quy trình quản lý vòng đời cơ sở hạ tầng đô thị minh bạch và hiệu quả.
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
                Chụp ảnh và gửi đi. Chúng tôi tự động trích xuất tọa độ GPS của bạn để xác định chính xác vị trí tại khu vực TP.HCM.
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
                Các cơ quan chức năng thuộc thành phố sẽ liên tục kiểm tra báo cáo của bạn, chỉ định mức độ ưu tiên và điều động đội ngũ xử lý phù hợp.
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
                Nhận thông báo ngay khi sự cố được khắc phục xong, đi kèm bằng chứng hình ảnh nghiệm thu thực tế từ đội ngũ nhân viên hiện trường.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-100 py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center text-gray-500">
          <p>© {new Date().getFullYear()} Nền tảng CityVoice - Thành phố Hồ Chí Minh.</p>
        </div>
      </footer>
    </div>
  );
}
