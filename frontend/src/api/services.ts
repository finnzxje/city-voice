import { apiClient } from "./axiosClient";

export interface Category {
  id: number;
  name: string;
  slug: string;
  iconKey: string;
}

export interface ReportResponse {
  id: string;
  title: string;
  description: string;
  categoryName: string;
  latitude: number;
  longitude: number;
  administrativeZoneName: string;
  incidentImageUrl: string;
  currentStatus: string;
  createdAt: string;
  priority?: "low" | "medium" | "high" | "critical";
  citizenId?: string;
  citizenName?: string;
  assignedToId?: string;
  assignedToName?: string;
}

export interface UserInfo {
  id: string;
  email: string;
  fullName: string;
  role: "citizen" | "staff" | "manager" | "admin";
  isActive: boolean;
}
interface ApiResponse<T> {
  data: T;
}

export const AuthAPI = {
  // Citizen Register
  registerCitizen: (data: any) =>
    apiClient.post("/auth/citizen/register", data),
  verifyEmail: (data: { email: string; otp: string }) =>
    apiClient.post("/auth/citizen/verify-email", data),
  resendVerification: (data: { email: string }) =>
    apiClient.post("/auth/citizen/resend-verification", data),

  // Citizen Login (Password)
  loginCitizenPassword: (data: any) =>
    apiClient.post("/auth/citizen/login", data),

  // Citizen Login (OTP)
  requestOtpLogin: (data: { email: string }) =>
    apiClient.post("/auth/citizen/request-otp", data),
  verifyOtpLogin: (data: { email: string; otp: string }) =>
    apiClient.post("/auth/citizen/verify-otp", data),

  // Staff Login
  loginStaff: (data: any) => apiClient.post("/auth/staff/login", data),

  // Get Me
  getMe: () => apiClient.get<ApiResponse<UserInfo>>("/auth/me"),

  // Logout
  logout: (refreshToken: string) =>
    apiClient.post("/auth/logout", { refreshToken }),
};

export const IncidentAPI = {
  getCategories: () => apiClient.get<ApiResponse<Category[]>>("/categories"),

  submitReport: (formData: FormData) =>
    apiClient.post("/reports", formData, {
      headers: { "Content-Type": "multipart/form-data" },
    }),

  getMyReports: () =>
    apiClient.get<ApiResponse<ReportResponse[]>>("/reports/my"),

  getAllReports: (params?: any) =>
    apiClient.get<ApiResponse<{ content: ReportResponse[]; totalPages: number }>>(
      "/reports",
      { params },
    ),

  getReportById: (id: string) =>
    apiClient.get<ApiResponse<ReportResponse>>(`/reports/${id}`),

  reviewReport: (
    id: string,
    data: { priority: string; assignedTo: string; note?: string },
  ) => apiClient.put(`/reports/${id}/review`, data),

  rejectReport: (id: string, data: { note: string }) =>
    apiClient.put(`/reports/${id}/reject`, data),

  resolveReport: (id: string, formData: FormData) =>
    apiClient.post(`/reports/${id}/resolve`, formData, {
      headers: { "Content-Type": "multipart/form-data" },
    }),
};

export interface HeatmapPoint {
  latitude: number;
  longitude: number;
  priority: string;
  category: string;
}

export interface AnalyticsStats {
  totalReports: number;
  newlyReceived: number;
  inProgress: number;
  resolved: number;
  rejected: number;
  completionRate: number;
  averageResolutionHours: number;
  byCategory: Record<string, number>;
  byPriority: Record<string, number>;
  byZone: Record<string, number>;
}

export const AnalyticsAPI = {
  getHeatmap: (params?: any) => 
    apiClient.get<ApiResponse<HeatmapPoint[]>>("/analytics/heatmap", { params }),

  getStats: (params?: any) => 
    apiClient.get<ApiResponse<AnalyticsStats>>("/analytics/stats", { params }),
};

export const AdminAPI = {
  getRoles: () => apiClient.get<ApiResponse<string[]>>("/admin/roles"),
  getUsers: () => apiClient.get<ApiResponse<UserInfo[]>>("/admin/users"),
  updateUserRole: (userId: string, role: string) => 
    apiClient.put(`/admin/users/${userId}/role`, { role }),
    
  createCategory: (data: { name: string; slug: string; iconKey: string; active?: boolean }) => 
    apiClient.post("/categories", data),
  updateCategory: (id: number, data: Partial<{ name: string; slug: string; iconKey: string; active: boolean }>) => 
    apiClient.put(`/categories/${id}`, data)
};

