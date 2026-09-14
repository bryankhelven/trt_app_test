"""Real browser regression: save/delete must survive immediate reload."""
import asyncio
import os
import re

from playwright.async_api import async_playwright


async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            executable_path=os.environ.get('CHROME_EXECUTABLE', '/home/bryan/.cache/ms-playwright/chromium-1234/chrome-linux64/chrome'),
            args=['--no-sandbox'],
        )
        context = await browser.new_context(viewport={'width': 1280, 'height': 900})
        page = await context.new_page()

        async def ready():
            await page.wait_for_selector('flutter-view', timeout=45000)
            placeholder = page.locator('flt-semantics-placeholder')
            if await placeholder.count():
                await placeholder.evaluate('(el) => el.click()')

        base = os.environ.get('ARCANUM_PREVIEW_URL', 'http://localhost:8890/trt_app_test').rstrip('/')
        await page.goto(base + '/#/reading/spread/CARTA_UNICA')
        await ready()
        deck = page.get_by_text('Baralho, 78 cartas restantes', exact=True)
        await deck.wait_for()
        box = await deck.bounding_box()
        await page.mouse.click(box['x'] + box['width'] / 2, box['y'] + box['height'] / 2)
        await page.get_by_text('Escolher carta fechada 1', exact=True).click()
        await page.get_by_role('button', name='Colocar na próxima posição', exact=True).click()
        await page.get_by_role('button', name='Salvar tiragem', exact=True).click()
        await page.get_by_text('Tiragem salva neste dispositivo', exact=True).wait_for()
        # No sleep: a success message must already mean the write completed.
        await page.reload()
        await ready()
        await page.get_by_role('button', name='Início', exact=True).click()
        await page.get_by_text(re.compile('Consultar Carta Única')).click()
        await page.get_by_role('button', name='Excluir', exact=True).click()
        await page.get_by_text('Excluir leitura?', exact=True).wait_for()
        await page.get_by_role('button', name='Excluir', exact=True).last.click()
        await page.get_by_text('Seu último encontro', exact=True).wait_for(state='detached')
        # Wait for navigation out of the deleted reading, not a storage delay.
        await page.get_by_role('button', name='Diário de leituras', exact=True).wait_for()
        await page.reload()
        await ready()
        await page.get_by_role('button', name='Diário de leituras', exact=True).click()
        await page.get_by_text('Nenhuma leitura salva ainda.', exact=True).wait_for()
        print('PASS: explicit save and deletion survive immediate reload')
        await browser.close()


if __name__ == '__main__':
    asyncio.run(main())
