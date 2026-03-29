import { FolderTree, X } from "lucide-react";

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
  onSave: () => void;
  isEditing: boolean;
}

const COMMON_ICONS = ["Cone", "Zap", "CloudRain", "AlertTriangle", "Trash2", "TreeDeciduous", "Wrench", "CircleHelp"];

export default function AddCategoryModal({
  isOpen,
  onClose,
  form,
  setForm,
  onSave,
  isEditing
}: AddCategoryModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm px-4" onClick={onClose}>
      <div className="bg-surface-container-lowest w-full max-w-md rounded-3xl shadow-2xl overflow-hidden animate-fade-in-down duration-200" onClick={(e) => e.stopPropagation()}>
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
              onChange={(e) => setForm({...form, name: e.target.value})}
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
                onChange={(e) => setForm({...form, slug: e.target.value})}
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

          <div className="pt-4">
            <button 
              onClick={onSave}
              disabled={!form.name || !form.slug}
              className="w-full bg-primary text-white py-4 rounded-xl font-bold flex items-center justify-center gap-2 hover:bg-primary-container transition-all active:scale-[0.98] shadow-lg shadow-primary/20 disabled:opacity-50 disabled:shadow-none"
            >
              {isEditing ? "Cập nhật thay đổi" : "Tạo danh mục"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
