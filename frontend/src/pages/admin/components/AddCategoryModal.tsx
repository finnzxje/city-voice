import { AlertTriangle, ArrowLeft, Check, FolderTree, Trash2, X } from "lucide-react";
import { useEffect, useState } from "react";

interface CategoryForm {
  name: string;
  slug: string;
  iconKey: string;
}

interface AddCategoryModalProps {
  isOpen: boolean;
  onClose: () => void;
  form: CategoryForm;
  setForm: (form: CategoryForm) => void;
  onSave: (isActive: boolean) => void;
  isEditing: boolean;
  isActive: boolean | null;
}

const COMMON_ICONS = ["Cone", "Zap", "CloudRain", "AlertTriangle", "Trash2", "TreeDeciduous", "Wrench", "CircleHelp"];

export default function AddCategoryModal({
  isActive,
  isOpen,
  onClose,
  form,
  setForm,
  onSave,
  isEditing
}: AddCategoryModalProps) {
  const [showConfirm, setShowConfirm] = useState(false);
  useEffect(() => {
    if (!isOpen) setShowConfirm(false);
  }, [isOpen]);

  if (!isOpen) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-4" onClick={onClose}>
      <div className="bg-surface-container-lowest w-full max-w-md rounded-3xl shadow-2xl overflow-hidden animate-fade-in-down duration-200" onClick={(e) => e.stopPropagation()}>
        {/* --- GIAO DIỆN XÁC NHẬN (OVERLAY) --- */}
        {showConfirm && (
          <div className="absolute inset-0 z-20 bg-surface-container-lowest flex flex-col items-center justify-center p-8 text-center animate-fade-in">
            <div className="w-16 h-16 bg-error/10 text-error rounded-full flex items-center justify-center mb-4">
              <AlertTriangle className="h-8 w-8" />
            </div>
            <h4 className="text-xl font-bold text-on-surface mb-2 font-headline">Xác nhận vô hiệu hóa?</h4>
            <p className="text-sm text-on-surface-variant mb-8">
              Danh mục <span className="font-bold text-on-surface">"{form.name}"</span> sẽ bị ẩn khỏi ứng dụng. Bạn có thể kích hoạt lại sau trong phần quản trị.
            </p>
            <div className="flex flex-col w-full gap-3">
              <button
                onClick={() => onSave(false)} // Gọi API với active: false
                className="w-full bg-error text-white py-4 rounded-2xl font-bold shadow-lg shadow-error/20 active:scale-95 transition-all"
              >
                Vâng, vô hiệu hóa nó
              </button>
              <button
                onClick={() => setShowConfirm(false)}
                className="w-full py-3 text-sm font-bold text-on-surface-variant flex items-center justify-center gap-2"
              >
                <ArrowLeft className="h-4 w-4" /> Quay lại chỉnh sửa
              </button>
            </div>
          </div>
        )}
        {/* Header */}
        <div className="flex justify-between items-center px-8 py-6 border-b border-surface-container">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-xl bg-primary/10 flex items-center justify-center">
              <FolderTree className="h-5 w-5 text-primary" />
            </div>
            <div>
              <h3 className="text-xl font-bold text-on-surface font-headline">
                {isEditing ? "Chỉnh sửa danh mục" : "Thêm mới danh mục"}
              </h3>
              <p className="text-xs font-bold text-on-surface-variant tracking-wider uppercase">Điền thông tin</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-xl text-on-surface-variant hover:text-on-surface hover:bg-surface-container transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Body */}
        <div className="px-8 py-6 space-y-6">
          <div className="space-y-2">
            <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider ml-1">Tên danh mục</label>
            <input
              type="text"
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              className="w-full bg-surface-container-highest border-none rounded-xl p-4 focus:ring-2 focus:ring-primary/40 text-sm outline-none transition-all placeholder-outline-variant"
              placeholder="e.g. Giao thông công cộng"
            />
          </div>

          <div className="space-y-2">
            <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider ml-1">URL Slug</label>
            <div className="relative">
              <span className="absolute left-4 top-4 text-outline-variant font-mono text-sm">/</span>
              <input
                type="text"
                value={form.slug}
                onChange={(e) => setForm({ ...form, slug: e.target.value })}
                className="w-full bg-surface-container-highest border-none rounded-xl p-4 pl-7 focus:ring-2 focus:ring-primary/40 text-sm font-mono outline-none transition-all placeholder-outline-variant"
                placeholder="giao-thong"
              />
            </div>
          </div>

          <div className="space-y-2">
            <label className="text-xs font-bold text-on-surface-variant uppercase tracking-wider ml-1">Icon Key (Lucide)</label>
            <input
              type="text"
              value={form.iconKey}
              onChange={(e) => setForm({ ...form, iconKey: e.target.value })}
              className="w-full bg-surface-container-highest border-none rounded-xl p-4 text-sm font-mono focus:ring-2 focus:ring-primary/40 outline-none transition-all"
              placeholder="e.g. AlertTriangle, Trash2"
            />
            <div className="grid grid-cols-4 gap-2 mt-2">
              {COMMON_ICONS.map((icon) => (
                <button
                  key={icon}
                  type="button"
                  onClick={() => setForm({ ...form, iconKey: icon })}
                  className={`py-2 text-[10px] font-bold rounded-lg border-2 transition-colors 
                     ${form.iconKey === icon ? 'border-primary bg-primary/10 text-primary' : 'border-surface-container text-on-surface-variant hover:bg-surface-container'}
                  `}
                >
                  {icon}
                </button>
              ))}
            </div>
          </div>

          {/* ACTION BUTTONS */}
          <div className="pt-4 space-y-3">
            <button
              onClick={() => onSave(true)}
              disabled={!form.name || !form.slug}
              className="w-full bg-primary text-white py-4 rounded-xl font-bold flex items-center justify-center gap-2 hover:bg-primary-container transition-all active:scale-[0.98] shadow-lg shadow-primary/20 disabled:opacity-50 disabled:shadow-none"
            >
              {isEditing ? "Cập nhật thay đổi" : "Tạo danh mục"}
            </button>
            {isEditing && (
              isActive ? (
                <button
                  type="button"
                  onClick={() => setShowConfirm(true)}
                  className="w-full flex items-center justify-center gap-2 py-3 rounded-xl text-error hover:bg-error/5 font-bold text-sm transition-all border border-transparent hover:border-error/20"
                >
                  <Trash2 className="h-4 w-4" />
                  Vô hiệu hóa danh mục này
                </button>
              ) : (
                <button
                  type="button"
                  onClick={() => onSave(true)}
                  className="w-full flex items-center justify-center gap-2 py-3 rounded-xl text-success hover:bg-success/5 font-bold text-sm transition-all border border-transparent hover:border-success/20"
                >
                  <Check className="h-4 w-4" />
                  Kích hoạt danh mục này
                </button>
              )
            )}
          </div>
          {isEditing && (
            <p className="text-[10px] text-on-surface-variant text-center italic">
              * Vô hiệu hóa sẽ ẩn danh mục khỏi danh sách báo cáo của người dân.
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
