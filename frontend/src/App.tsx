import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { useAuth, AuthProvider } from "./contexts/AuthContext";
import { Toaster } from "react-hot-toast";

// Pages
import Login from "./pages/auth/Login";
import Register from "./pages/auth/Register";
import VerifyEmail from "./pages/auth/VerifyEmail";
import Landing from "./pages/Landing";

// Citizen Pages
import CitizenDashboard from "./pages/citizen/Dashboard";
import CitizenReportDetails from "./pages/citizen/ReportDetails";
import SubmitReport from "./pages/citizen/SubmitReport";

// Staff Pages
import StaffDashboard from "./pages/staff/Dashboard";
import StaffReportDetails from "./pages/staff/ReportDetails";

const ProtectedRoute = ({
  children,
  allowedRoles,
}: {
  children: React.ReactNode;
  allowedRoles?: string[];
}) => {
  const { user, isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="h-screen w-full flex items-center justify-center bg-gray-50 text-gray-500">
        Đang tải CityVoice...
      </div>
    );
  }

  if (!isAuthenticated || !user) {
    return <Navigate to="/login" />;
  }

  if (allowedRoles && !allowedRoles.includes(user.role)) {
    return <Navigate to="/" />; // Or unauthorized page
  }

  return <>{children}</>;
};

function AppRoutes() {
  const { user, isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="h-screen w-full flex items-center justify-center bg-gray-50 text-gray-500">
        Đang tải CityVoice...
      </div>
    );
  }

  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />
      <Route path="/verify-email" element={<VerifyEmail />} />

      {/* Public Landing or Protected Dashboard */}
      <Route 
        path="/" 
        element={
          isAuthenticated ? (
            user?.role === "citizen" ? <CitizenDashboard /> : <StaffDashboard />
          ) : (
            <Landing />
          )
        } 
      />

      <Route
        path="/reports/new"
        element={
          <ProtectedRoute allowedRoles={["citizen"]}>
            <SubmitReport />
          </ProtectedRoute>
        }
      />

      <Route
        path="/reports/:id"
        element={
          <ProtectedRoute>
            {user?.role === "citizen" ? <CitizenReportDetails /> : <StaffReportDetails />}
          </ProtectedRoute>
        }
      />

      <Route path="*" element={<Navigate to="/" />} />
    </Routes>
  );
}

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <div className="min-h-screen bg-gray-50 text-gray-900 font-sans">
          <Toaster position="top-right" />
          <AppRoutes />
        </div>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
