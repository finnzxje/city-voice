import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import Header from "./Header";
import { useAuth } from "../contexts/AuthContext";

jest.mock("../contexts/AuthContext", () => ({
  useAuth: jest.fn(),
}));

const mockUseAuth = jest.mocked(useAuth);

describe("Header", () => {
  it("shows guest navigation links when there is no authenticated user", () => {
    mockUseAuth.mockReturnValue({
      user: null,
      isAuthenticated: false,
      isLoading: false,
      login: jest.fn(),
      logout: jest.fn(),
    });

    render(
      <MemoryRouter>
        <Header />
      </MemoryRouter>,
    );

    expect(screen.getByRole("link", { name: /cityvoice/i })).toHaveAttribute("href", "/");
    expect(screen.getByRole("link", { name: /đăng nhập/i })).toHaveAttribute("href", "/login");
    expect(screen.getByRole("link", { name: /đăng ký/i })).toHaveAttribute("href", "/register");
  });

  it("shows citizen links and logs out authenticated users", async () => {
    const logout = jest.fn();
    mockUseAuth.mockReturnValue({
      user: {
        id: "user-1",
        email: "citizen@example.com",
        fullName: "Nguyen Van A",
        role: "citizen",
        isActive: true,
      },
      isAuthenticated: true,
      isLoading: false,
      login: jest.fn(),
      logout,
    });

    render(
      <MemoryRouter>
        <Header />
      </MemoryRouter>,
    );

    expect(screen.getByRole("link", { name: /tổng quan/i })).toHaveAttribute(
      "href",
      "/citizen/dashboard",
    );
    expect(screen.getByRole("link", { name: /báo cáo/i })).toHaveAttribute(
      "href",
      "/reports/new",
    );
    expect(screen.getByText("Nguyen Van A")).toBeInTheDocument();

    await userEvent.click(screen.getByRole("button", { name: /đăng xuất/i }));

    expect(logout).toHaveBeenCalledTimes(1);
  });
});
