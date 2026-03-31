import { type ReactNode } from "react";
import Header from "../components/Header";
import bgImg from "../assets/image1.png";

type AuthLayoutProps = {
  children: ReactNode;
};

export default function AuthLayout({ children }: AuthLayoutProps) {
  return (
    <div className="flex flex-col min-h-screen bg-gray-50/50">
      <Header />

      <main className="flex-1 w-full flex items-center justify-center p-4 sm:p-8 lg:p-10">
        <div className="w-full max-w-5xl flex flex-col lg:flex-row bg-white rounded-3xl overflow-hidden shadow-[0_20px_60px_-15px_rgba(0,0,0,0.1)] border border-gray-100 min-h-[600px]">
          {/* Left Side - Background and Text */}
          <div className="hidden lg:flex w-1/2 relative bg-[#0055d4] items-end pb-16 px-12 xl:px-16">
            <div className="absolute inset-0 z-0">
              <img src={bgImg} alt="City Background" className="w-full h-full object-cover object-center opacity-60 mix-blend-overlay" />
            </div>

            <div className="relative z-20 text-white max-w-xl">
              <h1 className="text-[36px] xl:text-[40px] font-extrabold leading-tight mb-6 tracking-wide drop-shadow-md">
                Tiếng nói của bạn<br />kiến tạo thành phố<br />tương lai.
              </h1>
              <p className="text-lg text-white/95 font-medium mb-10 leading-relaxed font-sans w-11/12 drop-shadow-sm">
                Tham gia cùng hàng ngàn công dân tích cực đang thay đổi diện mạo đô thị mỗi ngày thông qua nền tảng CityVoice.
              </p>
              <div className="flex items-center gap-4">
                <div className="flex -space-x-4">
                  <img className="w-11 h-11 rounded-full border-[3px] border-[#0055d4] shadow-md object-cover" src="https://i.pravatar.cc/100?img=11" alt="Avatar" />
                  <img className="w-11 h-11 rounded-full border-[3px] border-[#0055d4] shadow-md object-cover" src="https://i.pravatar.cc/100?img=12" alt="Avatar" />
                  <img className="w-11 h-11 rounded-full border-[3px] border-[#0055d4] shadow-md object-cover" src="https://i.pravatar.cc/100?img=13" alt="Avatar" />
                </div>
                <span className="text-sm font-semibold text-white/90 drop-shadow-sm">+2.5k người tham gia tuần này</span>
              </div>
            </div>
          </div>

          {/* Right Side - Form Content */}
          <div className="w-full lg:w-1/2 flex items-center justify-center p-8 lg:p-12 bg-white relative">
            <div className="w-full max-w-[400px]">
              {children}
            </div>
          </div>
        </div>
      </main>


    </div>
  );
}
