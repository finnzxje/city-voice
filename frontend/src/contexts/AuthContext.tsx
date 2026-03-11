import {
  createContext,
  useContext,
  useState,
  useEffect,
  type ReactNode,
} from "react";
import { AuthAPI, type UserInfo } from "../api/services";

interface AuthContextType {
  user: UserInfo | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (
    tokens: { accessToken: string; refreshToken: string },
    userData?: UserInfo,
  ) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<UserInfo | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchUser = async () => {
      const accessToken = localStorage.getItem("accessToken");
      if (accessToken) {
        try {
          const res = await AuthAPI.getMe();
          setUser(res.data);
        } catch (error) {
          console.error("Failed to fetch user info", error);
        }
      }
      setIsLoading(false);
    };

    fetchUser();
  }, []);

  const login = async (
    tokens: { accessToken: string; refreshToken: string },
    userData?: UserInfo,
  ) => {
    localStorage.setItem("accessToken", tokens.accessToken);
    localStorage.setItem("refreshToken", tokens.refreshToken);
    if (userData) {
      setUser(userData);
    } else {
      // Fetch user info if not provided
      try {
        const res = await AuthAPI.getMe();
        setUser(res.data);
      } catch (error) {
        console.error(error);
      }
    }
  };

  const logout = async () => {
    const refreshToken = localStorage.getItem("refreshToken");
    if (refreshToken) {
      try {
        await AuthAPI.logout(refreshToken);
      } catch (e) {
        console.error("Logout failed on server", e);
      }
    }
    localStorage.removeItem("accessToken");
    localStorage.removeItem("refreshToken");
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
        isLoading,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};
