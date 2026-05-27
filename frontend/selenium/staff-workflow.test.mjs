import assert from "node:assert/strict";
import { createServer } from "node:http";
import { mkdtemp, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { Builder, By, until } from "selenium-webdriver";
import chrome from "selenium-webdriver/chrome.js";

const APP_URL = process.env.SELENIUM_BASE_URL ?? "http://127.0.0.1:5173";
const MOCK_API_PORT = Number(process.env.SELENIUM_MOCK_API_PORT ?? 18080);
const USE_MOCK_API = process.env.SELENIUM_USE_MOCK_API !== "false";
const HEADLESS = process.env.SELENIUM_HEADLESS === "true";
const STEP_DELAY_MS = Number(process.env.SELENIUM_STEP_DELAY_MS ?? 900);
const PAUSE_MS = Number(process.env.SELENIUM_PAUSE_MS ?? 5000);

const staffUser = {
  id: "staff-1",
  email: "staff@example.com",
  fullName: "Tran Thi Staff",
  role: "staff",
  isActive: true,
};

const report = {
  id: "staff-report-1",
  title: "Cột đèn giao thông bị hỏng",
  description: "Cột đèn tại giao lộ nhấp nháy liên tục, gây nguy hiểm cho người đi đường.",
  categoryName: "Hệ thống chiếu sáng",
  latitude: 10.7769,
  longitude: 106.7009,
  administrativeZoneName: "Quận 1",
  incidentImageUrl: "",
  currentStatus: "newly_received",
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
  citizenId: "citizen-1",
  citizenName: "Nguyen Van A",
  citizenPhone: "0900000000",
  priority: undefined,
  assignedToId: undefined,
  assignedToName: undefined,
  resolutionImageUrl: undefined,
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
  if (!USE_MOCK_API) {
    return undefined;
  }

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
          accessToken: "selenium-staff-access-token",
          refreshToken: "selenium-staff-refresh-token",
        },
      });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/auth/me") {
      sendJson(res, 200, { data: staffUser });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/reports") {
      sendJson(res, 200, {
        data: {
          content: [report],
          totalPages: 1,
        },
      });
      return;
    }

    if (req.method === "GET" && url.pathname === `/api/reports/${report.id}`) {
      sendJson(res, 200, { data: report });
      return;
    }

    if (req.method === "PUT" && url.pathname === `/api/reports/${report.id}/review`) {
      const body = JSON.parse((await readRequestBody(req)).toString() || "{}");

      report.currentStatus = "in_progress";
      report.priority = body.priority ?? "medium";
      report.assignedToId = staffUser.id;
      report.assignedToName = staffUser.fullName;
      report.updatedAt = new Date().toISOString();

      sendJson(res, 200, { data: report });
      return;
    }

    if (req.method === "PUT" && url.pathname === `/api/reports/${report.id}/reject`) {
      await readRequestBody(req);

      report.currentStatus = "rejected";
      report.updatedAt = new Date().toISOString();

      sendJson(res, 200, { data: report });
      return;
    }

    if (req.method === "POST" && url.pathname === `/api/reports/${report.id}/resolve`) {
      await readRequestBody(req);

      report.currentStatus = "resolved";
      report.resolutionImageUrl = "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&q=80&w=600";
      report.updatedAt = new Date().toISOString();

      sendJson(res, 200, { data: report });
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
  if (!server) {
    return;
  }

  await new Promise((resolve, reject) => {
    server.close((error) => (error ? reject(error) : resolve()));
  });
}

async function createDriver() {
  const options = new chrome.Options();

  if (HEADLESS) {
    options.addArguments("--headless=new");
  }

  options.addArguments(
    "--disable-dev-shm-usage",
    "--no-sandbox",
    "--window-size=1440,950",
  );

  return new Builder().forBrowser("chrome").setChromeOptions(options).build();
}

