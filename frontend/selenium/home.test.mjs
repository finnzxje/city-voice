import assert from "node:assert/strict";
import { Builder, By, until } from "selenium-webdriver";
import chrome from "selenium-webdriver/chrome.js";

const BASE_URL = process.env.SELENIUM_BASE_URL ?? "http://127.0.0.1:5173";
const BROWSER = process.env.SELENIUM_BROWSER ?? "chrome";
const HEADLESS = process.env.SELENIUM_HEADLESS !== "false";

async function createDriver() {
  if (BROWSER !== "chrome") {
    throw new Error(`Unsupported SELENIUM_BROWSER="${BROWSER}". This script currently supports chrome.`);
  }

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

async function run() {
  const driver = await createDriver();

  try {
    await driver.get(BASE_URL);

    const pageContent = await driver.wait(
      until.elementLocated(By.xpath("//*[contains(normalize-space(.), 'Bản đồ sự cố cộng đồng')]")),
      10000,
    );

    await driver.wait(until.elementIsVisible(pageContent), 5000);

    const pageText = await driver.findElement(By.css("body")).getText();
    const pageDomText = await driver.executeScript("return document.body.textContent || '';");

    assert.match(pageText, /CityVoice/);
    assert.match(pageText, /Bản đồ sự cố cộng đồng/);
    assert.match(pageText, /Kết quả từ cộng đồng/);
    assert.match(pageDomText, /Cùng nhau xây dựng/);
    assert.match(pageDomText, /Gửi báo cáo ngay/);

    console.log("Selenium smoke test passed: CityVoice home page is visible.");
  } finally {
    await driver.quit();
  }
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
