import { MousePointerClick, Radio, Zap } from "lucide-react";
import { motion } from "motion/react";

const Features = () => (
    <section className="py-24 bg-surface-container-low">
        <div className="max-w-7xl mx-auto px-6">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                {[
                    {
                        icon: <Radio size={32} />,
                        title: "Theo dõi trực tiếp",
                        desc: "Cập nhật trạng thái xử lý sự cố theo thời gian thực. Nhận thông báo ngay khi vấn đề của bạn được tiếp nhận và giải quyết.",
                        color: "bg-primary/10 text-primary"
                    },
                    {
                        icon: <Zap size={32} />,
                        title: "Phản hồi nhanh chóng",
                        desc: "Quy trình tự động hóa giúp thông tin đến đúng cơ quan chức năng trong vài giây, rút ngắn 50% thời gian phản hồi truyền thống.",
                        color: "bg-orange-500/10 text-orange-600"
                    },
                    {
                        icon: <MousePointerClick size={32} />,
                        title: "Dễ dàng sử dụng",
                        desc: "Giao diện tối giản, trực quan giúp mọi công dân ở mọi lứa tuổi đều có thể gửi báo cáo chỉ với 3 bước chạm đơn giản.",
                        color: "bg-blue-500/10 text-blue-600"
                    }
                ].map((feature, i) => (
                    <motion.div
                        key={i}
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.5, delay: i * 0.1 }}
                        viewport={{ once: true }}
                        className="bg-surface-container-lowest p-10 rounded-[3rem] shadow-xl border border-primary/5 hover:translate-y-[-8px] transition-all duration-500 group"
                    >
                        <div className={`w-16 h-16 ${feature.color} rounded-[1.5rem] flex items-center justify-center mb-8 group-hover:scale-110 group-hover:rotate-6 transition-transform duration-500`}>
                            {feature.icon}
                        </div>
                        <h3 className="font-headline text-2xl font-bold mb-4 text-on-surface">{feature.title}</h3>
                        <p className="text-on-surface-variant leading-relaxed font-medium">
                            {feature.desc}
                        </p>
                    </motion.div>
                ))}
            </div>
        </div>
    </section>
);
export default Features;