async function createUploadImage() {
  const dir = await mkdtemp(join(tmpdir(), "cityvoice-staff-selenium-"));
  const filePath = join(dir, "proof.png");
  const pngBase64 =
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADggF9Hc3XWQAAAABJRU5ErkJggg==";

  await writeFile(filePath, Buffer.from(pngBase64, "base64"));
  return filePath;
}

async function slowStep(driver, label) {
  console.log(`Step: ${label}`);

  if (STEP_DELAY_MS > 0) {
    await driver.sleep(STEP_DELAY_MS);
  }
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
      const proto = element instanceof HTMLTextAreaElement
        ? HTMLTextAreaElement.prototype
        : HTMLInputElement.prototype;
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

async function runStaffFlow() {
  const mockApi = await startMockApi();
  const driver = await createDriver();

  try {
    await driver.get(`${APP_URL}/login`);
    await slowStep(driver, "Opened login page");

    await clickByText(driver, "Cán bộ");
    await slowStep(driver, "Selected staff login tab");

    await fillInput(driver, By.css("input[type='email']"), staffUser.email);
    await slowStep(driver, "Entered staff email");

    await fillInput(driver, By.css("input[type='password']"), "password123");
    await slowStep(driver, "Entered staff password");

    await clickByText(driver, "Đăng nhập Hệ thống");
    await slowStep(driver, "Submitted staff login");

    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Quản lý báo cáo sự cố')]")), 10000);
    await driver.wait(until.elementLocated(By.xpath(`//*[contains(normalize-space(.), '${report.title}')]`)), 10000);
    await slowStep(driver, "Staff report list is visible");

    const detailButton = await driver.wait(
      until.elementLocated(By.xpath(`//tr[.//*[contains(normalize-space(.), '${report.title}')]]//button[@title='Xem chi tiết']`)),
      10000,
    );
    await driver.executeScript("arguments[0].scrollIntoView({ block: 'center' });", detailButton);
    await detailButton.click();
    await slowStep(driver, "Opened report details");

    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Chi tiết sự cố')]")), 10000);
    await driver.wait(until.elementLocated(By.xpath(`//*[contains(normalize-space(.), '${report.title}')]`)), 10000);

    await clickByText(driver, "cao");
    await slowStep(driver, "Selected high priority");

    await clickByText(driver, "Duyệt & Phân công");
    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Đang xử lý')]")), 10000);
    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Nghiệm thu')]")), 10000);
    await slowStep(driver, "Accepted report and moved to in_progress");

    const proofPath = await createUploadImage();
    const proofInput = await driver.wait(until.elementLocated(By.css("input[type='file']")), 10000);
    await driver.executeScript(
      "arguments[0].classList.remove('hidden'); arguments[0].style.display = 'block';",
      proofInput,
    );
    await proofInput.sendKeys(proofPath);
    await slowStep(driver, "Uploaded resolution proof image");

    await setReactFieldValue(driver, By.css("textarea[placeholder*='Ghi chú hoàn thành']"), "Đã thay thế bóng đèn và kiểm tra tín hiệu.");
    await slowStep(driver, "Entered resolution note");

    await clickByText(driver, "Hoàn thành & Đóng hồ sơ");
    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Đã giải quyết')]")), 10000);
    await slowStep(driver, "Resolved report");

    const bodyText = await driver.findElement(By.css("body")).getText();
    assert.match(bodyText, /Cột đèn giao thông bị hỏng/);
    assert.match(bodyText, /Đã giải quyết/);
    assert.match(bodyText, /ẢNH NGHIỆM THU/);

    if (PAUSE_MS > 0) {
      await driver.sleep(PAUSE_MS);
    }

    console.log("Selenium staff flow passed: login, accept, assign, and resolve completed.");
  } catch (error) {
    const currentUrl = await driver.getCurrentUrl();
    const bodyText = await driver.findElement(By.css("body")).getText().catch(() => "");

    console.error(`Selenium staff flow failed at URL: ${currentUrl}`);
    console.error(bodyText.slice(0, 2500));
    throw error;
  } finally {
    await driver.quit();
    await stopMockApi(mockApi);
  }
}

runStaffFlow().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
