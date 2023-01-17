const express = require('express');
const cors = require('cors');
const puppeteer = require('puppeteer');
const cheerio = require('cheerio');
const app = express();

app.use(cors());

const currencies = [];

app.get('/currencies', async (req, res) => {
    if (!currencies.length) {
        const browser = await puppeteer.launch();
        const page = await browser.newPage();
        await page.goto(`https://continentalcurrency.ca/list-of-currencies/`);
        const selector = await page.waitForSelector('html');
        const html = await page.evaluate(selector => selector.innerHTML, selector);
        const $ = cheerio.load(html);
        $('p').each(function () {
            const text = $(this).text();
            if (text.indexOf('|') >= 0) {
                const sp = text.split('|');
                currencies.push({
                    code: sp[0].trim(),
                    name: sp[1].trim()
                });
            }
        });
    }
    res.send(currencies);
});

app.get('/exchange/:firstCurrency/:secondCurrency', async (req, res) => {
    const {firstCurrency, secondCurrency} = req.params;
    if (firstCurrency === secondCurrency) {
        res.status(400);
        res.json({error: 'Can not exchange currency to itself'});
    }
    const browser = await puppeteer.launch();
    const page = await browser.newPage();
    await page.goto(`https://www.google.com/finance/quote/${firstCurrency}-${secondCurrency}`);
    const element = await page.waitForSelector('.YMlKec.fxKbKc').catch(() => {
        res.status(400);
        res.json({error: 'invalid currency'});
    });
    if (element) {
        const text = await page.evaluate(element => element.textContent, element);
        browser.close().then();
        res.json({rate: parseFloat(text)});
    }
});

app.listen(3000, () => {
    console.log('Server is running');
});
