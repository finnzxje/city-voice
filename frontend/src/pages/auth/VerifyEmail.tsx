import React, { useState } from "react";
import { useNavigate, useLocation, Navigate } from "react-router-dom";
import { AuthAPI } from "../../api/services";
import {
  MailCheck,
  KeyRound,
  ArrowRight,
  AlertCircle,
  RefreshCw,
} from "lucide-react";

export default function VerifyEmail() {
  const navigate = useNavigate();
  const location = useLocation();
  const email = location.state?.email || "";
  const [otp, setOtp] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [msg, setMsg] = useState(
    email ? "Mã xác minh đã được gửi đến email của bạn." : "",
  );

  // If no email in state, they probably shouldn't be here directly
  if (!email) {
    return <Navigate to="/register" />;
  }

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      await AuthAPI.verifyEmail({ email, otp });
      navigate("/login", {
        state: { message: "Xác minh email thành công! Bạn có thể đăng nhập ngay bây giờ." },
      });
    } catch (err: any) {
      setError(
        err.response?.data?.message || "Xác minh thất bại. Mã OTP không đúng.",
      );
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    setLoading(true);
    setError("");
    setMsg("");
    try {
      await AuthAPI.resendVerification({ email });
      setMsg("Một mã xác minh mới đã được gửi đi.");
    } catch (err: any) {
      setError(err.response?.data?.message || "Gửi lại mã thất bại.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-50 via-white to-blue-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full">
        <div className="bg-white/70 backdrop-blur-xl rounded-3xl shadow-2xl overflow-hidden border border-white/50 p-8 sm:p-12">
          <div className="text-center mb-8">
            <div className="mx-auto h-16 w-16 bg-green-100 text-green-600 rounded-full flex items-center justify-center mb-6">
              <MailCheck size={32} />
            </div>
            <h2 className="text-3xl font-extrabold text-gray-900 tracking-tight">
              Xác minh email của bạn
            </h2>
            <p className="mt-2 text-sm text-gray-500">
              Chúng tôi vừa gửi một mã 6 số đến{" "}
              <span className="font-semibold text-gray-900">{email}</span>
            </p>
          </div>

          {error && (
            <div className="mb-6 bg-red-50/80 backdrop-blur-sm border-l-4 border-red-500 p-4 rounded-r-lg flex items-center">
              <AlertCircle className="text-red-500 mr-3 shrink-0" size={20} />
              <p className="text-sm text-red-700">{error}</p>
            </div>
          )}

          {msg && !error && (
            <div className="mb-6 bg-green-50/80 backdrop-blur-sm border-l-4 border-green-500 p-4 rounded-r-lg flex items-center">
              <MailCheck className="text-green-500 mr-3 shrink-0" size={20} />
              <p className="text-sm text-green-700">{msg}</p>
            </div>
          )}

          <form className="space-y-6" onSubmit={handleVerify}>
            <div className="relative group">
              <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <KeyRound className="h-5 w-5 text-gray-400 group-focus-within:text-indigo-500 transition-colors" />
              </div>
              <input
                type="text"
                required
                value={otp}
                onChange={(e) => setOtp(e.target.value)}
                className="block w-full pl-11 pr-4 py-4 border border-gray-200 rounded-xl leading-5 bg-white/50 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 focus:bg-white transition-all duration-200 text-center text-xl font-mono tracking-[0.5em]"
                placeholder="------"
                maxLength={6}
              />
            </div>

            <button
              type="submit"
              disabled={loading || otp.length !== 6}
              className="group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-semibold rounded-xl text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 transition-all duration-200 shadow-lg shadow-indigo-200 disabled:opacity-70 disabled:cursor-not-allowed"
            >
              {loading ? "Đang xác minh..." : "Xác minh Email"}
              {!loading && (
                <ArrowRight className="ml-2 h-4 w-4 group-hover:translate-x-1 transition-transform" />
              )}
            </button>
          </form>

          <div className="mt-8 text-center bg-gray-50/50 p-4 rounded-xl">
            <p className="text-sm text-gray-600">Bạn chưa nhận được mã?</p>
            <button
              onClick={handleResend}
              disabled={loading}
              className="mt-2 inline-flex items-center text-sm font-medium text-indigo-600 hover:text-indigo-500 disabled:opacity-70"
            >
              <RefreshCw
                size={16}
                className={`mr-2 ${loading ? "animate-spin" : ""}`}
              />
              Gửi lại mã xác minh
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
