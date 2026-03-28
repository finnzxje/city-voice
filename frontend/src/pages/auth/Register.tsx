import React, { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { AuthAPI } from "../../api/services";
import toast from "react-hot-toast";
import { AlertCircle, User, Mail, Lock, Phone } from "lucide-react";
import AuthLayout from "../../layouts/AuthLayout";

export default function Register() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    fullName: "",
    email: "",
    password: "",
    confirmPassword: "",
    phoneNumber: "",
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [agreed, setAgreed] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    if (formData.password !== formData.confirmPassword) {
      setError("Mật khẩu xác nhận không khớp.");
      setLoading(false);
      return;
    }

    if (!agreed) {
      setError("Vui lòng đồng ý với Điều khoản dịch vụ và Chính sách bảo mật.");
      setLoading(false);
      return;
    }

    try {
      await AuthAPI.registerCitizen(formData);
      toast.success("Đăng ký thành công! Vui lòng kiểm tra email.");
      navigate("/verify-email", { state: { email: formData.email } });
    } catch (err: any) {
      const errorMessage =
        err.response?.data?.message || "Đăng ký thất bại. Vui lòng thử lại.";
      setError(errorMessage);
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout>
      <div className="bg-white/0 border-transparent overflow-hidden px-2 pt-4">
        <div className="mb-8">
          <h2 className="text-[28px] font-extrabold text-gray-900 tracking-tight mb-2">
            Tạo tài khoản mới
          </h2>
          <p className="text-[15px] text-gray-600 font-medium tracking-tight">
            Bắt đầu hành trình đóng góp cho cộng đồng ngay hôm nay.
          </p>
        </div>

        {error && (
          <div className="mb-6 bg-red-50/80 border-l-4 border-red-500 p-3 rounded-r-md flex items-center shadow-sm">
            <AlertCircle className="text-red-500 mr-2 shrink-0" size={18} />
            <p className="text-[13px] text-red-700 font-bold">{error}</p>
          </div>
        )}

        <form className="space-y-5" onSubmit={handleSubmit}>
          <div>
            <label className="block text-[13px] font-bold text-gray-600 mb-1.5 ml-1">
              Full Name
            </label>
            <input
              name="fullName"
              type="text"
              required
              value={formData.fullName}
              onChange={(e) =>
                setFormData({ ...formData, fullName: e.target.value })
              }
              className="block w-full px-4 py-3 border-none bg-gray-200/50 rounded-[10px] text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#0055d4] transition-all text-sm font-medium"
              placeholder="Nguyễn Văn A"
            />
          </div>

          {/* Since we need phoneNumber for the backend to succeed based on initial code, let's include it nicely or make it half width with maybe something else, or full width */}
          <div>
            <label className="block text-[13px] font-bold text-gray-600 mb-1.5 ml-1">
              Phone Number
            </label>
            <input
              name="phoneNumber"
              type="tel"
              required
              value={formData.phoneNumber}
              onChange={(e) =>
                setFormData({ ...formData, phoneNumber: e.target.value })
              }
              className="block w-full px-4 py-3 border-none bg-gray-200/50 rounded-[10px] text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#0055d4] transition-all text-sm font-medium"
              placeholder="0912 345 678"
            />
          </div>

          <div>
            <label className="block text-[13px] font-bold text-gray-600 mb-1.5 ml-1">
              Email
            </label>
            <input
              name="email"
              type="email"
              required
              value={formData.email}
              onChange={(e) =>
                setFormData({ ...formData, email: e.target.value })
              }
              className="block w-full px-4 py-3 border-none bg-gray-200/50 rounded-[10px] text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#0055d4] transition-all text-sm font-medium"
              placeholder="example@cityvoice.vn"
            />
          </div>

          <div className="flex gap-4">
            <div className="w-1/2">
              <label className="block text-[13px] font-bold text-gray-600 mb-1.5 ml-1">
                Password
              </label>
              <input
                name="password"
                type="password"
                required
                value={formData.password}
                onChange={(e) =>
                  setFormData({ ...formData, password: e.target.value })
                }
                className="block w-full px-4 py-3 border-none bg-gray-200/50 rounded-[10px] text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#0055d4] transition-all text-sm font-medium"
                placeholder="••••••••"
              />
            </div>
            
            <div className="w-1/2">
              <label className="block text-[13px] font-bold text-gray-600 mb-1.5 ml-1">
                Confirm Password
              </label>
              <input
                name="confirmPassword"
                type="password"
                required
                value={formData.confirmPassword}
                onChange={(e) =>
                  setFormData({ ...formData, confirmPassword: e.target.value })
                }
                className="block w-full px-4 py-3 border-none bg-gray-200/50 rounded-[10px] text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#0055d4] transition-all text-sm font-medium"
                placeholder="••••••••"
              />
            </div>
          </div>

          <div className="flex items-start pt-3">
            <div className="flex items-center h-5">
               <input
                 id="agreed"
                 type="checkbox"
                 checked={agreed}
                 onChange={(e) => setAgreed(e.target.checked)}
                 className="h-4 w-4 text-[#0055d4] focus:ring-[#0055d4] border-gray-300 rounded cursor-pointer"
               />
            </div>
            <div className="ml-2.5 text-[12px] font-medium text-gray-500">
               <label htmlFor="agreed" className="cursor-pointer">
                 Tôi đồng ý với{" "}
                 <Link to="#" className="font-bold text-[#0055d4] hover:underline">
                   Điều khoản dịch vụ
                 </Link>{" "}
                 và{" "}
                 <Link to="#" className="font-bold text-[#0055d4] hover:underline">
                   Chính sách bảo mật
                 </Link>{" "}
                 của CityVoice.
               </label>
            </div>
          </div>

          <div className="pt-2">
            <button
              type="submit"
              disabled={loading}
              className="w-full flex justify-center py-3.5 px-4 rounded-[10px] text-[15px] font-bold text-white bg-[#0055d4] hover:bg-[#004bbd] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#0055d4] transition-all shadow-[0_4px_12px_rgba(0,85,212,0.25)] disabled:opacity-70 disabled:cursor-not-allowed items-center"
            >
              {loading ? "Đang tạo tài khoản..." : "Đăng ký ngay"}
            </button>
          </div>
        </form>

        <div className="mt-8 text-center text-[13px] text-gray-500 font-medium">
          Đã có tài khoản?{" "}
          <Link
            to="/login"
            className="font-bold text-[#0055d4] hover:underline"
          >
            Đăng nhập
          </Link>
        </div>
      </div>
    </AuthLayout>
  );
}
