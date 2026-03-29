import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { useAuth, AuthProvider } from "./contexts/AuthContext";
import { Toaster } from "react-hot-toast";

// Pages
import Login from "./pages/auth/Login";
import Register from "./pages/auth/Register";
import VerifyEmail from "./pages/auth/VerifyEmail";


// Citizen Pages
import CitizenDashboard from "./pages/citizen/DashboardCitizen";
import CitizenReportDetails from "./pages/citizen/ReportDetails";
import SubmitReport from "./pages/citizen/SubmitReport";

// Staff Pages
import StaffDashboard from "./pages/staff/DashboardStaff";
import StaffReportDetails from "./pages/staff/ReportDetails";

// Manager & Admin Pages
import ManagerDashboard from "./pages/manager/Dashboard";
import AdminDashboard from "./pages/admin/Dashboard";
import Home from "./pages/Home";
import UsersTab from "./pages/admin/components/UsersTab";
import CategoriesTab from "./pages/admin/components/CategoriesTab";
import HeaderManager from "./pages/manager/HeaderManager";

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
      <Route path="/dashboard-citizen" element={<CitizenDashboard />} />
      {/* Public Landing or Protected Dashboard Redirect */}
      <Route
        path="/"
        element={
          isAuthenticated ? (
            user?.role === "citizen" ? <Navigate to="/citizen" replace /> :
              user?.role === "manager" ? <Navigate to="/manager" replace /> :
                user?.role === "admin" ? <Navigate to="/admin/users" replace /> :
                  <Navigate to="/staff" replace />
          ) : (
            <Home />
          )
        }
      />

      {/* Role-based base routes */}
      <Route
        path="/citizen"
        element={
          <ProtectedRoute allowedRoles={["citizen"]}>
            <CitizenDashboard />
          </ProtectedRoute>
        }
      />
      <Route
        path="/manager"
        element={
          <ProtectedRoute allowedRoles={["manager"]}>
            <HeaderManager />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/manager/dashboard" replace />} />
        <Route path="dashboard" element={<ManagerDashboard />} />
      </Route>
      <Route
        path="/staff"
        element={
          <ProtectedRoute allowedRoles={["staff"]}>
            <StaffDashboard />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/staff" replace />} />
      </Route>
      {/* Admin nested routes */}
      <Route
        path="/admin"
        element={
          <ProtectedRoute allowedRoles={["admin"]}>
            <AdminDashboard />
          </ProtectedRoute>
        }
      >
        <Route index element={<Navigate to="/admin/users" replace />} />
        <Route path="users" element={<UsersTab />} />
        <Route path="categories" element={<CategoriesTab />} />
      </Route>

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
