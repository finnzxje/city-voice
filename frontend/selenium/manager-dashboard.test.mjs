import assert from "node:assert/strict";
import { createServer } from "node:http";
import { Builder, By, until } from "selenium-webdriver";
import chrome from "selenium-webdriver/chrome.js";

const APP_URL = process.env.SELENIUM_BASE_URL ?? "http://127.0.0.1:5173";
const MOCK_API_PORT = Number(process.env.SELENIUM_MOCK_API_PORT ?? 18080);
const USE_MOCK_API = process.env.SELENIUM_USE_MOCK_API !== "false";
const HEADLESS = process.env.SELENIUM_HEADLESS === "true";
const STEP_DELAY_MS = Number(process.env.SELENIUM_STEP_DELAY_MS ?? 900);
const PAUSE_MS = Number(process.env.SELENIUM_PAUSE_MS ?? 5000);

const managerUser = {
  id: "manager-1",
  email: "manager@example.com",
  fullName: "Le Thi Manager",
  role: "manager",
  isActive: true,
};

const stats = {
  totalReports: 24,
  newlyReceived: 6,
  inProgress: 8,
  resolved: 9,
  rejected: 1,
  completionRate: 37.5,
  averageResolutionHours: 18.4,
  byCategory: {
    "Hạ tầng đường bộ": 10,
    "Hệ thống chiếu sáng": 8,
    "Vệ sinh môi trường": 6,
  },
  byPriority: {
    critical: 2,
    high: 7,
    medium: 10,
    low: 5,
  },
  byZone: {
    "Quận 1": 9,
    "Thành phố Thủ Đức": 7,
    "Quận Bình Thạnh": 5,
  },
};

const heatmapPoints = [
  { latitude: 10.7769, longitude: 106.7009, priority: "high", category: "Hạ tầng đường bộ" },
  { latitude: 10.7829, longitude: 106.7069, priority: "critical", category: "Hệ thống chiếu sáng" },
];

function readRequestBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });
}

function sendJson(res, status, body) {
  res.writeHead(status, {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Allow-Methods": "GET, POST, PUT, OPTIONS",
    "Content-Type": "application/json",
  });
  res.end(JSON.stringify(body));
}

function sendBinary(res, type) {
  res.writeHead(200, {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Allow-Methods": "GET, POST, PUT, OPTIONS",
    "Content-Type": type === "excel"
      ? "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      : "application/pdf",
    "Content-Disposition": `attachment; filename="cityvoice-manager.${type === "excel" ? "xlsx" : "pdf"}"`,
  });
  res.end(Buffer.from("cityvoice-export"));
}

async function startMockApi() {
  if (!USE_MOCK_API) return undefined;

  const server = createServer(async (req, res) => {
    if (req.method === "OPTIONS") {
      sendJson(res, 204, {});
      return;
    }

    const url = new URL(req.url ?? "/", `http://127.0.0.1:${MOCK_API_PORT}`);
    console.log(`Mock API: ${req.method} ${url.pathname}`);

    if (req.method === "POST" && url.pathname === "/api/auth/staff/login") {
      await readRequestBody(req);
      sendJson(res, 200, {
        data: {
          accessToken: "selenium-manager-access-token",
          refreshToken: "selenium-manager-refresh-token",
        },
      });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/auth/me") {
      sendJson(res, 200, { data: managerUser });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/categories") {
      sendJson(res, 200, {
        data: [
          { id: 1, name: "Hạ tầng đường bộ", slug: "road", iconKey: "Cone", active: true },
          { id: 2, name: "Hệ thống chiếu sáng", slug: "lighting", iconKey: "Zap", active: true },
        ],
      });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/analytics/stats") {
      sendJson(res, 200, { data: stats });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/analytics/heatmap") {
      sendJson(res, 200, { data: heatmapPoints });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/analytics/export/excel") {
      sendBinary(res, "excel");
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/analytics/export/pdf") {
      sendBinary(res, "pdf");
      return;
    }

    sendJson(res, 404, { message: `No mock route for ${req.method} ${url.pathname}` });
  });

  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(MOCK_API_PORT, "127.0.0.1", resolve);
  });

  console.log(`Mock API is running at http://127.0.0.1:${MOCK_API_PORT}/api`);
  return server;
}

