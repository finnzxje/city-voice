import React, { useState, useRef, useEffect } from "react";
import { useNavigate, useLocation, Navigate, Link } from "react-router-dom";
import { AuthAPI } from "../../api/services";
import { AlertCircle, ArrowLeft } from "lucide-react";
import AuthLayout from "../../layouts/AuthLayout";

export default function VerifyEmail() {
  const navigate = useNavigate();
  const location = useLocation();
  const email = location.state?.email || "";

  const [otp, setOtp] = useState(["", "", "", "", "", ""]);
  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [countdown, setCountdown] = useState(60);

  // If no email in state, they probably shouldn't be here directly
  if (!email) {
    return <Navigate to="/register" />;
  }

  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    if (countdown > 0) {
      timer = setTimeout(() => setCountdown(countdown - 1), 1000);
    }
    return () => clearTimeout(timer);
  }, [countdown]);

  const handleChange = (index: number, value: string) => {
    if (isNaN(Number(value))) return;

    const newOtp = [...otp];
    // take only the last character in case they paste multiple
    newOtp[index] = value.substring(value.length - 1);
    setOtp(newOtp);

    // move backward after delete
    if (value === "" && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
    // Move forward 
    if (value !== "" && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Backspace" && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
    if (e.key === "Enter" && otp.join("").length === 6) {
      handleVerify(e as any);
    }
  };

  const handlePaste = (e: React.ClipboardEvent<HTMLInputElement>) => {
    e.preventDefault();
    const pastedData = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, 6);
    if (pastedData) {
      const newOtp = [...otp];
      for (let i = 0; i < pastedData.length; i++) {
        newOtp[i] = pastedData[i];
      }
      setOtp(newOtp);
      // focus the last filled input or the next empty one
      const focusIndex = Math.min(pastedData.length, 5);
      inputRefs.current[focusIndex]?.focus();
    }
  };

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    const otpValue = otp.join("");
    if (otpValue.length !== 6) return;

    setLoading(true);
    setError("");

    try {
      await AuthAPI.verifyEmail({ email, otp: otpValue });
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
    if (countdown > 0) return;

    setLoading(true);
    setError("");
    try {
      await AuthAPI.resendVerification({ email });
      setCountdown(60);
    } catch (err: any) {
      setError(err.response?.data?.message || "Gửi lại mã thất bại.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout>
      <div className="bg-white rounded-[20px] shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-gray-100 p-10 relative">
        <button
          onClick={() => navigate(-1)}
          className="flex items-center text-[13px] font-bold text-gray-500 hover:text-gray-900 transition-colors mb-8"
        >
          <ArrowLeft size={16} className="mr-2" /> Trở lại
        </button>

        <div className="mb-8">
          <h2 className="text-[28px] font-extrabold text-gray-900 tracking-tight mb-3">
            Xác thực tài khoản
          </h2>
          <p className="text-[15px] text-gray-500 font-medium">
            Vui lòng nhập mã OTP đã được gửi đến email của bạn
          </p>
        </div>

        {error && (
          <div className="mb-6 bg-red-50/80 border-l-4 border-red-500 p-3 flex items-center shadow-sm">
            <AlertCircle className="text-red-500 mr-2 shrink-0" size={18} />
            <p className="text-[13px] text-red-700 font-bold">{error}</p>
          </div>
        )}

        <form className="space-y-8" onSubmit={handleVerify}>
          <div className="grid grid-cols-6 gap-3 sm:gap-4">
            {otp.map((data, index) => (
              <input
                key={index}
                type="text"
                ref={(el) => { inputRefs.current[index] = el; }}
                value={data}
                onChange={(e) => handleChange(index, e.target.value)}
                onKeyDown={(e) => handleKeyDown(index, e)}
                onPaste={handlePaste}
                autoComplete="off"
                className={`w-full aspect-square text-center text-2xl font-semibold rounded-[12px] transition-all bg-gray-200/50 border-2 outline-none
                  ${data
                    ? "border-[#0055d4] bg-white text-[#0055d4] shadow-[0_0_12px_rgba(0,85,212,0.15)]"
                    : "border-transparent text-gray-900 focus:bg-white focus:border-[#0055d4]/40"
                  }`}
                maxLength={1}
              />
            ))}
          </div>

          <button
            type="submit"
            disabled={loading || otp.join("").length !== 6}
            className="w-full flex justify-center py-4 rounded-[10px] text-[15px] font-bold text-white bg-[#0055d4] hover:bg-[#004bbd] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#0055d4] transition-all shadow-[0_4px_12px_rgba(0,85,212,0.25)] disabled:opacity-70 disabled:cursor-not-allowed items-center"
          >
            {loading ? "Đang xác minh..." : "Xác nhận mã"}
          </button>
        </form>

        <div className="mt-8 text-center text-[13px] text-gray-500 font-medium tracking-wide">
          Chưa nhận được mã?{" "}
          <button
            onClick={handleResend}
            disabled={countdown > 0 || loading}
            className={`font-bold transition-colors ${countdown > 0 ? "text-gray-400 cursor-not-allowed" : "text-[#0055d4] hover:underline"
              }`}
          >
            Gửi lại mã {countdown > 0 && `(${countdown}s)`}
          </button>
        </div>
      </div>

      <div className="mt-8 flex justify-center gap-6 text-[12px] font-bold text-gray-400">
        <Link to="#" className="hover:text-gray-600 transition-colors">Trợ giúp</Link>
        <span>•</span>
        <Link to="#" className="hover:text-gray-600 transition-colors">Điều khoản bảo mật</Link>
      </div>
    </AuthLayout>
  );
}
