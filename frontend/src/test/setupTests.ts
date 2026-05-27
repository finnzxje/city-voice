import "@testing-library/jest-dom";
import { TextDecoder, TextEncoder } from "node:util";

if (typeof globalThis.TextEncoder === "undefined") {
  globalThis.TextEncoder = TextEncoder;
  globalThis.TextDecoder = TextDecoder as typeof globalThis.TextDecoder;
}
