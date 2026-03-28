import { Building2 } from "lucide-react";
import { Link } from "react-router-dom";

const Header = () => (
    <header className="relative top-0 left-0 right-0 z-50 py-4">
        <div className="max-w mx-auto px-6">
            <nav className="glass-nav flex items-center justify-between px-8 py-4 rounded-[2.5rem] border border-white/40 shadow-xl bg-white/40 backdrop-blur-xl">
                <Link to="/" className="flex items-center gap-3 group cursor-pointer">
                    <div className="w-12 h-12 bg-primary rounded-2xl flex items-center justify-center text-white shadow-lg group-hover:rotate-12 transition-transform duration-500">
                        <Building2 size={24} />
                    </div>
                    <span className="font-headline font-extrabold text-2xl tracking-tight text-on-surface">CityVoice</span>
                </Link>


                <div className="flex items-center gap-4">
                    <Link to="/login" className="px-6 py-2.5 text-sm font-bold text-on-surface-variant hover:text-primary transition-colors">
                        Đăng nhập
                    </Link>
                    <Link to="/register" className="px-8 py-3 bg-primary text-white rounded-full text-sm font-bold shadow-lg shadow-primary/20 hover:scale-105 active:scale-95 transition-all">
                        Đăng ký
                    </Link>
                </div>
            </nav>
        </div>
    </header>
);
export default Header;