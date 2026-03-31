import React, { useState } from "react";
import { useNavigate, Link, useLocation } from "react-router-dom";
import { AuthAPI } from "../../api/services";
import { useAuth } from "../../contexts/AuthContext";
import toast from "react-hot-toast";
import { Mail, Lock, ShieldCheck, KeyRound, AlertCircle, Eye, EyeOff } from "lucide-react";
import AuthLayout from "../../layouts/AuthLayout";

type LoginMode = "citizen_pwd" | "citizen_otp" | "staff";

export default function Login() {
  const navigate = useNavigate();
  const location = useLocation();
  const { login } = useAuth();

  const [mode, setMode] = useState<LoginMode>("citizen_pwd");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  const [otpSent, setOtpSent] = useState(false);
  const [otp, setOtp] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [msg, setMsg] = useState(location.state?.message || "");

  const handleCitizenPassword = async () => {
    const res = await AuthAPI.loginCitizenPassword({ email, password });
    await login(res.data.data);
    toast.success("Đăng nhập thành công!");
    navigate("/");
  };

  const handleStaffLogin = async () => {
    const res = await AuthAPI.loginStaff({ email, password });
    await login(res.data.data);
    toast.success("Đăng nhập cán bộ thành công!");
    navigate("/");
  };

  const handleRequestOTP = async () => {
    await AuthAPI.requestOtpLogin({ email });
    setOtpSent(true);
    setMsg("Mã OTP đã được gửi đến email của bạn.");
    toast.success("Mã OTP đã được gửi!");
  };

  const handleVerifyOTP = async () => {
    const res = await AuthAPI.verifyOtpLogin({ email, otp });
    await login({ accessToken: res.data.data.accessToken, refreshToken: res.data.data.refreshToken }, res.data.data.user);
    toast.success("Đăng nhập thành công!");
    navigate("/");
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setMsg("");

    try {
      if (mode === "citizen_pwd") {
        await handleCitizenPassword();
      } else if (mode === "staff") {
        await handleStaffLogin();
      } else if (mode === "citizen_otp") {
        if (!otpSent) {
          await handleRequestOTP();
        } else {
          await handleVerifyOTP();
        }
      }
    } catch (err: any) {
      if (err.response?.status === 403) {
        toast.error("Tài khoản chưa kích hoạt, vui lòng kiểm tra email.");

      } else {
        const errorMessage = err.response?.data?.message || "Đăng nhập thất bại.";
        setError(errorMessage);
        toast.error(errorMessage);
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout>
      <div className="bg-white rounded-xl h-full overflow-hidden flex flex-col min-h-[580px]">
        {/* Tabs */}
        <div className="flex border-b border-gray-100 shrink-0">
          <button
            onClick={() => {
              setMode("citizen_pwd");
              setOtpSent(false);
              setError("");
              setMsg("");
            }}
            className={`flex-1 py-4 text-[15px] font-semibold text-center transition-colors ${mode.startsWith("citizen")
              ? "text-[#0055d4] border-b-2 border-[#0055d4] bg-white relative top-px"
              : "text-gray-500 hover:text-gray-700 bg-gray-50"
              }`}
          >
            Cư dân
          </button>
          <button
            onClick={() => {
              setMode("staff");
              setError("");
              setMsg("");
            }}
            className={`flex-1 py-4 text-[15px] font-semibold text-center transition-colors ${mode === "staff"
              ? "text-[#0055d4] border-b-2 border-[#0055d4] bg-white relative top-px"
              : "text-gray-500 hover:text-gray-700 bg-gray-50"
              }`}
          >
            Cán bộ
          </button>
        </div>

        <div className="p-8 flex-1 flex flex-col">
          <div className="mb-6 shrink-0">
            <h2 className="text-[28px] font-bold text-gray-900 tracking-tight mb-2">
              {mode === "staff" ? "Cổng thông tin Nội bộ" : "Chào mừng trở lại"}
            </h2>
            <p className="text-[15px] text-gray-500 font-medium">
              {mode === "staff" ? "Dành cho Nhân viên & Ban quản lý" : "Vui lòng đăng nhập để tiếp tục đóng góp cho cộng đồng."}
            </p>
          </div>

          {error && (
            <div className="mb-6 bg-red-50/80 border-l-4 border-red-500 p-3 rounded-r-md flex items-center">
              <AlertCircle className="text-red-500 mr-2 shrink-0" size={18} />
              <p className="text-sm text-red-700 font-medium">{error}</p>
            </div>
          )}

          {msg && (
            <div className="mb-6 bg-green-50/80 border-l-4 border-green-500 p-3 rounded-r-md flex items-center">
              <ShieldCheck className="text-green-500 mr-2 shrink-0" size={18} />
              <p className="text-sm text-green-700 font-medium">{msg}</p>
            </div>
          )}

          <form className="space-y-4" onSubmit={handleSubmit}>
            <div>
              <label className="block text-xs font-bold text-gray-500 uppercase tracking-widest mb-1.5 ml-1">
                {mode === "staff" ? "Địa chỉ Email" : "Email"}
              </label>
              <div className="relative group">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                  <Mail className="h-[18px] w-[18px] text-gray-400 group-focus-within:text-[#0055d4] transition-colors" />
                </div>
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  disabled={otpSent}
                  className="block w-full pl-10 pr-4 py-3 border-none bg-gray-100/80 rounded-[10px] text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#0055d4] transition-all text-sm font-medium disabled:opacity-60"
                  placeholder={mode === "staff" ? "name@cityvoice.vn" : "example@city.gov.vn"}
                />
              </div>
            </div>

            {/* Password field */}
            {(mode === "staff" || mode === "citizen_pwd") && (
              <div>
                <div className="flex justify-between items-center mb-1.5 ml-1">
                  <label className="block text-xs font-bold text-gray-500 uppercase tracking-widest">
                    Mật khẩu
                  </label>
                  {/* <Link to="#" className="text-xs font-bold text-[#0055d4] hover:underline">
                    Quên mật khẩu?
                  </Link> */}
                </div>
                <div className="relative group">
                  <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                    <Lock className="h-[18px] w-[18px] text-gray-400 group-focus-within:text-[#0055d4] transition-colors" />
                  </div>
                  <input
                    type={showPassword ? "text" : "password"}
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="block w-full pl-10 pr-10 py-3 border-none bg-gray-100/80 rounded-[10px] text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#0055d4] transition-all text-sm font-medium tracking-wide"
                    placeholder="••••••••"
                  />
                  <div
                    className="absolute inset-y-0 right-0 pr-3.5 flex items-center cursor-pointer text-gray-400 hover:text-gray-600 transition-colors"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </div>
                </div>
              </div>
            )}

            {/* OTP field */}
            {mode === "citizen_otp" && (
              <>
                {!otpSent ? null : (
                  <div className="mt-4 animate-fade-in-down">
                    <label className="block text-xs font-bold text-gray-500 uppercase tracking-widest mb-1.5 ml-1">
                      Mã OTP
                    </label>
                    <div className="relative group">
                      <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                        <KeyRound className="h-[18px] w-[18px] text-gray-400 group-focus-within:text-[#0055d4] transition-colors" />
                      </div>
                      <input
                        type="text"
                        required
                        value={otp}
                        onChange={(e) => setOtp(e.target.value)}
                        className="block w-full pl-10 pr-4 py-3 border-none bg-gray-100/80 rounded-[10px] text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-[#0055d4] transition-all text-sm font-medium tracking-widest"
                        placeholder="Nhập mã 6 số"
                        maxLength={6}
                      />
                    </div>
                  </div>
                )}
              </>
            )}

            <div className="flex items-center pt-1 pb-2">
              <input
                id="remember_me"
                type="checkbox"
                className="h-4 w-4 text-[#0055d4] focus:ring-[#0055d4] border-gray-300 rounded cursor-pointer"
              />
              <label htmlFor="remember_me" className="ml-2 block text-[13px] font-medium text-gray-700 cursor-pointer">
                Ghi nhớ đăng nhập
              </label>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full flex justify-center py-3.5 px-4 rounded-[10px] text-sm font-bold text-white bg-[#0055d4] hover:bg-[#004bbd] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#0055d4] transition-all shadow-[0_4px_12px_rgba(0,85,212,0.25)] disabled:opacity-70 disabled:cursor-not-allowed items-center"
            >
              {loading
                ? "Đang xử lý..."
                : (mode === "citizen_otp" && !otpSent)
                  ? "Gửi mã OTP"
                  : (mode === "staff" ? "Đăng nhập Hệ thống \u2192" : "Đăng nhập ngay")}
            </button>

            {mode.startsWith("citizen") && mode === "citizen_pwd" && (
              <>
                <div className="relative py-4">
                  <div className="absolute inset-0 flex items-center">
                    <div className="w-full border-t border-gray-100"></div>
                  </div>
                  <div className="relative flex justify-center">
                    <span className="px-3 bg-white text-[11px] font-bold text-gray-400 uppercase tracking-widest">Hoặc</span>
                  </div>
                </div>

                <button
                  type="button"
                  onClick={() => {
                    setMode("citizen_otp");
                    setOtpSent(false);
                    setError("");
                  }}
                  className="w-full flex justify-center py-3.5 px-4 rounded-[10px] text-sm font-bold text-gray-700 bg-gray-100 hover:bg-gray-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-300 transition-all items-center gap-2"
                >
                  <KeyRound size={16} className="text-gray-600" />
                  Đăng nhập không mật khẩu (OTP)
                </button>
              </>
            )}

            {mode === "citizen_otp" && (
              <div className="text-center mt-3">
                <button type="button" onClick={() => setMode("citizen_pwd")} className="text-[13px] font-semibold text-gray-600 hover:text-gray-900 transition-colors">
                  Quay lại đăng nhập mật khẩu
                </button>
              </div>
            )}
          </form>

          <div className="mt-auto pt-6 px-1">
            {mode.startsWith("citizen") ? (
              <div className="text-center text-[13px] text-gray-600 font-medium">
                Bạn chưa có tài khoản?{" "}
                <Link to="/register" className="font-bold text-[#0055d4] hover:underline">
                  Tạo tài khoản mới
                </Link>
              </div>
            ) : (
              <div className="text-center">
                <button onClick={() => setMode("citizen_pwd")} className="text-[14px] font-bold text-gray-600 hover:text-gray-900 transition-colors flex items-center justify-center gap-2 mx-auto">
                  &larr; Quay lại Trang chủ
                </button>
              </div>
            )}
          </div>
        </div>
      </div>


    </AuthLayout>
  );
}
