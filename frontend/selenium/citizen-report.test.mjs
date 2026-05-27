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

const user = {
  id: "citizen-1",
  email: "citizen@example.com",
  fullName: "Nguyen Van A",
  role: "citizen",
  isActive: true,
};

const submittedReports = [];

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

    if (req.method === "POST" && url.pathname === "/api/auth/citizen/login") {
      await readRequestBody(req);
      sendJson(res, 200, {
        data: {
          accessToken: "selenium-access-token",
          refreshToken: "selenium-refresh-token",
        },
      });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/auth/me") {
      sendJson(res, 200, { data: user });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/categories") {
      sendJson(res, 200, {
        data: [
          { id: 1, name: "Hạ tầng đường bộ", slug: "road", iconKey: "road", active: true },
          { id: 2, name: "Hệ thống chiếu sáng", slug: "lighting", iconKey: "lightbulb", active: true },
        ],
      });
      return;
    }

    if (req.method === "POST" && url.pathname === "/api/reports") {
      await readRequestBody(req);

      const report = {
        id: "selenium-report-1",
        title: "Ổ gà trước cổng trường",
        description: "Mặt đường hư hỏng cần xử lý để bảo đảm an toàn.",
        categoryName: "Hạ tầng đường bộ",
        latitude: 10.7769,
        longitude: 106.7009,
        administrativeZoneName: "Quận 1",
        incidentImageUrl: "",
        currentStatus: "newly_received",
        createdAt: new Date().toISOString(),
      };

      submittedReports.splice(0, submittedReports.length, report);
      sendJson(res, 201, { data: report });
      return;
    }

    if (req.method === "GET" && url.pathname === "/api/reports/my") {
      sendJson(res, 200, { data: submittedReports });
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
    "--window-size=1366,900",
  );

  return new Builder().forBrowser("chrome").setChromeOptions(options).build();
}

async function createUploadImage() {
  const dir = await mkdtemp(join(tmpdir(), "cityvoice-selenium-"));
  const filePath = join(dir, "incident.png");
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

async function clickSubmitButton(driver) {
  const button = await driver.wait(until.elementLocated(By.css("form button[type='submit']")), 10000);

  await driver.wait(until.elementIsVisible(button), 5000);
  await driver.executeScript("arguments[0].scrollIntoView({ block: 'center' });", button);
  await driver.executeScript("arguments[0].closest('form').requestSubmit(arguments[0]);", button);
}

async function runCitizenFlow() {
  const mockApi = await startMockApi();
  const driver = await createDriver();

  try {
    await driver.get(`${APP_URL}/login`);
    await slowStep(driver, "Opened login page");

    await fillInput(driver, By.css("input[type='email']"), user.email);
    await slowStep(driver, "Entered citizen email");

    await fillInput(driver, By.css("input[type='password']"), "password123");
    await slowStep(driver, "Entered citizen password");

    await clickByText(driver, "Đăng nhập ngay");
    await slowStep(driver, "Submitted citizen login");

    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Báo cáo của tôi')]")), 10000);
    await slowStep(driver, "Citizen dashboard is visible");

    await driver.get(`${APP_URL}/reports/new`);
    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Báo cáo Sự cố mới')]")), 10000);
    await slowStep(driver, "Opened new report form");

    const uploadPath = await createUploadImage();
    const fileInput = await driver.findElement(By.css("input[type='file']"));
    await driver.executeScript(
      "arguments[0].classList.remove('sr-only'); arguments[0].style.display = 'block';",
      fileInput,
    );
    await fileInput.sendKeys(uploadPath);
    await slowStep(driver, "Uploaded evidence image");

    await setReactFieldValue(driver, By.id("title"), "Ổ gà trước cổng trường");
    await slowStep(driver, "Entered report title");

    const categorySelect = await driver.findElement(By.id("category"));
    await categorySelect.findElement(By.css("option[value='1']")).click();
    await slowStep(driver, "Selected report category");

    await setReactFieldValue(driver, By.id("description"), "Mặt đường hư hỏng cần xử lý để bảo đảm an toàn.");
    await slowStep(driver, "Entered report description");

    await setReactFieldValue(driver, By.id("latitude"), "10.7769");
    await setReactFieldValue(driver, By.id("longitude"), "106.7009");
    await slowStep(driver, "Entered report coordinates");

    const invalidFields = await driver.executeScript(`
      return Array.from(document.querySelectorAll('form [required]'))
        .filter((element) => !element.checkValidity())
        .map((element) => ({
          id: element.id,
          name: element.name,
          value: element.value,
          message: element.validationMessage
        }));
    `);

    assert.deepEqual(invalidFields, []);

    await clickSubmitButton(driver);
    await slowStep(driver, "Submitted report form");

    await driver.wait(until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Ổ gà trước cổng trường')]")), 10000);
    await slowStep(driver, "Report appears on dashboard");

    const bodyText = await driver.findElement(By.css("body")).getText();
    assert.match(bodyText, /Báo cáo của tôi/);
    assert.match(bodyText, /Ổ gà trước cổng trường/);
    assert.match(bodyText, /Mới tiếp nhận/);

    if (PAUSE_MS > 0) {
      await driver.sleep(PAUSE_MS);
    }

    console.log("Selenium citizen flow passed: login and report submission completed.");
  } catch (error) {
    const currentUrl = await driver.getCurrentUrl();
    const bodyText = await driver.findElement(By.css("body")).getText().catch(() => "");

    console.error(`Selenium citizen flow failed at URL: ${currentUrl}`);
    console.error(bodyText.slice(0, 2000));
    throw error;
  } finally {
    await driver.quit();
    await stopMockApi(mockApi);
  }
}

runCitizenFlow().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
