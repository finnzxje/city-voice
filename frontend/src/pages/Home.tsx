import { Navigate } from "react-router-dom";
import Footer from "../components/Footer";
import Features from "../components/Features";
import Header from "../components/Header";
import Hero from "../components/Hero";
import MapSection from "../components/MapSection";
import Stats from "../components/Stats";
import { useAuth } from "../contexts/AuthContext";

const Home = () => {
    const { isAuthenticated, isLoading } = useAuth();

    if (isLoading) {
        return (
            <div className="h-screen w-full flex items-center justify-center bg-gray-50 text-gray-500">
                Loading CityVoice...
            </div>
        );
    }

    if (isAuthenticated) {
        return <Navigate to="/" replace />;
    }
    return (<div className="min-h-screen">
        <Header />
        <main>
            <Hero />
            <Features />
            <MapSection />
            <Stats />
        </main>
        <Footer />
    </div>)
}
export default Home;