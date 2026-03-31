const Stats = () => (
    <section className="py-20">
        <div className="max-w-7xl mx-auto px-6">
            <div className="bg-primary rounded-[4rem] p-12 md:p-24 text-white flex flex-col md:flex-row justify-between items-center gap-12 relative overflow-hidden shadow-2xl shadow-primary/20">
                {/* Texture */}
                <div className="absolute inset-0 opacity-10 pointer-events-none">
                    <svg height="100%" width="100%" xmlns="http://www.w3.org/2000/svg">
                        <defs>
                            <pattern height="40" id="dots" patternUnits="userSpaceOnUse" width="40">
                                <circle cx="2" cy="2" fill="white" r="1"></circle>
                            </pattern>
                        </defs>
                        <rect fill="url(#dots)" height="100%" width="100%"></rect>
                    </svg>
                </div>

                <div className="text-center md:text-left z-10">
                    <h2 className="font-headline text-5xl font-extrabold mb-6">Kết quả từ cộng đồng</h2>
                    <p className="text-white/80 text-xl font-medium">Cùng nhau, chúng ta đang thay đổi diện mạo thành phố.</p>
                </div>

                <div className="grid grid-cols-2 md:grid-cols-3 gap-8 md:gap-16 z-10">
                    {[
                        { value: "12,4k+", label: "Báo cáo đã xử lý" },
                        { value: "98%", label: "Mức độ hài lòng" },
                        { value: "<24h", label: "Thời gian trung bình" }
                    ].map((stat, i) => (
                        <div key={i} className="text-center">
                            <p className="font-headline text-4xl md:text-5xl font-extrabold mb-2">{stat.value}</p>
                            <p className="text-xs font-bold text-white/60 uppercase tracking-widest">{stat.label}</p>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    </section>
);
export default Stats;