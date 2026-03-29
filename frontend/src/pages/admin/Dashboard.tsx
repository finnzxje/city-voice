import { Link } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import {
  LogOut,
  Building2,
  LayoutDashboard,
  Users,
  FolderTree,
} from "lucide-react";

import { Outlet, NavLink } from "react-router-dom";
export default function AdminDashboard() {
  const { user, logout } = useAuth();
  return (
    <div className="min-h-screen bg-surface text-on-surface flex font-body">
      {/* SideNavBar */}
      <aside className="hidden md:flex flex-col h-screen p-4 space-y-2 w-64 fixed left-0 top-0 bg-[#ffffff] border-r border-surface-container z-50">
        <div className="px-4 py-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-linear-to-br from-primary to-primary-container rounded-xl flex items-center justify-center text-white shadow-lg">
              <Building2 size={20} />
            </div>
            <div>
              <span className="font-headline font-black text-xl tracking-tight text-primary leading-tight">CityVoice</span>
              <p className="text-[10px] uppercase tracking-widest text-on-surface-variant font-bold">Admin Portal</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 space-y-1 py-5">
          <Link to="/" className="flex items-center px-4 py-3 text-on-surface-variant hover:text-on-surface hover:bg-surface-container-low transition-all duration-200 cursor-pointer text-sm font-medium rounded-lg">
            <LayoutDashboard className="mr-3 h-5 w-5" />
            Home
          </Link>

          <NavLink
            to="/admin/users"
            className={({ isActive }) =>
              `w-full flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-all duration-200 cursor-pointer hover:translate-y-0 active:scale-100 ${isActive
                ? "bg-surface-container-lowest text-primary shadow-sm"
                : "text-on-surface-variant hover:text-on-surface hover:bg-surface-container-low"
              }`
            }
          >
            <Users className="mr-3 h-5 w-5" />
            User Access
          </NavLink>

          <NavLink
            to="/admin/categories"
            className={({ isActive }) =>
              `w-full flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-all duration-200 cursor-pointer hover:translate-y-0 active:scale-100 ${isActive
                ? "bg-surface-container-lowest text-primary shadow-sm"
                : "text-on-surface-variant hover:text-on-surface hover:bg-surface-container-low"
              }`
            }
          >
            <FolderTree className="mr-3 h-5 w-5" />
            Categories
          </NavLink>
        </nav>

        <div className="pt-4 mt-auto border-t border-surface-container space-y-1">
          <button onClick={logout} className="w-full flex items-center px-4 py-3 text-error hover:bg-error-container/20 transition-all duration-200 cursor-pointer text-sm font-bold rounded-lg group">
            <LogOut className="mr-3 h-5 w-5 group-hover:-translate-x-1 transition-transform" />
            Đăng xuất
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 md:ml-64 min-w-0 bg-surface min-h-screen pb-12">
        {/* TopAppBar */}
        <header className="sticky top-0 w-full flex items-center justify-end px-8 h-16 bg-surface-container-lowest/70 backdrop-blur-xl z-40 border-b border-surface-container/50">

          <div className="flex justify-end gap-3 ml-2 pl-4">
            <div className="text-right hidden sm:block">
              <p className="text-xs font-bold text-on-surface leading-none">{user?.fullName || "Chưa cập nhật"}</p>
              <p className="text-[10px] text-on-surface-variant uppercase font-bold tracking-wider mt-0.5">Admin</p>
            </div>
            <div className="h-9 w-9 bg-error-container text-on-error-container rounded-full flex items-center justify-center font-bold text-xs uppercase border-2 border-surface-container-lowest shadow-sm">
              {user?.fullName?.substring(0, 2) || user?.email.substring(0, 2)}
            </div>
          </div>

        </header>

        {/* Dynamic Content */}
        <div className="p-8 max-w-7xl mx-auto w-full">
          <Outlet />
        </div>
      </main>


    </div>
  );
}
