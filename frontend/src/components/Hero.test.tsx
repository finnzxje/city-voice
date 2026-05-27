import { render, screen } from "@testing-library/react";
import Hero from "./Hero";

jest.mock("motion/react", () => ({
  motion: {
    div: ({ children, ...props }: React.HTMLAttributes<HTMLDivElement>) => (
      <div {...props}>{children}</div>
    ),
  },
}));

describe("Hero", () => {
  it("renders the CityVoice landing message and primary actions", () => {
    render(<Hero />);

    expect(
      screen.getByRole("heading", {
        name: /cùng nhau xây dựng thành phố tốt đẹp hơn/i,
      }),
    ).toBeInTheDocument();
    expect(screen.getByText(/báo cáo sự cố đô thị nhanh chóng/i)).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /gửi báo cáo ngay/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /xem bản đồ sự cố/i })).toBeInTheDocument();
  });

  it("renders the hero image and latest incident card", () => {
    render(<Hero />);

    expect(screen.getByRole("img", { name: /modern city life/i })).toBeInTheDocument();
    expect(screen.getByText(/sự cố mới nhất/i)).toBeInTheDocument();
    expect(screen.getByText(/hố ga đã được xử lý/i)).toBeInTheDocument();
  });
});
