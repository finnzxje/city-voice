import { MapPin, Navigation } from "lucide-react";
import { motion } from "motion/react";
import { useState } from "react";

const MapSection = () => {
    const [view, setView] = useState<'list' | 'map'>('map');

    return (
        <section className="py-24 bg-surface overflow-hidden">
            <div className="max-w-7xl mx-auto px-6">
                <div className="flex flex-col md:flex-row justify-between items-end mb-12 gap-6">
                    <div className="max-w-2xl">
                        <h2 className="font-headline text-4xl font-bold mb-4">Bản đồ sự cố cộng đồng</h2>
                        <p className="text-on-surface-variant text-lg">
                            Minh bạch hóa mọi hoạt động hạ tầng. Bạn có thể xem các sự cố đang được xử lý quanh khu vực của mình.
                        </p>
                    </div>
                    <div className="flex bg-surface-container-high p-1 rounded-xl">
                        <button
                            onClick={() => setView('list')}
                            className={`px-6 py-2 rounded-lg font-bold text-sm transition-all ${view === 'list' ? 'bg-white shadow-sm' : 'text-on-surface-variant'}`}
                        >
                            Danh sách
                        </button>
                        <button
                            onClick={() => setView('map')}
                            className={`px-6 py-2 rounded-lg font-bold text-sm transition-all ${view === 'map' ? 'bg-white shadow-sm' : 'text-on-surface-variant'}`}
                        >
                            Bản đồ
                        </button>
                    </div>
                </div>

                <div className="relative w-full h-[600px] rounded-[3rem] overflow-hidden shadow-2xl border border-white/40">
                    <div className="absolute inset-0 bg-[#eef2ff]">
                        <img
                            className="w-full h-full object-cover opacity-90"
                            src="https://images.unsplash.com/photo-1569336415962-a4bd9f6dfc0f?auto=format&fit=crop&q=80&w=1600"
                            alt="Clean Architectural Map"
                            referrerPolicy="no-referrer"
                        />
                        {/* Soft Grid Overlay */}
                        <div className="absolute inset-0 opacity-10 pointer-events-none">
                            <svg height="100%" width="100%" xmlns="http://www.w3.org/2000/svg">
                                <defs>
                                    <pattern height="80" id="soft-grid" patternUnits="userSpaceOnUse" width="80">
                                        <circle cx="1" cy="1" fill="#0061f2" r="1"></circle>
                                    </pattern>
                                </defs>
                                <rect fill="url(#soft-grid)" height="100%" width="100%"></rect>
                            </svg>
                        </div>
                        <div className="absolute inset-0 bg-gradient-to-t from-white/40 via-transparent to-transparent"></div>
                    </div>

                    {/* Overlays */}
                    <div className="absolute top-8 left-8 flex flex-col gap-4">
                        <div className="bg-white/80 backdrop-blur-xl p-6 rounded-[2rem] shadow-xl border border-white/60 text-on-surface">
                            <h4 className="font-headline font-bold text-base mb-4 text-primary">Phân loại sự cố</h4>
                            <div className="space-y-4">
                                {[
                                    { color: 'bg-blue-500', label: 'Hạ tầng đường bộ', ring: 'ring-blue-100' },
                                    { color: 'bg-emerald-500', label: 'Hệ thống chiếu sáng', ring: 'ring-emerald-100' },
                                    { color: 'bg-orange-500', label: 'Vệ sinh môi trường', ring: 'ring-orange-100' }
                                ].map((item, i) => (
                                    <label key={i} className="flex items-center gap-4 cursor-pointer group">
                                        <span className={`w-3.5 h-3.5 rounded-full ${item.color} ring-4 ${item.ring} group-hover:scale-125 transition-transform`}></span>
                                        <span className="text-sm font-semibold text-on-surface-variant group-hover:text-primary transition-colors">{item.label}</span>
                                    </label>
                                ))}
                            </div>
                        </div>
                    </div>

                    <div className="absolute bottom-10 right-10 flex flex-col gap-4">
                        <button className="w-14 h-14 bg-white/90 backdrop-blur-md text-primary rounded-2xl flex items-center justify-center shadow-xl border border-white hover:bg-white transition-all">
                            <Navigation size={24} />
                        </button>
                        <button className="w-14 h-14 bg-primary text-white rounded-2xl flex items-center justify-center shadow-xl hover:scale-110 transition-all">
                            <MapPin size={24} />
                        </button>
                    </div>

                    {/* Soft Marker Popup */}
                    <div className="absolute top-1/2 left-1/3 -translate-x-1/2 -translate-y-1/2">
                        <div className="relative group cursor-pointer">
                            {/* Soft Pulse */}
                            <motion.div
                                animate={{ scale: [1, 1.8, 1], opacity: [0.3, 0, 0.3] }}
                                transition={{ repeat: Infinity, duration: 2.5 }}
                                className="absolute inset-0 bg-primary rounded-full blur-lg"
                            ></motion.div>

                            <div className="relative w-8 h-8 bg-white rounded-full flex items-center justify-center text-primary shadow-xl border-4 border-primary/20">
                                <div className="w-3 h-3 bg-primary rounded-full"></div>
                            </div>

                            <motion.div
                                initial={{ opacity: 0, y: 10 }}
                                whileHover={{ opacity: 1, y: 0 }}
                                className="absolute bottom-12 left-1/2 -translate-x-1/2 w-64 bg-white/90 backdrop-blur-2xl p-5 rounded-[2.5rem] shadow-2xl border border-white text-on-surface pointer-events-none"
                            >
                                <div className="flex justify-between items-center mb-3">
                                    <span className="px-3 py-1 bg-primary/10 text-primary rounded-full text-[10px] font-bold uppercase tracking-wider">Hạ tầng</span>
                                    <span className="text-[10px] font-bold text-on-surface-variant/40">#SC-1024</span>
                                </div>
                                <p className="text-base font-bold mb-1">Cải tạo vỉa hè</p>
                                <p className="text-xs text-on-surface-variant mb-4">Phường Đa Kao • 2 giờ trước</p>
                                <div className="w-full h-2 bg-primary-container rounded-full overflow-hidden">
                                    <motion.div
                                        initial={{ width: 0 }}
                                        whileInView={{ width: '75%' }}
                                        className="h-full bg-primary"
                                    ></motion.div>
                                </div>
                            </motion.div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    );
};
export default MapSection;