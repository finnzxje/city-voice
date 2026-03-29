import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../../contexts/AuthContext";
import { AdminAPI, IncidentAPI, type UserInfo, type Category } from "../../api/services";
import {
  LogOut,
  Building2,
  LayoutDashboard,
  Users,
  FolderTree,
  Database
} from "lucide-react";
import toast from "react-hot-toast";

import UsersTab from "./components/UsersTab";
import CategoriesTab from "./components/CategoriesTab";
import AddCategoryModal from "./components/AddCategoryModal";

export default function AdminDashboard() {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = useState<'users' | 'categories'>('users');
  
  // Data sets
  const [usersList, setUsersList] = useState<UserInfo[]>([]);
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
      if (res.data?.data) setUsersList(res.data.data);
    } catch (err: any) {
      toast.error("Không thể tải danh sách người dùng.");
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
      setCategoryForm({ name: cat.name, slug: cat.slug, iconKey: cat.iconKey || '' });
    } else {
      setEditingCategory(null);
      setCategoryForm({ name: '', slug: '', iconKey: 'FolderTree' });
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

          <button
            onClick={() => setActiveTab('users')}
            className={`w-full flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-all duration-200 cursor-pointer ${
              activeTab === 'users' ? 'bg-surface-container-lowest text-primary shadow-sm hover:translate-y-0 active:scale-100' : 'text-on-surface-variant hover:text-on-surface hover:bg-surface-container-low hover:translate-x-1'
            }`}
          >
            <Users className="mr-3 h-5 w-5" />
            User Access
          </button>
          
          <button
            onClick={() => setActiveTab('categories')}
            className={`w-full flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-all duration-200 cursor-pointer ${
              activeTab === 'categories' ? 'bg-surface-container-lowest text-primary shadow-sm hover:translate-y-0 active:scale-100' : 'text-on-surface-variant hover:text-on-surface hover:bg-surface-container-low hover:translate-x-1'
            }`}
          >
            <FolderTree className="mr-3 h-5 w-5" />
            Categories
          </button>

          <button disabled className="w-full flex items-center px-4 py-3 text-outline-variant text-sm font-medium rounded-lg cursor-not-allowed">
            <Database className="mr-3 h-5 w-5" />
            System Logs
          </button>
        </nav>

        <div className="pt-4 mt-auto border-t border-surface-container space-y-1">
          <button onClick={logout} className="w-full flex items-center px-4 py-3 text-error hover:bg-error-container/20 transition-all duration-200 cursor-pointer text-sm font-bold rounded-lg group">
            <LogOut className="mr-3 h-5 w-5 group-hover:-translate-x-1 transition-transform" />
            Sign Out
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 md:ml-64 min-w-0 bg-surface min-h-screen pb-12">
        {/* TopAppBar */}
        <header className="sticky top-0 w-full flex items-center justify-between px-8 h-16 bg-surface-container-lowest/70 backdrop-blur-xl z-40 border-b border-surface-container/50">
          <div className="flex items-center gap-8">
            <h2 className="text-xl font-bold tracking-tight text-on-surface font-headline antialiased">
               {activeTab === 'users' ? 'IAM Management' : 'Category Management'}
            </h2>
            <nav className="hidden md:flex items-center gap-6 text-sm font-medium">
               <span className="text-primary font-bold border-b-2 border-primary py-5">Overview</span>
               <span className="text-on-surface-variant py-5">Analytics</span>
            </nav>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-3 ml-2 pl-4 border-l border-surface-container">
              <div className="text-right hidden sm:block">
                <p className="text-xs font-bold text-on-surface leading-none">{user?.fullName || "Chưa cập nhật"}</p>
                <p className="text-[10px] text-on-surface-variant uppercase font-bold tracking-wider mt-0.5">Admin</p>
              </div>
              <div className="h-9 w-9 bg-error-container text-on-error-container rounded-full flex items-center justify-center font-bold text-xs uppercase border-2 border-surface-container-lowest shadow-sm">
                {user?.fullName?.substring(0,2) || user?.email.substring(0,2)}
              </div>
            </div>
          </div>
        </header>

        {/* Dynamic Content */}
        <div className="p-8 max-w-7xl mx-auto w-full">
           {activeTab === 'users' && (
             <UsersTab 
               users={usersList} 
               systemRoles={systemRoles} 
               loading={loading}
               onRoleChange={handleRoleChange} 
             />
           )}
           
           {activeTab === 'categories' && (
             <CategoriesTab 
               categories={categories}
               loading={loading}
               onOpenModal={handleOpenCategoryModal}
               onDelete={handleDeleteCategory}
             />
           )}
        </div>
      </main>

      <AddCategoryModal 
        isOpen={isCategoryModalOpen}
        onClose={() => setIsCategoryModalOpen(false)}
        form={categoryForm}
        setForm={setCategoryForm}
        onSave={handleSaveCategory}
        isEditing={!!editingCategory}
      />
    </div>
  );
}
