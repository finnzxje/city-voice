import { Building2 } from "lucide-react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";

const Header = () => {
    const { user, logout } = useAuth();
    const navigate = useNavigate();

    return (
        <header className="fixed top-0 left-0 right-0 z-50 py-3 px-6 bg-slate-50/70 backdrop-blur-md shadow-sm">
            <div className="max-w-7xl mx-auto flex items-center justify-between">
                <Link to="/" className="flex items-center gap-3 group cursor-pointer">
                    <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center text-white shadow-lg group-hover:rotate-12 transition-transform duration-500">
                        <Building2 size={20} />
                    </div>
                    <span className="font-headline font-extrabold text-xl tracking-tight text-primary">CityVoice</span>
                </Link>

                <nav className="hidden lg:flex space-x-6 font-headline font-medium">
                    {user?.role === "citizen" && (
                        <>
                            <Link to="/citizen/dashboard" className="text-slate-600 hover:text-primary transition-colors">Dashboard</Link>
                            <Link to="/reports/new" className="text-slate-600 hover:text-primary transition-colors">Báo cáo</Link>
                        </>
                    )}
                    {user?.role === "staff" && (
                        <Link to="/staff/dashboard" className="text-slate-600 hover:text-primary transition-colors">Dashboard</Link>
                    )}
                    {(user?.role === "manager" || user?.role === "admin") && (
                        <Link to="/manager/dashboard" className="text-slate-600 hover:text-primary transition-colors">Dashboard</Link>
                    )}
                </nav>

                <div className="flex items-center gap-4">
                    {user ? (
                        <>
                            <span className="text-sm font-medium hidden sm:block text-slate-700 font-body">
                                {user.fullName || user.email}
                            </span>
                            <button
                                onClick={() => {
                                    logout();
                                    navigate("/");
                                }}
                                className="flex items-center gap-2 px-5 py-2.5 border border-slate-200 bg-white text-slate-600 text-sm font-semibold rounded-xl shadow-sm hover:border-red-200 hover:text-red-600 hover:bg-red-50 active:scale-95 transition-all duration-200 font-body"
                            >
                                Đăng xuất
                                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" y1="12" x2="9" y2="12" /></svg>

                            </button>
                        </>
                    ) : (
                        <>
                            <Link to="/login" className="px-5 py-2 text-sm font-bold text-on-surface-variant hover:text-primary transition-colors">
                                Đăng nhập
                            </Link>
                            <Link to="/register" className="px-6 py-2 bg-primary text-white rounded-lg text-sm font-bold shadow-md hover:scale-105 active:scale-95 transition-transform">
                                Đăng ký
                            </Link>
                        </>
                    )}
                </div>
            </div>
        </header>
    );
};

export default Header;