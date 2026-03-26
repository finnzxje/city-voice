import { useEffect, useState } from "react";
import { useAuth } from "../../contexts/AuthContext";
import { AdminAPI, IncidentAPI, type UserInfo, type Category } from "../../api/services";
import {
  Users,
  Settings,
  ShieldCheck,
  LogOut,
  FolderTree,
  Edit2,
  Trash2,
  X,
  Plus,
  CloudRain,
  Lamp,
  TreeDeciduous,
  Footprints,
  CircleHelp,
  TriangleAlert,
  TrafficCone,
  type LucideIcon
} from "lucide-react";
import toast from "react-hot-toast";

/* ── Icon & Color mapping for category iconKey ───────────────────── */
const ICON_MAP: Record<string, LucideIcon> = {
  "road-warning": TrafficCone,
  "lamp-off": Lamp,
  "cloud-rain": CloudRain,
  "triangle-alert": TriangleAlert,
  "trash-x": Trash2,
  "tree": TreeDeciduous,
  "footprints": Footprints,
  "circle-help": CircleHelp,
};

const COLOR_PALETTE = [
  { bg: "bg-amber-50",   border: "border-amber-200", icon: "text-amber-600",  tag: "bg-amber-100 text-amber-700" },
  { bg: "bg-violet-50",  border: "border-violet-200",icon: "text-violet-600", tag: "bg-violet-100 text-violet-700" },
  { bg: "bg-sky-50",     border: "border-sky-200",   icon: "text-sky-600",    tag: "bg-sky-100 text-sky-700" },
  { bg: "bg-rose-50",    border: "border-rose-200",  icon: "text-rose-600",   tag: "bg-rose-100 text-rose-700" },
  { bg: "bg-emerald-50", border: "border-emerald-200",icon: "text-emerald-600",tag: "bg-emerald-100 text-emerald-700" },
  { bg: "bg-teal-50",    border: "border-teal-200",  icon: "text-teal-600",   tag: "bg-teal-100 text-teal-700" },
  { bg: "bg-pink-50",    border: "border-pink-200",  icon: "text-pink-600",   tag: "bg-pink-100 text-pink-700" },
  { bg: "bg-indigo-50",  border: "border-indigo-200",icon: "text-indigo-600", tag: "bg-indigo-100 text-indigo-700" },
];

function getCategoryVisual(iconKey: string, index: number) {
  const Icon = ICON_MAP[iconKey] || CircleHelp;
  const palette = COLOR_PALETTE[index % COLOR_PALETTE.length];
  return { Icon, palette };
}

