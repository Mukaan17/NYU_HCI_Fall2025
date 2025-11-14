import puppeteer from "puppeteer";

async function scrapeBrooklynLibrary() {
  const browser = await puppeteer.launch({
    headless: "new",
    args: ["--no-sandbox", "--disable-setuid-sandbox"]
  });

  const page = await browser.newPage();

  await page.goto("https://discover.bklynlibrary.org/?event", {
    waitUntil: "networkidle2",
    timeout: 0,
  });

  // Wait for React cards to load
  await page.waitForSelector(".MuiCard-root", { timeout: 30000 });

  const events = await page.evaluate(() => {
    const cards = [...document.querySelectorAll(".MuiCard-root")];

    return cards.slice(0, 20).map(card => {
      const title = card.querySelector("h2,h3")?.innerText || null;

      const date = card.querySelector("time")?.innerText || null;

      const timeNode = [...card.querySelectorAll("svg + span")].find(
        n => n.innerText.includes("am") || n.innerText.includes("pm")
      );
      const time = timeNode?.innerText || null;

      const location = card.querySelector("[data-testid='LocationOnIcon'] ~ p")
        ?.innerText || null;

      return { title, date, time, location };
    });
  });

  await browser.close();
  return events;
}

// Run directly
scrapeBrooklynLibrary().then(events => {
  console.log(JSON.stringify(events, null, 2));
});
