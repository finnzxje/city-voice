import React, { useState } from "react";
import { useNavigate, Link, useLocation } from "react-router-dom";
import { AuthAPI } from "../../api/services";
import { useAuth } from "../../contexts/AuthContext";
import {
  Mail,
  Lock,
  ShieldCheck,
  KeyRound,
  ArrowRight,
  Activity,
  AlertCircle,
} from "lucide-react";

type LoginMode = "citizen_pwd" | "citizen_otp" | "staff";

export default function Login() {
  const navigate = useNavigate();
  const location = useLocation();
  const { login } = useAuth();

  const [mode, setMode] = useState<LoginMode>("citizen_pwd");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [otpSent, setOtpSent] = useState(false);
  const [otp, setOtp] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [msg, setMsg] = useState(location.state?.message || "");

  const handleCitizenPassword = async () => {
    const res = await AuthAPI.loginCitizenPassword({ email, password });
    await login(res.data);
    navigate("/");
  };

  const handleStaffLogin = async () => {
    const res = await AuthAPI.loginStaff({ email, password });
    await login(res.data);
    navigate("/");
  };

  const handleRequestOTP = async () => {
    await AuthAPI.requestOtpLogin({ email });
    setOtpSent(true);
    setMsg("Mã OTP đã được gửi đến email của bạn.");
  };

  const handleVerifyOTP = async () => {
    const res = await AuthAPI.verifyOtpLogin({ email, otp });
    await login(res.data);
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
      if (
        err.response?.status === 403 &&
        err.response?.data?.message?.includes("verify")
      ) {
        // Account inactive, redirect to verify email
        navigate("/verify-email", { state: { email } });
      } else {
        setError(err.response?.data?.title || "Đăng nhập thất bại.");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-50 via-white to-blue-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full">
        <div className="bg-white/70 backdrop-blur-xl rounded-3xl shadow-2xl overflow-hidden border border-white/50">
          {/* Tabs */}
          <div className="flex border-b border-gray-100">
            <button
              onClick={() => {
                setMode("citizen_pwd");
                setOtpSent(false);
                setError("");
              }}
              className={`flex-1 py-4 text-sm font-medium text-center transition-colors ${
                mode.startsWith("citizen")
                  ? "text-indigo-600 border-b-2 border-indigo-600 bg-white"
                  : "text-gray-500 hover:text-gray-700 bg-gray-50/50"
              }`}
            >
              Cư dân
            </button>
            <button
              onClick={() => {
                setMode("staff");
                setError("");
              }}
              className={`flex-1 py-4 text-sm font-medium text-center transition-colors ${
                mode === "staff"
                  ? "text-indigo-600 border-b-2 border-indigo-600 bg-white"
                  : "text-gray-500 hover:text-gray-700 bg-gray-50/50"
              }`}
            >
              Cán bộ
            </button>
          </div>

          <div className="p-8 sm:p-12">
            <div className="text-center mb-8">
              <div className="mx-auto h-16 w-16 bg-indigo-600 text-white rounded-2xl flex items-center justify-center transform rotate-3 shadow-lg mb-6">
                <Activity size={32} className="transform -rotate-3" />
              </div>
              <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">
                Chào mừng trở lại
              </h2>
            </div>

            {error && (
              <div className="mb-6 bg-red-50/80 backdrop-blur-sm border-l-4 border-red-500 p-4 rounded-r-lg flex items-center">
                <AlertCircle className="text-red-500 mr-3 shrink-0" size={20} />
                <p className="text-sm text-red-700">{error}</p>
              </div>
            )}

            {msg && (
              <div className="mb-6 bg-green-50/80 backdrop-blur-sm border-l-4 border-green-500 p-4 rounded-r-lg flex items-center">
                <ShieldCheck
                  className="text-green-500 mr-3 shrink-0"
                  size={20}
                />
                <p className="text-sm text-green-700">{msg}</p>
              </div>
            )}

            <form className="space-y-6" onSubmit={handleSubmit}>
              <div className="space-y-4">
                <div className="relative group">
                  <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                    <Mail className="h-5 w-5 text-gray-400 group-focus-within:text-indigo-500 transition-colors" />
                  </div>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    disabled={otpSent}
                    className="block w-full pl-11 pr-4 py-3 border border-gray-200 rounded-xl leading-5 bg-white/50 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 focus:bg-white transition-all duration-200 sm:text-sm disabled:opacity-50"
                    placeholder="Địa chỉ Email"
                  />
                </div>

                {/* Password field - show if Staff or Citizen Pwd */}
                {(mode === "staff" || mode === "citizen_pwd") && (
                  <div className="relative group">
                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                      <Lock className="h-5 w-5 text-gray-400 group-focus-within:text-indigo-500 transition-colors" />
                    </div>
                    <input
                      type="password"
                      required
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="block w-full pl-11 pr-4 py-3 border border-gray-200 rounded-xl leading-5 bg-white/50 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 focus:bg-white transition-all duration-200 sm:text-sm"
                      placeholder="Mật khẩu"
                    />
                  </div>
                )}

                {/* OTP field - show if Citizen OTP and requested */}
                {mode === "citizen_otp" && otpSent && (
                  <div className="relative group mt-4 transform origin-top animate-fade-in-down">
                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                      <KeyRound className="h-5 w-5 text-gray-400 group-focus-within:text-indigo-500 transition-colors" />
                    </div>
                    <input
                      type="text"
                      required
                      value={otp}
                      onChange={(e) => setOtp(e.target.value)}
                      className="block w-full pl-11 pr-4 py-3 border border-gray-200 rounded-xl leading-5 bg-white/50 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 focus:bg-white transition-all duration-200 sm:text-sm tracking-widest"
                      placeholder="Nhập mã OTP 6 số"
                      maxLength={6}
                    />
                  </div>
                )}
              </div>

              {/* Toggle Citizen Pwd / OTP */}
              {mode.startsWith("citizen") && (
                <div className="flex items-center justify-end">
                  <button
                    type="button"
                    onClick={() => {
                      setMode(
                        mode === "citizen_pwd" ? "citizen_otp" : "citizen_pwd",
                      );
                      setOtpSent(false);
                      setError("");
                      setMsg("");
                    }}
                    className="text-sm font-medium text-indigo-600 hover:text-indigo-500 transition-colors"
                  >
                    {mode === "citizen_pwd"
                      ? "Đăng nhập nhanh bằng OTP"
                      : "Đăng nhập bằng mật khẩu"}
                  </button>
                </div>
              )}

              <div>
                <button
                  type="submit"
                  disabled={loading}
                  className="group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-semibold rounded-xl text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all duration-200 shadow-lg shadow-indigo-200 disabled:opacity-70 disabled:cursor-not-allowed"
                >
                  {loading
                    ? "Đang xử lý..."
                    : mode === "citizen_otp" && !otpSent
                      ? "Gửi mã OTP"
                      : "Đăng nhập"}
                  {!loading && (
                    <ArrowRight className="ml-2 h-4 w-4 group-hover:translate-x-1 transition-transform" />
                  )}
                </button>
              </div>
            </form>
          </div>

          {mode.startsWith("citizen") && (
            <div className="px-8 py-6 bg-gray-50/50 backdrop-blur-md border-t border-gray-100 text-center">
              <p className="text-sm text-gray-600">
                Chưa có tài khoản?{" "}
                <Link
                  to="/register"
                  className="font-semibold text-indigo-600 hover:text-indigo-500 transition-colors"
                >
                  Đăng ký ngay
                </Link>
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