export default function AdminDashboard() {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = useState<'users' | 'categories'>('users');
  
  // Data sets
  const [users, setUsers] = useState<UserInfo[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [systemRoles, setSystemRoles] = useState<string[]>(['citizen', 'staff', 'manager', 'admin']);
  
  const [loading, setLoading] = useState(false);

  // Category Modal States
  const [isCategoryModalOpen, setIsCategoryModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [categoryForm, setCategoryForm] = useState({ name: '', slug: '', iconKey: '' });

  useEffect(() => {
    if (activeTab === 'users') {
      fetchUsers();
      fetchRoles();
    } else {
      fetchCategories();
    }
  }, [activeTab]);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const res = await AdminAPI.getUsers();
      if (res.data?.data) setUsers(res.data.data);
    } catch (err: any) {
      toast.error("Không thể tải danh sách người dùng. Hãy đảm bảo bạn có quyền Admin.");
    } finally {
      setLoading(false);
    }
  };

  const fetchRoles = async () => {
    try {
      const res = await AdminAPI.getRoles();
      if (res.data?.data) setSystemRoles(res.data.data);
    } catch (err) {
      console.error(err);
    }
  };

  const fetchCategories = async () => {
    setLoading(true);
    try {
      const res = await IncidentAPI.getCategories();
      if (res.data?.data) setCategories(res.data.data);
    } catch (err) {
      toast.error("Không thể tải danh mục.");
    } finally {
      setLoading(false);
    }
  };

  const handleRoleChange = async (userId: string, newRole: string) => {
    const toastId = toast.loading("Đang cập nhật quyền...");
    try {
      await AdminAPI.updateUserRole(userId, newRole);
      toast.success("Cập nhật thành công", { id: toastId });
      fetchUsers(); 
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Cập nhật thất bại", { id: toastId });
    }
  };

  const handleOpenCategoryModal = (cat?: Category) => {
    if (cat) {
      setEditingCategory(cat);
      setCategoryForm({ name: cat.name, slug: cat.slug, iconKey: cat.iconKey });
    } else {
      setEditingCategory(null);
      setCategoryForm({ name: '', slug: '', iconKey: '' });
    }
    setIsCategoryModalOpen(true);
  };

  const handleSaveCategory = async () => {
    if (!categoryForm.name || !categoryForm.slug) {
      toast.error("Vui lòng điền tên và slug");
      return;
    }
    const toastId = toast.loading("Đang lưu...");
    try {
      if (editingCategory) {
        await AdminAPI.updateCategory(editingCategory.id, categoryForm);
      } else {
        await AdminAPI.createCategory(categoryForm);
      }
      toast.success("Đã lưu danh mục", { id: toastId });
      setIsCategoryModalOpen(false);
      fetchCategories();
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Lưu thất bại", { id: toastId });
    }
  };

  const handleDeleteCategory = async (id: number) => {
    if (!window.confirm("Bạn có chắc muốn vô hiệu hóa danh mục này?")) return;
    const toastId = toast.loading("Đang xử lý...");
    try {
      await AdminAPI.updateCategory(id, { active: false });
      toast.success("Đã vô hiệu hóa", { id: toastId });
      fetchCategories();
    } catch (err: any) {
      toast.error(err.response?.data?.message || "Cập nhật thất bại", { id: toastId });
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col relative">
      <header className="bg-slate-900 text-white sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16 items-center">
            <div className="flex items-center gap-3">
              <div className="h-8 w-8 bg-slate-700 rounded-lg flex items-center justify-center transform rotate-3">
                <ShieldCheck className="text-white h-5 w-5 transform -rotate-3" />
              </div>
              <span className="font-bold text-xl tracking-tight">
                CityVoice Admin
              </span>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm font-medium text-slate-300 hidden sm:block">
                Xin chào, {user?.fullName || user?.email}
              </span>
              <button
                onClick={logout}
                className="p-2 text-slate-400 hover:text-red-400 transition-colors rounded-lg hover:bg-slate-800"
                title="Đăng xuất"
              >
                <LogOut className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      </header>

      <div className="flex-1 w-full max-w-7xl mx-auto flex flex-col md:flex-row py-8 px-4 sm:px-6 lg:px-8 gap-8">
        
        <div className="w-full md:w-64 flex-shrink-0">
          <nav className="space-y-1 bg-white p-2 rounded-xl border border-gray-200 shadow-sm">
            <button
              onClick={() => setActiveTab('users')}
              className={`w-full flex items-center px-4 py-3 text-sm font-medium rounded-lg ${
                activeTab === 'users' 
                ? 'bg-slate-900 text-white' 
                : 'text-gray-700 hover:bg-gray-100'
              }`}
            >
              <Users className={`h-5 w-5 mr-3 ${activeTab === 'users' ? 'text-white' : 'text-gray-400'}`} />
              Quản trị Người dùng
            </button>
            <button
              onClick={() => setActiveTab('categories')}
              className={`w-full flex items-center px-4 py-3 text-sm font-medium rounded-lg ${
                activeTab === 'categories' 
                ? 'bg-slate-900 text-white' 
                : 'text-gray-700 hover:bg-gray-100'
              }`}
            >
              <FolderTree className={`h-5 w-5 mr-3 ${activeTab === 'categories' ? 'text-white' : 'text-gray-400'}`} />
              Quản lý Danh mục
            </button>
            <button
              disabled
              className="w-full flex items-center px-4 py-3 text-sm font-medium rounded-lg text-gray-400 opacity-60 cursor-not-allowed"
            >
              <Settings className="h-5 w-5 mr-3 text-gray-400" />
              Cấu hình Hệ thống
            </button>
          </nav>
        </div>

        <div className="flex-1 min-w-0">
          {activeTab === 'users' && (
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden flex flex-col h-[700px]">
              <div className="px-6 py-5 border-b border-gray-200 bg-gray-50 flex justify-between items-center">
                <div>
                  <h3 className="text-lg font-medium text-gray-900">Tài khoản & Phân quyền</h3>
                  <p className="mt-1 text-sm text-gray-500">Quản lý roles của công dân, cán bộ, quản lý.</p>
                </div>
              </div>
              <div className="flex-1 overflow-auto p-0">
                {loading ? (
                   <div className="py-12 flex justify-center"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-slate-900"></div></div>
                ) : (
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50 sticky top-0">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Người dùng</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Trạng thái</th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Phân quyền (Role)</th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {users.map((u) => (
                        <tr key={u.id}>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="flex items-center">
                              <div className="h-10 w-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-600 font-bold uppercase border border-slate-200">
                                {u.fullName?.substring(0,2) || u.email.substring(0,2)}
                              </div>
                              <div className="ml-4">
                                <div className="text-sm font-medium text-gray-900">{u.fullName || "Chưa cập nhật"}</div>
                                <div className="text-sm text-gray-500">{u.email}</div>
                              </div>
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${u.isActive ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                              {u.isActive ? 'Hoạt động' : 'Đã khóa'}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            <select
                              value={u.role.toLowerCase()}
                              onChange={(e) => handleRoleChange(u.id, e.target.value)}
                              disabled={u.id === user?.id}
                              className="mt-1 block w-40 pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-slate-500 focus:border-slate-500 sm:text-sm rounded-md shadow-sm"
                            >
                              {systemRoles.map(role => (
                                <option key={role} value={role.toLowerCase()}>{role.toUpperCase()}</option>
                              ))}
                            </select>
                          </td>
                        </tr>
                      ))}
                      {users.length === 0 && (
                        <tr>
                          <td colSpan={3} className="px-6 py-10 text-center text-gray-500">Không tìm thấy người dùng.</td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                )}
              </div>
            </div>
          )}

          {/* ═══════════════════════════════════════════════════════════
              CATEGORIES TAB – Card Grid Design
              ═══════════════════════════════════════════════════════════ */}
          {activeTab === 'categories' && (
            <div className="space-y-6">
              {/* Header */}
              <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                  <h3 className="text-xl font-semibold text-gray-900">Danh mục Sự cố</h3>
                  <p className="mt-1 text-sm text-gray-500">
                    Quản lý các loại sự cố được hiển thị cho công dân.
                    <span className="ml-2 inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-600">
                      {categories.length} danh mục
                    </span>
                  </p>
                </div>
                <button 
                  className="flex items-center gap-2 bg-slate-900 text-white px-5 py-2.5 rounded-xl font-medium text-sm hover:bg-slate-800 transition-all shadow-sm hover:shadow-md active:scale-95"
                  onClick={() => handleOpenCategoryModal()}
                >
                  <Plus className="h-4 w-4" />
                  Thêm danh mục
                </button>
              </div>

              {loading ? (
                <div className="py-16 flex justify-center">
                  <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-slate-900"></div>
                </div>
              ) : categories.length === 0 ? (
                <div className="text-center py-20 bg-white rounded-2xl border-2 border-dashed border-gray-200">
                  <FolderTree className="mx-auto h-12 w-12 text-gray-300 mb-3" />
                  <p className="text-gray-500">Chưa có danh mục nào.</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
                  {categories.map((c, idx) => {
                    const { Icon, palette } = getCategoryVisual(c.iconKey, idx);
                    return (
                      <div
                        key={c.id}
                        className={`group relative rounded-2xl border ${palette.border} ${palette.bg} p-5 transition-all duration-200 hover:shadow-lg hover:-translate-y-0.5`}
                      >
                        {/* Top row: Icon + Actions */}
                        <div className="flex items-start justify-between mb-4">
                          <div className={`h-12 w-12 rounded-xl ${palette.bg} border ${palette.border} flex items-center justify-center shadow-sm`}>
                            <Icon className={`h-6 w-6 ${palette.icon}`} />
                          </div>
                          {/* Action buttons – visible on hover */}
                          <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
                            <button
                              onClick={() => handleOpenCategoryModal(c)}
                              className="p-2 rounded-lg bg-white/80 hover:bg-white text-gray-500 hover:text-indigo-600 border border-gray-200/80 shadow-sm transition-colors"
                              title="Chỉnh sửa"
                            >
                              <Edit2 className="h-4 w-4" />
                            </button>
                            <button
                              onClick={() => handleDeleteCategory(c.id)}
                              className="p-2 rounded-lg bg-white/80 hover:bg-white text-gray-500 hover:text-red-600 border border-gray-200/80 shadow-sm transition-colors"
                              title="Vô hiệu hóa"
                            >
                              <Trash2 className="h-4 w-4" />
                            </button>
                          </div>
                        </div>

                        {/* Category name */}
                        <h4 className="text-base font-semibold text-gray-900 mb-1.5 group-hover:text-gray-800">
                          {c.name}
                        </h4>

                        {/* Slug tag */}
                        <span className={`inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-mono font-medium ${palette.tag}`}>
                          {c.slug}
                        </span>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          )}

        </div>
      </div>

      {/* ═══════════════════════════════════════════════════════════
          Category Create / Edit Modal
          ═══════════════════════════════════════════════════════════ */}
      {isCategoryModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-4" onClick={() => setIsCategoryModalOpen(false)}>
          <div className="bg-white w-full max-w-md rounded-2xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200" onClick={(e) => e.stopPropagation()}>
            {/* Modal header */}
            <div className="flex justify-between items-center px-6 py-5 border-b border-gray-100">
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-xl bg-slate-100 flex items-center justify-center">
                  <FolderTree className="h-5 w-5 text-slate-600" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">
                    {editingCategory ? "Chỉnh sửa danh mục" : "Thêm mới danh mục"}
                  </h3>
                  <p className="text-xs text-gray-400">Điền thông tin bên dưới</p>
                </div>
              </div>
              <button 
                onClick={() => setIsCategoryModalOpen(false)}
                className="p-2 rounded-lg text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-colors"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Modal body */}
            <div className="px-6 py-5 space-y-5">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">Tên danh mục</label>
                <input 
                  type="text" 
                  value={categoryForm.name}
                  onChange={(e) => setCategoryForm({...categoryForm, name: e.target.value})}
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-slate-500/20 focus:border-slate-500 transition-shadow outline-none"
                  placeholder="VD: Giao thông"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">Slug (mã định danh)</label>
                <input 
                  type="text" 
                  value={categoryForm.slug}
                  onChange={(e) => setCategoryForm({...categoryForm, slug: e.target.value})}
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm font-mono focus:ring-2 focus:ring-slate-500/20 focus:border-slate-500 transition-shadow outline-none"
                  placeholder="VD: giao-thong"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">Icon Key</label>
                <input 
                  type="text" 
                  value={categoryForm.iconKey}
                  onChange={(e) => setCategoryForm({...categoryForm, iconKey: e.target.value})}
                  className="w-full px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-slate-500/20 focus:border-slate-500 transition-shadow outline-none"
                  placeholder="VD: road-warning, cloud-rain, tree"
                />
                <p className="mt-1.5 text-xs text-gray-400">
                  Các key hỗ trợ: road-warning, lamp-off, cloud-rain, triangle-alert, trash-x, tree, footprints, circle-help
                </p>
              </div>

              {/* Live preview */}
              {categoryForm.name && (
                <div className="pt-2 border-t border-gray-100">
                  <p className="text-xs font-medium text-gray-400 uppercase tracking-wider mb-2">Xem trước</p>
                  <div className={`rounded-xl border p-4 flex items-center gap-3 ${getCategoryVisual(categoryForm.iconKey || '', 0).palette.bg} ${getCategoryVisual(categoryForm.iconKey || '', 0).palette.border}`}>
                    {(() => {
                      const { Icon, palette } = getCategoryVisual(categoryForm.iconKey || '', 0);
                      return (
                        <>
                          <div className={`h-10 w-10 rounded-lg flex items-center justify-center border ${palette.border} ${palette.bg}`}>
                            <Icon className={`h-5 w-5 ${palette.icon}`} />
                          </div>
                          <div>
                            <p className="font-semibold text-gray-900 text-sm">{categoryForm.name}</p>
                            {categoryForm.slug && (
                              <span className={`inline-flex text-xs font-mono mt-0.5 ${palette.tag} px-1.5 py-0.5 rounded`}>
                                {categoryForm.slug}
                              </span>
                            )}
                          </div>
                        </>
                      );
                    })()}
                  </div>
                </div>
              )}
            </div>

            {/* Modal footer */}
            <div className="px-6 py-4 bg-gray-50/80 border-t border-gray-100 flex justify-end gap-3">
              <button 
                onClick={() => setIsCategoryModalOpen(false)}
                className="px-5 py-2.5 border border-gray-200 rounded-xl text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors"
              >
                Hủy
              </button>
              <button 
                onClick={handleSaveCategory}
                className="px-5 py-2.5 bg-slate-900 rounded-xl text-sm font-medium text-white hover:bg-slate-800 transition-colors shadow-sm hover:shadow-md active:scale-95"
              >
                {editingCategory ? "Lưu thay đổi" : "Tạo danh mục"}
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
