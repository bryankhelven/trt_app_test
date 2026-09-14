"""Exercise the actual generated offline worker across two live releases."""
import asyncio
import functools
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

from playwright.async_api import async_playwright


class FreshFiles(SimpleHTTPRequestHandler):
    def do_GET(self):
        # Fixtures replace equal-sized files within one timestamp second.
        # Force byte validation instead of the sample server's date-only 304.
        if 'If-Modified-Since' in self.headers:
            del self.headers['If-Modified-Since']
        super().do_GET()


async def main():
    generator = Path(__file__).with_name('prepare_offline.py').resolve()
    with tempfile.TemporaryDirectory(prefix='arcanum-update-') as directory:
        root = Path(directory)
        site = root / 'trt_app_test'
        for version in ('one', 'two'):
            work = root / version
            output = work / 'build/web'
            output.mkdir(parents=True)
            (output / 'index.html').write_text(
                '<!doctype html><html><body><main>' + version + '</main>'
                '<input aria-label="draft"></body></html>'
            )
            subprocess.run(['python3', str(generator)], cwd=work, check=True)
        shutil.copytree(root / 'one/build/web', site)
        handler = functools.partial(FreshFiles, directory=str(root))
        server = ThreadingHTTPServer(('127.0.0.1', 0), handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            async with async_playwright() as playwright:
                browser = await playwright.chromium.launch(
                    executable_path=os.environ.get(
                        'CHROME_EXECUTABLE',
                        '/home/bryan/.cache/ms-playwright/chromium-1234/chrome-linux64/chrome',
                    ),
                    args=['--no-sandbox'],
                )
                context = await browser.new_context()
                page = await context.new_page()
                navigations = []
                page.on('framenavigated', lambda frame: navigations.append(frame.url))
                url = f'http://127.0.0.1:{server.server_port}/trt_app_test/'
                await page.goto(url)
                await page.wait_for_function('navigator.serviceWorker.controller !== null')
                await page.get_by_label('draft').fill('tiragem temporária')
                assert len(navigations) == 1, 'First installation must not reload'
                await page.evaluate("caches.open('arcanum-assets-other-project-keep')")
                shutil.copytree(root / 'two/build/web', site, dirs_exist_ok=True)
                await page.evaluate('(async()=>{const r=await navigator.serviceWorker.ready;await r.update();})()')
                await page.get_by_role('button', name='Atualizar agora').wait_for()
                assert await page.get_by_label('draft').input_value() == 'tiragem temporária'
                assert len(navigations) == 1, 'Update must wait for the user'
                await page.get_by_role('button', name='Atualizar agora').click()
                await page.get_by_text('two', exact=True).wait_for()
                assert len(navigations) == 2, 'Accepting must reload exactly once'
                assert 'arcanum-assets-other-project-keep' in await page.evaluate('caches.keys()')
                await context.set_offline(True)
                await page.reload()
                await page.get_by_text('two', exact=True).wait_for()
                await browser.close()
                print('PASS: first install, pending update retains draft, explicit activation, scoped cache, offline reload')
        finally:
            server.shutdown()
            server.server_close()


if __name__ == '__main__':
    asyncio.run(main())
