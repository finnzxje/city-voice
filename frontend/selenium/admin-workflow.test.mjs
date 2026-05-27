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

const adminUser = {
  id: "admin-1",
  email: "admin@example.com",
  fullName: "Pham Admin",
  role: "admin",
  isActive: true,
};

const users = [
  adminUser,
  {
    id: "citizen-1",
    email: "citizen@example.com",
    fullName: "Nguyen Van A",
    role: "citizen",
    isActive: true,
  },
  {
    id: "staff-1",
    email: "staff@example.com",
    fullName: "Tran Thi Staff",
    role: "staff",
    isActive: true,
  },
];

const categories = [
  { id: 1, name: "Hạ tầng đường bộ", slug: "road", iconKey: "Cone", active: true },
  { id: 2, name: "Hệ thống chiếu sáng", slug: "lighting", iconKey: "Zap", active: true },
];

const stats = {
  totalReports: 12,
  newlyReceived: 3,
  inProgress: 4,
  resolved: 4,
  rejected: 1,
  completionRate: 33.3,
  averageResolutionHours: 20.5,
  byCategory: { "Hạ tầng đường bộ": 7, "Hệ thống chiếu sáng": 5 },
  byPriority: { high: 4, medium: 5, low: 3 },
  byZone: { "Quận 1": 5, "Quận Bình Thạnh": 4 },
};

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
          accessToken: "selenium-admin-access-token",
          refreshToken: "selenium-admin-refresh-token",
        },
      });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/auth/me") {
      sendJson(res, 200, { data: adminUser });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/admin/roles") {
      sendJson(res, 200, { data: ["citizen", "staff", "manager", "admin"] });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/admin/users") {
      sendJson(res, 200, { data: users });
      return;
    }

    const roleMatch = url.pathname.match(/^\/api\/admin\/users\/([^/]+)\/role$/);
    if (req.method === "PUT" && roleMatch) {
      const body = JSON.parse((await readRequestBody(req)).toString() || "{}");
      const target = users.find((user) => user.id === roleMatch[1]);
      if (target) target.role = body.role;
      sendJson(res, 200, { data: target });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/categories/all") {
      sendJson(res, 200, { data: categories });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/categories") {
      sendJson(res, 200, { data: categories.filter((category) => category.active !== false) });
      return;
    }

    if (req.method === "POST" && url.pathname === "/api/categories") {
      const body = JSON.parse((await readRequestBody(req)).toString() || "{}");
      const category = {
        id: categories.length + 1,
        name: body.name,
        slug: body.slug,
        iconKey: body.iconKey || "FolderTree",
        active: body.active !== false,
      };
      categories.push(category);
      sendJson(res, 201, { data: category });
      return;
    }

    const categoryMatch = url.pathname.match(/^\/api\/categories\/(\d+)$/);
    if (req.method === "PUT" && categoryMatch) {
      const body = JSON.parse((await readRequestBody(req)).toString() || "{}");
      const target = categories.find((category) => category.id === Number(categoryMatch[1]));
      if (target) Object.assign(target, body);
      sendJson(res, 200, { data: target });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/analytics/stats") {
      sendJson(res, 200, { data: stats });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/analytics/heatmap") {
      sendJson(res, 200, { data: [] });
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

async function setReactFieldValue(driver, locator, value) {
  const element = await driver.wait(until.elementLocated(locator), 10000);
  await driver.executeScript(
    `
      const element = arguments[0];
      const value = arguments[1];
      const proto = HTMLInputElement.prototype;
      const setter = Object.getOwnPropertyDescriptor(proto, 'value').set;
      setter.call(element, value);
      element.dispatchEvent(new Event('input', { bubbles: true }));
      element.dispatchEvent(new Event('change', { bubbles: true }));
    `,
    element,
    value,
  );
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

async function runAdminFlow() {
  const mockApi = await startMockApi();
  const driver = await createDriver();

  try {
    await driver.get(`${APP_URL}/login`);
    await slowStep(driver, "Opened login page");

    await clickByText(driver, "Cán bộ");
    await slowStep(driver, "Selected internal login tab");

    await fillInput(driver, By.css("input[type='email']"), adminUser.email);
    await slowStep(driver, "Entered admin email");

    await fillInput(driver, By.css("input[type='password']"), "password123");
    await slowStep(driver, "Entered admin password");

    await clickByText(driver, "Đăng nhập Hệ thống");
    await slowStep(driver, "Submitted admin login");

    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Quản lý quyền truy cập')]")), 10000);
    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Nguyen Van A')]")), 10000);
    await slowStep(driver, "Admin users tab is visible");

    const citizenRoleButton = await driver.wait(
      until.elementLocated(By.xpath("//tr[.//*[contains(normalize-space(.), 'Nguyen Van A')]]//button[contains(normalize-space(.), 'Thay đổi vai trò')]")),
      10000,
    );
    await driver.executeScript("arguments[0].scrollIntoView({ block: 'center' });", citizenRoleButton);
    await citizenRoleButton.click();
    await slowStep(driver, "Opened role dropdown");

    const managerRoleButton = await driver.wait(
      until.elementLocated(By.xpath("//tr[.//*[contains(normalize-space(.), 'Nguyen Van A')]]//button[contains(normalize-space(.), 'MANAGER')]")),
      10000,
    );
    await managerRoleButton.click();
    await driver.wait(until.elementLocated(By.xpath("//tr[.//*[contains(normalize-space(.), 'Nguyen Van A')] and .//*[contains(normalize-space(.), 'manager')]]")), 10000);
    await slowStep(driver, "Changed citizen role to manager");

    await clickByText(driver, "Categories");
    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'CẤU TRÚC PHẢN HỒI')]")), 10000);
    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Hạ tầng đường bộ')]")), 10000);
    await slowStep(driver, "Admin categories tab is visible");

    await clickByText(driver, "Tạo danh mục mới");
    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Thêm mới danh mục')]")), 10000);
    await slowStep(driver, "Opened category modal");

    await setReactFieldValue(driver, By.xpath("//label[contains(normalize-space(.), 'Tên danh mục')]/following-sibling::input"), "Cây xanh đô thị");
    await slowStep(driver, "Entered category name");

    await setReactFieldValue(driver, By.xpath("//label[contains(normalize-space(.), 'URL Slug')]/following-sibling::div//input"), "cay-xanh-do-thi");
    await slowStep(driver, "Entered category slug");

    await setReactFieldValue(driver, By.xpath("//label[contains(normalize-space(.), 'Icon Key')]/following-sibling::input"), "TreeDeciduous");
    await slowStep(driver, "Entered category icon");

    const modalCreateButton = await driver.wait(
      until.elementLocated(By.xpath("//div[contains(@class, 'fixed')]//button[normalize-space(.)='Tạo danh mục']")),
      10000,
    );
    await driver.executeScript("arguments[0].scrollIntoView({ block: 'center' });", modalCreateButton);
    await modalCreateButton.click();
    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Cây xanh đô thị')]")), 10000);
    await slowStep(driver, "Created new category");

    const bodyText = await driver.findElement(By.css("body")).getText();
    assert.match(bodyText, /CẤU TRÚC PHẢN HỒI/);
    assert.match(bodyText, /Cây xanh đô thị/);
    assert.match(bodyText, /Hoạt động/);

    if (PAUSE_MS > 0) await driver.sleep(PAUSE_MS);

    console.log("Selenium admin flow passed: user role and category management completed.");
  } catch (error) {
    const currentUrl = await driver.getCurrentUrl();
    const bodyText = await driver.findElement(By.css("body")).getText().catch(() => "");
    console.error(`Selenium admin flow failed at URL: ${currentUrl}`);
    console.error(bodyText.slice(0, 3000));
    throw error;
  } finally {
    await driver.quit();
    await stopMockApi(mockApi);
  }
}

runAdminFlow().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
