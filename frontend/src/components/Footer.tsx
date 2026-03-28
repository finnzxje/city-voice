import { Building2, Globe, Mail, MapPin, Phone, Share2 } from "lucide-react";

const Footer = () => (
    <footer className="bg-surface-container-highest pt-24 pb-12">
        <div className="max-w-7xl mx-auto px-6">
            <div className="grid grid-cols-1 md:grid-cols-12 gap-16 mb-24">
                <div className="md:col-span-4">
                    <a className="flex items-center gap-3 text-2xl font-extrabold tracking-tight text-primary font-headline mb-8" href="/">
                        <div className="p-2 bg-primary rounded-2xl text-white inline-flex shadow-lg">
                            <Building2 size={24} />
                        </div>
                        CityVoice
                    </a>
                    <p className="text-on-surface-variant leading-relaxed mb-10 font-medium">
                        Nền tảng kết nối trực tiếp công dân và chính quyền đô thị, hướng tới một tương lai số minh bạch và hiệu quả.
                    </p>
                    <div className="flex gap-5">
                        {[Globe, Mail, Share2].map((Icon, i) => (
                            <a key={i} className="w-12 h-12 rounded-2xl bg-white flex items-center justify-center text-primary shadow-md hover:scale-110 hover:rotate-6 transition-all" href="#">
                                <Icon size={22} />
                            </a>
                        ))}
                    </div>
                </div>

                <div className="md:col-span-2">
                    <h5 className="font-headline font-extrabold text-sm uppercase tracking-widest mb-8 text-on-surface">Dịch vụ</h5>
                    <ul className="space-y-5 text-on-surface-variant text-sm font-bold">
                        <li><a className="hover:text-primary transition-colors" href="#">Báo cáo sự cố</a></li>
                        <li><a className="hover:text-primary transition-colors" href="#">Tra cứu hồ sơ</a></li>
                        <li><a className="hover:text-primary transition-colors" href="#">Bản đồ quy hoạch</a></li>
                        <li><a className="hover:text-primary transition-colors" href="#">Tin tức đô thị</a></li>
                    </ul>
                </div>

                <div className="md:col-span-2">
                    <h5 className="font-headline font-extrabold text-sm uppercase tracking-widest mb-8 text-on-surface">Thông tin</h5>
                    <ul className="space-y-5 text-on-surface-variant text-sm font-bold">
                        <li><a className="hover:text-primary transition-colors" href="#">Về dự án</a></li>
                        <li><a className="hover:text-primary transition-colors" href="#">Điều khoản sử dụng</a></li>
                        <li><a className="hover:text-primary transition-colors" href="#">Chính sách bảo mật</a></li>
                        <li><a className="hover:text-primary transition-colors" href="#">Hướng dẫn</a></li>
                    </ul>
                </div>

                <div className="md:col-span-4">
                    <h5 className="font-headline font-extrabold text-sm uppercase tracking-widest mb-8 text-on-surface">Liên hệ</h5>
                    <div className="space-y-6">
                        <div className="flex items-start gap-4">
                            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary shrink-0">
                                <MapPin size={20} />
                            </div>
                            <p className="text-sm text-on-surface-variant font-medium leading-relaxed">Tòa nhà Trung tâm Hành chính, Số 1 Lê Duẩn, Quận 1, TP. HCM</p>
                        </div>
                        <div className="flex items-center gap-4">
                            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary shrink-0">
                                <Phone size={20} />
                            </div>
                            <p className="text-sm text-on-surface-variant font-bold">1900 1234 (Tổng đài 24/7)</p>
                        </div>
                        <div className="flex items-center gap-4">
                            <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary shrink-0">
                                <Mail size={20} />
                            </div>
                            <p className="text-sm text-on-surface-variant font-bold">hotro@cityvoice.vn</p>
                        </div>
                    </div>
                </div>
            </div>

            <div className="pt-12 border-t border-outline-variant/20 flex flex-col md:flex-row justify-between items-center gap-6">
                <p className="text-xs text-on-surface-variant font-bold">© 2024 CityVoice - Nền tảng Thành phố Thông minh. All rights reserved.</p>
                <div className="flex items-center gap-3 bg-white/50 px-5 py-2 rounded-full border border-white/50">
                    <span className="text-xs text-on-surface-variant font-bold">Trạng thái hệ thống:</span>
                    <span className="flex items-center gap-2 text-xs font-extrabold text-emerald-600">
                        <span className="w-2 h-2 rounded-full bg-emerald-600 animate-pulse"></span>
                        Hoạt động ổn định
                    </span>
                </div>
            </div>
        </div>
    </footer>
);
export default Footer;