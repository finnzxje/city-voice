import { render, screen } from "@testing-library/react";
import Stats from "./Stats";

describe("Stats", () => {
  it("renders community impact metrics", () => {
    render(<Stats />);

    expect(screen.getByRole("heading", { name: /kết quả từ cộng đồng/i })).toBeInTheDocument();
    expect(screen.getByText("12,4k+")).toBeInTheDocument();
    expect(screen.getByText("98%")).toBeInTheDocument();
    expect(screen.getByText("<24h")).toBeInTheDocument();
  });
});
