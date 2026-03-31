import { ArrowRight, CheckCircle2 } from "lucide-react";
import { motion } from "motion/react";

const Hero = () => (
    <section className="relative min-h-[800px] flex items-center overflow-hidden px-6 pt-32 pb-20">
        <div className="max-w-7xl mx-auto w-full grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            <motion.div
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.6 }}
                className="lg:col-span-7 z-10"
            >
                <span className="inline-block px-5 py-2 rounded-full bg-primary/10 text-primary text-xs font-extrabold tracking-widest uppercase mb-8">
                    Vì một thành phố thông minh
                </span>
                <h1 className="font-headline text-6xl md:text-7xl font-extrabold leading-[1.1] text-on-surface mb-8 tracking-tight">
                    Cùng nhau xây dựng <span className="text-primary">thành phố</span> tốt đẹp hơn
                </h1>
                <p className="text-xl text-on-surface-variant max-w-xl mb-12 leading-relaxed font-medium">
                    Báo cáo sự cố đô thị nhanh chóng, minh bạch. Tiếng nói của bạn giúp hạ tầng thành phố hoàn thiện hơn mỗi ngày.
                </p>
                <div className="flex flex-col sm:flex-row gap-5">
                    <button className="px-10 py-5 bg-primary text-white rounded-full font-bold text-lg shadow-2xl shadow-primary/30 hover:scale-[1.05] active:scale-[0.95] transition-all">
                        Gửi báo cáo ngay
                    </button>
                    <button className="px-10 py-5 bg-white text-on-surface rounded-full font-bold text-lg shadow-xl border border-primary/10 hover:bg-surface-container-high transition-all flex items-center justify-center gap-3">
                        Xem bản đồ sự cố
                        <ArrowRight size={20} />
                    </button>
                </div>
            </motion.div>

            <motion.div
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.8, delay: 0.2 }}
                className="lg:col-span-5 relative"
            >
                <div className="relative w-full aspect-[4/5] rounded-[4rem] overflow-hidden shadow-2xl border border-white">
                    <img
                        alt="Modern City Life"
                        className="w-full h-full object-cover"
                        src="https://images.unsplash.com/photo-1449824913935-59a10b8d2000?auto=format&fit=crop&q=80&w=1000"
                        referrerPolicy="no-referrer"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-primary/20 to-transparent"></div>
                </div>

                {/* Floating Card */}
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.6, delay: 0.8 }}
                    className="absolute -bottom-6 -left-12 bg-white/90 backdrop-blur-2xl p-8 rounded-[2.5rem] shadow-2xl max-w-xs hidden md:block border border-white"
                >
                    <div className="flex items-center gap-4 mb-4">
                        <div className="w-12 h-12 rounded-2xl bg-primary/10 flex items-center justify-center text-primary">
                            <CheckCircle2 size={24} />
                        </div>
                        <div>
                            <p className="text-xs text-on-surface-variant font-bold uppercase tracking-wider">Sự cố mới nhất</p>
                            <p className="font-extrabold text-base">Hố ga đã được xử lý</p>
                        </div>
                    </div>
                    <p className="text-sm text-on-surface-variant font-medium">Phường Bến Nghé, Quận 1 • 15 phút trước</p>
                </motion.div>
            </motion.div>
        </div>

        {/* Abstract background shape */}
        <div className="absolute top-0 right-0 -z-10 w-1/2 h-full bg-gradient-to-bl from-primary/5 to-transparent rounded-bl-[200px]"></div>
    </section>
);
export default Hero;