import { useState } from "react";
import type { Category } from "../../../api/services";
import { FolderTree, Search, Plus, Edit2, Trash2, AlertCircle } from "lucide-react";
import * as LucideIcons from "lucide-react";

const COLOR_PALETTE = [
  { bg: "bg-surface-container-high", icon: "text-primary" },
  { bg: "bg-yellow-100", icon: "text-yellow-700" },
  { bg: "bg-emerald-100", icon: "text-emerald-700" },
  { bg: "bg-orange-100", icon: "text-orange-700" },
  { bg: "bg-purple-100", icon: "text-purple-700" },
  { bg: "bg-rose-100", icon: "text-rose-700" },
];

function getCategoryVisual(iconKey: string, index: number) {
  // Try to find the icon dynamically, fallback to FolderTree
  // Converting iconKey like "road-warning" to "RoadWarning" or finding match
  let IconComponent = (LucideIcons as any)[iconKey];
  if (!IconComponent) {
    // Try pascal case conversion
    const pascalKey = iconKey
      .split("-")
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
      .join("");
    IconComponent = (LucideIcons as any)[pascalKey] || LucideIcons.FolderTree;
  }
  const palette = COLOR_PALETTE[index % COLOR_PALETTE.length];
  return { Icon: IconComponent, palette };
}

interface CategoriesTabProps {
  categories: Category[];
  loading: boolean;
  onOpenModal: (cat?: Category) => void;
  onDelete: (id: number) => void;
}

