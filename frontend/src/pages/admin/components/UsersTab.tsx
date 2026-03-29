import { useState } from "react";
import type { UserInfo } from "../../../api/services";
import { Users, TrendingUp, Bolt, Search, Filter, ChevronDown, Check } from "lucide-react";

interface UsersTabProps {
  users: UserInfo[];
  systemRoles: string[];
  loading: boolean;
  onRoleChange: (userId: string, newRole: string) => void;
}

export default function UsersTab({ users, systemRoles, loading, onRoleChange }: UsersTabProps) {
  const [searchTerm, setSearchTerm] = useState("");
  const [roleFilter, setRoleFilter] = useState("all");
  const [openDropdownId, setOpenDropdownId] = useState<string | null>(null);

  const totalCitizens = users.filter((u) => u.role === "citizen").length;
  const activeSessions = users.filter((u) => u.isActive).length;

  const filteredUsers = users.filter((u) => {
    const matchesSearch =
      u.fullName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      u.email.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesRole = roleFilter === "all" || u.role.toLowerCase() === roleFilter;
    return matchesSearch && matchesRole;
  });

  return (
    <div className="space-y-8 animate-fade-in-up">
      {/* Bento Dashboard Header */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="md:col-span-2 p-8 bg-linear-to-br from-primary to-primary-container rounded-xl shadow-lg text-white flex flex-col justify-between relative overflow-hidden group">
          <div className="absolute -right-12 -bottom-12 w-48 h-48 bg-white/10 rounded-full blur-[48px] group-hover:scale-110 transition-transform duration-700"></div>
          <div className="relative z-10">
            <h3 className="text-3xl font-bold mb-2 font-headline">Manage Access</h3>
            <p className="text-white/80 max-w-md text-sm leading-relaxed">
              Securely oversee citizen and staff permissions. Update roles, manage lifecycle status, and monitor administrative activity across the CityVoice ecosystem.
            </p>
          </div>
          <div className="mt-8 flex gap-4 relative z-10">
            <button className="bg-white text-primary px-6 py-2.5 rounded-lg text-sm font-bold shadow-sm hover:bg-surface-container-low transition-colors active:scale-95">
              Add New User
            </button>
            <button className="bg-primary-container/50 border border-white/20 text-white px-6 py-2.5 rounded-lg text-sm font-bold hover:bg-white/10 transition-colors active:scale-95">
              Export Report
            </button>
          </div>
        </div>

        <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-transparent hover:border-primary/10 transition-all flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <span className="text-[10px] font-black uppercase text-on-surface-variant tracking-tighter">
                Total Citizens
              </span>
              <span className="text-primary bg-primary/5 p-1.5 rounded-lg">
                <Users className="h-4 w-4" />
              </span>
            </div>
            <p className="text-4xl font-black text-on-surface font-headline">{totalCitizens}</p>
          </div>
          <p className="text-[11px] text-[#168a3e] font-bold mt-4 flex items-center gap-1">
            <TrendingUp className="h-3 w-3" />+{users.length > 0 ? '4' : '0'}% from last month
          </p>
        </div>

        <div className="bg-surface-container-lowest p-6 rounded-xl shadow-sm border border-transparent hover:border-primary/10 transition-all flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <span className="text-[10px] font-black uppercase text-on-surface-variant tracking-tighter">
                Active Users
              </span>
              <span className="text-secondary bg-secondary/5 p-1.5 rounded-lg">
                <Bolt className="h-4 w-4" />
              </span>
            </div>
            <p className="text-4xl font-black text-on-surface font-headline">{activeSessions}</p>
          </div>
          <div className="mt-4 flex -space-x-2">
            {users.slice(0, 3).map((u, i) => (
              <div
                key={i}
                className="w-6 h-6 rounded-full border-2 border-white bg-primary text-[8px] flex items-center justify-center text-white font-bold uppercase"
              >
                {u.fullName?.substring(0, 2) || u.email.substring(0, 2)}
              </div>
            ))}
            {activeSessions > 3 && (
              <div className="w-6 h-6 rounded-full bg-surface-container-low border-2 border-white flex items-center justify-center text-[8px] font-bold text-on-surface-variant">
                +{activeSessions - 3}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* List Controls */}
      <div className="flex flex-col md:flex-row items-center justify-between gap-4 bg-surface-container-low p-4 rounded-xl">
        <div className="flex items-center gap-4 w-full md:w-auto">
          <div className="relative w-full md:w-80">
            <input
              className="w-full bg-surface-container-lowest border-none rounded-lg py-2.5 pl-10 pr-4 text-sm focus:ring-2 focus:ring-primary/20 outline-none"
              placeholder="Search by name or email..."
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            <Search className="absolute left-3 top-2.5 text-on-surface-variant h-5 w-5" />
          </div>
          <div className="relative inline-block text-left">
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              className="appearance-none bg-surface-container-lowest px-4 py-2.5 pl-10 pr-8 rounded-lg text-sm font-medium border-none shadow-sm text-on-surface hover:bg-white transition-all outline-none"
            >
              <option value="all">Filter by Role (All)</option>
              {systemRoles.map((r) => (
                <option key={r} value={r}>
                  {r.toUpperCase()}
                </option>
              ))}
            </select>
            <Filter className="absolute left-3 top-2.5 h-4 w-4 text-on-surface-variant" />
            <ChevronDown className="absolute right-3 top-3 h-4 w-4 text-on-surface-variant" />
          </div>
        </div>
      </div>

      {/* Modern Table Interface */}
      <div className="bg-surface-container-lowest rounded-xl shadow-sm overflow-hidden border-none min-h-[400px]">
        {loading ? (
          <div className="py-16 flex justify-center">
            <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary"></div>
          </div>
        ) : (
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-high/50 text-on-surface-variant uppercase text-[11px] font-black tracking-widest">
                <th className="px-8 py-5">Tài khoản</th>
                <th className="px-6 py-5">Liên hệ</th>
                <th className="px-6 py-5">Phân quyền</th>
                <th className="px-6 py-5 text-center">Trạng thái</th>
                <th className="px-8 py-5 text-right">Hành động</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-container-low">
              {filteredUsers.map((u) => {
                const isSysAdmin = u.role === "admin";
                return (
                  <tr key={u.id} className="group hover:bg-surface-container-low/50 transition-colors">
                    <td className="px-8 py-4">
                      <div className="flex items-center gap-3">
                        <div
                          className={`w-9 h-9 rounded-full flex items-center justify-center font-bold text-xs uppercase
                          ${
                            u.role === "admin"
                              ? "bg-error-container text-on-error-container"
                              : u.role === "manager"
                              ? "bg-secondary-container/50 text-on-secondary-container"
                              : u.role === "staff"
                              ? "bg-primary/10 text-primary"
                              : "bg-surface-container-highest text-on-surface-variant"
                          }
                        `}
                        >
                          {u.fullName?.substring(0, 2) || u.email.substring(0, 2)}
                        </div>
                        <span className="text-sm font-bold text-on-surface">
                          {u.fullName || "Tài khoản số #" + u.id.substring(0, 4)}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-on-surface-variant">{u.email}</td>
                    <td className="px-6 py-4">
                      <span
                        className={`px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-wider
                        ${
                          u.role === "admin"
                            ? "bg-error-container text-on-error-container"
                            : u.role === "manager"
                            ? "bg-secondary-container/30 text-secondary"
                            : u.role === "staff"
                            ? "bg-primary/10 text-primary"
                            : "bg-surface-container-high text-on-surface-variant"
                        }
                      `}
                      >
                        {u.role}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-center">
                      <span
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider
                        ${
                          u.isActive
                            ? "bg-[#defce9] text-[#168a3e]"
                            : "bg-surface-container-highest text-on-surface-variant"
                        }
                      `}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full mr-1.5 ${
                            u.isActive ? "bg-[#168a3e]" : "bg-on-surface-variant"
                          }`}
                        ></span>
                        {u.isActive ? "Active" : "Inactive"}
                      </span>
                    </td>
                    <td className="px-8 py-4 text-right">
                      <div className="relative inline-block text-left">
                        <button
                          onClick={() => setOpenDropdownId(openDropdownId === u.id ? null : u.id)}
                          className="text-primary hover:bg-primary/5 px-4 py-2 rounded-lg text-xs font-bold transition-all flex items-center gap-1 ml-auto outline-none"
                        >
                          Change Role
                          <ChevronDown className="h-4 w-4" />
                        </button>
                        {/* Dropdown Menu */}
                        {openDropdownId === u.id && (
                          <div className="absolute right-0 mt-2 w-48 bg-surface-container-lowest border border-surface-container rounded-xl shadow-xl z-10 p-2 animate-fade-in-down">
                            {systemRoles.map((role) => (
                              <button
                                key={role}
                                onClick={() => {
                                  onRoleChange(u.id, role);
                                  setOpenDropdownId(null);
                                }}
                                disabled={isSysAdmin} // Admin roles are often protected
                                className={`w-full text-left px-4 py-2.5 text-xs font-bold rounded-lg flex justify-between items-center transition-colors
                                  ${
                                    u.role === role
                                      ? "bg-primary/10 text-primary"
                                      : "text-on-surface hover:bg-surface-container-low"
                                  }
                                  ${isSysAdmin ? "opacity-50 cursor-not-allowed" : ""}
                                `}
                              >
                                {role.toUpperCase()}
                                {u.role === role && <Check className="h-4 w-4" />}
                              </button>
                            ))}
                          </div>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
              {filteredUsers.length === 0 && (
                <tr>
                  <td colSpan={5} className="py-12 text-center text-on-surface-variant text-sm font-medium">
                    Không tìm thấy người dùng phù hợp.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
