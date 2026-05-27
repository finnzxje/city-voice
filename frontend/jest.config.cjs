module.exports = {
  clearMocks: true,
  collectCoverageFrom: [
    "src/**/*.{ts,tsx}",
    "!src/**/*.d.ts",
    "!src/main.tsx",
  ],
  moduleFileExtensions: ["ts", "tsx", "js", "jsx"],
  moduleNameMapper: {
    "\\.(css|less|scss|sass)$": "identity-obj-proxy",
    "\\.(gif|jpg|jpeg|png|svg|webp)$": "<rootDir>/src/test/__mocks__/fileMock.ts",
  },
  setupFilesAfterEnv: ["<rootDir>/src/test/setupTests.ts"],
  testEnvironment: "jsdom",
  testMatch: ["<rootDir>/src/**/*.test.{ts,tsx}"],
  transform: {
    "^.+\\.(ts|tsx)$": [
      "ts-jest",
      {
        diagnostics: false,
        tsconfig: "tsconfig.jest.json",
      },
    ],
  },
};