export default function CategoriesTab({ categories, loading, onOpenModal, onDelete }: CategoriesTabProps) {
  const [searchTerm, setSearchTerm] = useState("");

  const activeCategories = categories.filter((c) => c.active !== false);
  const inactiveCategories = categories.filter((c) => c.active === false);

  const displayCategories = categories.filter((c) =>
    c.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-10 animate-fade-in-up">
      {/* Hero Stats / Header Section */}
      <div className="relative overflow-hidden rounded-3xl bg-primary px-10 py-12 text-white shadow-2xl shadow-primary/20">
        <div className="relative z-10 flex flex-col md:flex-row md:items-end justify-between gap-8">
          <div className="max-w-2xl">
            <span className="inline-block px-3 py-1 bg-white/20 backdrop-blur-md rounded-full text-[10px] font-bold uppercase tracking-widest mb-4">
              Core Infrastructure
            </span>
            <h1 className="text-4xl md:text-5xl font-extrabold font-headline leading-tight mb-4">
              Structure City Response
            </h1>
            <p className="text-primary-fixed-dim text-lg max-w-xl">
              Configure incident classification hierarchies to optimize response time and departmental routing.
            </p>
          </div>
          <div className="flex gap-4">
            <div className="bg-white/10 backdrop-blur-md p-6 rounded-2xl border border-white/10 min-w-[140px]">
              <p className="text-xs text-[#b4c5ff] mb-1 font-bold">Total Active</p>
              <p className="text-3xl font-bold font-headline">{activeCategories.length}</p>
            </div>
            <div className="bg-white/10 backdrop-blur-md p-6 rounded-2xl border border-white/10 min-w-[140px]">
              <p className="text-xs text-[#b4c5ff] mb-1 font-bold">Inactive</p>
              <p className="text-3xl font-bold font-headline">{inactiveCategories.length}</p>
            </div>
          </div>
        </div>
        {/* Abstract UI element */}
        <div className="absolute -right-20 -top-20 w-80 h-80 bg-white/10 rounded-full blur-3xl"></div>
        <div className="absolute -left-20 -bottom-20 w-64 h-64 bg-indigo-900/40 rounded-full blur-3xl"></div>
      </div>

      {/* Main Management Interface */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Left: Category List (Bento Grid) */}
        <div className="lg:col-span-8 space-y-4">
          <div className="flex items-center justify-between mb-4 px-2">
            <h3 className="text-xl font-bold text-on-surface flex items-center gap-2 font-headline">
              Active Categories
              <span className="text-xs font-bold px-3 py-0.5 bg-surface-container text-on-surface-variant rounded-full">
                All
              </span>
            </h3>
            <div className="flex gap-2">
              <div className="relative hidden sm:block">
                <input
                  className="bg-surface-container-lowest border-none rounded-lg py-2 pl-9 pr-4 text-sm focus:ring-2 focus:ring-primary/20 outline-none w-48 shadow-sm"
                  placeholder="Find category..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                />
                <Search className="absolute left-3 top-2.5 text-on-surface-variant h-4 w-4" />
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-4">
            {loading ? (
              <div className="py-12 flex justify-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
              </div>
            ) : displayCategories.length === 0 ? (
               <div className="text-center py-12 text-on-surface-variant">Không có danh mục nào</div>
            ) : (
              displayCategories.map((cat, idx) => {
                const { Icon, palette } = getCategoryVisual(cat.iconKey, idx);
                const isActive = cat.active !== false;

                return (
                  <div
                    key={cat.id}
                    className={`group bg-surface-container-lowest p-5 rounded-2xl flex items-center justify-between transition-all hover:-translate-y-0.5 hover:shadow-xl hover:shadow-surface-container border hover:border-primary/20
                      ${!isActive ? "opacity-60 grayscale bg-surface-container" : "border-transparent"}
                    `}
                  >
                    <div className="flex items-center gap-5">
                      <div
                        className={`w-14 h-14 rounded-2xl flex items-center justify-center 
                          ${isActive ? palette.bg + " " + palette.icon : "bg-surface-container-high text-on-surface-variant"}
                        `}
                      >
                        <Icon className="h-7 w-7" />
                      </div>
                      <div>
                        <h4 className="font-bold text-on-surface text-lg leading-tight font-headline">
                          {cat.name}
                        </h4>
                        <p className="text-sm text-on-surface-variant font-mono tracking-tight mt-0.5">
                          /incident/{cat.slug}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-6">
                      <div className="hidden sm:block text-right mr-4">
                        <p className="text-[10px] font-black uppercase tracking-tighter text-outline-variant mb-0.5">
                          Status
                        </p>
                        <p className={`text-sm font-bold ${isActive ? "text-[#168a3e]" : "text-on-surface-variant"}`}>
                          {isActive ? "Active" : "Disabled"}
                        </p>
                      </div>
                      <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button
                          onClick={() => onOpenModal(cat)}
                          className="p-2.5 rounded-xl bg-surface-container text-on-surface-variant hover:text-primary hover:bg-primary/10 transition-colors"
                          title="Chỉnh sửa"
                        >
                          <Edit2 className="h-4 w-4" />
                        </button>
                        {isActive && (
                          <button
                            onClick={() => onDelete(cat.id)}
                            className="p-2.5 rounded-xl bg-surface-container text-on-surface-variant hover:text-error hover:bg-error-container/50 transition-colors"
                            title="Xóa/Tắt"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* Right: Quick Action Widget */}
        <div className="lg:col-span-4 sticky top-24">
          <div className="bg-surface-container-lowest p-8 rounded-3xl shadow-xl shadow-surface-container border border-surface-container-low mb-6">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary">
                <FolderTree className="h-5 w-5" />
              </div>
              <h3 className="text-xl font-bold text-on-surface font-headline">New Category</h3>
            </div>
            
            <p className="text-sm text-on-surface-variant mb-6 leading-relaxed">
              Create a new incident category to expand the reporting capabilities for citizens. Choose a clear name and an identifiable icon.
            </p>

            <button
              onClick={() => onOpenModal()}
              className="w-full bg-primary text-white py-4 rounded-xl font-bold flex items-center justify-center gap-2 hover:bg-primary-container transition-all active:scale-95 shadow-lg shadow-primary/20"
            >
              <Plus className="h-5 w-5" />
              Tạo danh mục mới
            </button>
          </div>

          <div className="p-6 rounded-3xl bg-secondary-container/10 border border-secondary/20">
            <div className="flex items-start gap-3">
              <AlertCircle className="h-5 w-5 text-secondary mt-0.5" />
              <div>
                <h4 className="text-sm font-bold text-on-secondary-container mb-1">Audit Log</h4>
                <p className="text-xs text-on-surface-variant leading-relaxed font-medium">
                  Changes to category metadata are logged with a timestamp for compliance tracking.
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