async function stopMockApi(server) {
  if (!server) return;

  await new Promise((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
}

async function createDriver() {
  const options = new chrome.Options();
  if (HEADLESS) options.addArguments("--headless=new");
  options.addArguments("--disable-dev-shm-usage", "--no-sandbox", "--window-size=1440,950");
  return new Builder().forBrowser("chrome").setChromeOptions(options).build();
}

async function slowStep(driver, label) {
  console.log(`Step: ${label}`);
  if (STEP_DELAY_MS > 0) await driver.sleep(STEP_DELAY_MS);
}

async function fillInput(driver, locator, value) {
  const element = await driver.wait(until.elementLocated(locator), 10000);
  await driver.wait(until.elementIsVisible(element), 5000);
  await element.clear();
  await element.click();
  await element.sendKeys(value);
}

async function clickByText(driver, text) {
  const element = await driver.wait(
    until.elementLocated(By.xpath(`//*[self::button or self::a][contains(normalize-space(.), '${text}')]`)),
    10000,
  );
  await driver.wait(until.elementIsVisible(element), 5000);
  await driver.executeScript("arguments[0].scrollIntoView({ block: 'center' });", element);
  await element.click();
}

async function runManagerFlow() {
  const mockApi = await startMockApi();
  const driver = await createDriver();

  try {
    await driver.get(`${APP_URL}/login`);
    await slowStep(driver, "Opened login page");

    await clickByText(driver, "Cán bộ");
    await slowStep(driver, "Selected internal login tab");

    await fillInput(driver, By.css("input[type='email']"), managerUser.email);
    await slowStep(driver, "Entered manager email");

    await fillInput(driver, By.css("input[type='password']"), "password123");
    await slowStep(driver, "Entered manager password");

    await clickByText(driver, "Đăng nhập Hệ thống");
    await slowStep(driver, "Submitted manager login");

    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Tổng quan Phân tích')]")), 10000);
    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Dữ liệu sự cố toàn thành phố Hồ Chí Minh')]")), 10000);
    await slowStep(driver, "Manager analytics dashboard is visible");

    let bodyText = await driver.findElement(By.css("body")).getText();
    assert.match(bodyText, /Sự cố phát sinh/);
    assert.match(bodyText, /Tỷ lệ hoàn thành/);
    assert.match(bodyText, /TG giải quyết trung bình/);
    assert.match(bodyText, /Đang được xử lý/);
    assert.match(bodyText, /Top Khu vực/);
    assert.match(bodyText, /Mức độ Ưu tiên/);

    await clickByText(driver, "Bộ lọc");
    await slowStep(driver, "Opened manager filters");

    const prioritySelect = await driver.wait(
      until.elementLocated(By.xpath("//label[contains(normalize-space(.), 'Mức độ ưu tiên')]/following-sibling::select")),
      10000,
    );
    await prioritySelect.findElement(By.css("option[value='high']")).click();
    await slowStep(driver, "Applied high priority filter");

    await clickByText(driver, "Excel");
    await slowStep(driver, "Triggered Excel export");

    await clickByText(driver, "PDF");
    await slowStep(driver, "Triggered PDF export");

    bodyText = await driver.findElement(By.css("body")).getText();
    assert.match(bodyText, /Tổng quan Phân tích/);
    assert.match(bodyText, /Phân bố Trạng thái/);
    assert.match(bodyText, /Hạ tầng đường bộ/);

    if (PAUSE_MS > 0) await driver.sleep(PAUSE_MS);

    console.log("Selenium manager flow passed: analytics, filters, and exports completed.");
  } catch (error) {
    const currentUrl = await driver.getCurrentUrl();
    const bodyText = await driver.findElement(By.css("body")).getText().catch(() => "");
    console.error(`Selenium manager flow failed at URL: ${currentUrl}`);
    console.error(bodyText.slice(0, 2500));
    throw error;
  } finally {
    await driver.quit();
    await stopMockApi(mockApi);
  }
}

runManagerFlow().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
