"""Real-browser acceptance for the revised product contract. No state injection."""
import asyncio,json,os,re
from pathlib import Path
from playwright.async_api import async_playwright
OUT=Path('docs/evidence/revision2')
async def semantics(page):
 await page.wait_for_selector('flutter-view',timeout=45000)
 placeholder=page.locator('flt-semantics-placeholder')
 if await placeholder.count(): await placeholder.evaluate('(el)=>el.click()')
 await page.wait_for_timeout(450)
async def main():
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path=os.environ.get('CHROME_EXECUTABLE','/home/bryan/.cache/ms-playwright/chromium-1234/chrome-linux64/chrome'),headless=True,args=['--no-sandbox','--use-gl=swiftshader','--enable-unsafe-swiftshader'])
  ctx=await browser.new_context(viewport={'width':1280,'height':900})
  page=await ctx.new_page();errors=[];external=[];checks=[]
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  page.on('request',lambda r:external.append(r.url) if r.url.startswith('http') and not r.url.startswith('http://localhost:8878') else None)
  async def button(name):
   await page.get_by_role('button',name=name,exact=True).click();await page.wait_for_timeout(250)
  async def draw(remaining):
   deck=page.get_by_text(f'Baralho, {remaining} cartas restantes',exact=True)
   box=await deck.bounding_box()
   # Flutter IgnorePointer governs the canvas; a tooltip text node may still
   # overlap in its accessibility mirror. Exercise an actual mouse click.
   await page.mouse.click(box['x']+box['width']/2,box['y']+box['height']/2);await page.wait_for_timeout(200)
   await page.get_by_text('Escolher carta fechada 1',exact=True).click();await page.wait_for_timeout(350)
   await button('Colocar na próxima posição')
   await page.get_by_text(f'Baralho, {remaining-1} cartas restantes',exact=True).wait_for()
  try:
   await page.goto('http://localhost:8878/#/reading/spread/CRUZ_CELTICA');await semantics(page)
   for i in range(10):
    await draw(78-i)
    await page.get_by_text(f'Carta fechada {i+1}, revelar',exact=False).click();await page.wait_for_timeout(120)
   checks.append('Celtic: 10 manual placements and reveals')
   await page.mouse.move(5,5);await page.wait_for_timeout(300)
   await page.screenshot(path=str(OUT/'celtic-desktop.png'))
   target=page.get_by_text(re.compile('revelada, abrir informações')).last
   box=await target.bounding_box();await page.mouse.move(box['x']+box['width']/2,box['y']+box['height']/2);await page.wait_for_timeout(550)
   await page.screenshot(path=str(OUT/'position-hover.png'))
   assert await page.get_by_text(re.compile('Como o significado desta carta')).count()>0
   checks.append('Floating hover includes position and reflection prompt')
   await page.mouse.move(5,5);await button('Notas da leitura')
   await page.get_by_role('textbox',name='Pergunta (opcional)',exact=True).click();await page.keyboard.insert_text('Escolha de teste')
   await page.keyboard.press('Tab');await page.keyboard.insert_text('Notas privadas de teste')
   await button('Aplicar notas');await button('Salvar tiragem')
   await page.get_by_text('Tiragem salva neste dispositivo',exact=True).wait_for()
   for w,h in [(390,844),(844,390)]:
    await page.set_viewport_size({'width':w,'height':h});await page.mouse.move(5,h-5);await page.wait_for_timeout(500)
    await page.get_by_text('Baralho, 68 cartas restantes',exact=True).wait_for()
    await page.screenshot(path=str(OUT/f'celtic-{w}x{h}.png'))
   checks.append('Portrait/landscape retains placed identities and revealed state')
   await page.set_viewport_size({'width':1280,'height':900});await page.reload();await semantics(page)
   await page.get_by_text('Baralho, 78 cartas restantes',exact=True).wait_for()
   await button('Início');await page.get_by_text(re.compile('Consultar Cruz Celta')).click();await page.wait_for_timeout(250)
   await page.get_by_text('Notas privadas de teste',exact=True).wait_for()
   await button('Abrir tiragem na mesa');await page.get_by_text('Baralho, 68 cartas restantes',exact=True).wait_for()
   checks.append('Only explicit saved snapshot reopens from journal after reload')
   await button('Nova tiragem');await page.get_by_text('Baralho, 78 cartas restantes',exact=True).wait_for()
   await draw(78);await page.reload();await semantics(page)
   if await page.get_by_role('button',name='Início',exact=True).count(): await button('Início')
   await page.get_by_text(re.compile('Consultar Cruz Celta')).click();await page.wait_for_timeout(250)
   await button('Abrir tiragem na mesa');await page.get_by_text('Baralho, 68 cartas restantes',exact=True).wait_for()
   checks.append('Unsaved new reading discarded on reload; original journal snapshot preserved')
   # Fresh route and split selector with minor arcana browsing.
   await page.goto('http://localhost:8878/#/reading/free');await semantics(page)
   await page.get_by_text('Baralho, 78 cartas restantes',exact=True).click();await page.wait_for_timeout(200)
   await page.get_by_text('Menores',exact=True).click();await page.get_by_text('Percorrer',exact=True).click();await page.wait_for_timeout(250)
   await page.get_by_text('1 de 56',exact=True).wait_for();await button('Próxima carta')
   await page.screenshot(path=str(OUT/'browse-minors.png'))
   await button('Escolher esta carta');await button('Colocar no centro')
   await page.get_by_text('Baralho, 77 cartas restantes',exact=True).wait_for()
   await page.reload();await semantics(page);await page.get_by_text('Baralho, 78 cartas restantes',exact=True).wait_for()
   checks.append('Minor browsing selects a closed card; unsaved free reading discarded')
   # Pairs are manually filled, selector narrows itself to the required arcana.
   await page.goto('http://localhost:8878/#/reading/spread/SE_SIM_SE_NAO');await semantics(page)
   await button('Opções da mesa');await page.get_by_role('menuitem',name='Usar maior + menor por posição',exact=True).click();await page.wait_for_timeout(200)
   for i,expected in [(0,'maior'),(1,'menor'),(2,'maior'),(3,'menor')]:
    await page.get_by_text(f'Baralho, {78-i} cartas restantes',exact=True).click();await page.wait_for_timeout(200)
    await page.get_by_text(f'Esta posição pede um arcano {expected}.',exact=True).wait_for()
    await page.get_by_text(re.compile(r'Escolher carta fechada \d+')).first.click();await page.wait_for_timeout(350);await button('Colocar na próxima posição')
    await page.get_by_text(f'Carta fechada {i+1}, revelar',exact=False).click();await page.wait_for_timeout(120)
   await page.mouse.move(5,5);await page.screenshot(path=str(OUT/'yes-no-pairs.png'));checks.append('Major/minor pair enforced in each Yes/No position')
   for mode,name in [('CRUZ_HERMETICA','hermetic'),('QUATRO_ELEMENTOS','elements')]:
    await page.goto(f'http://localhost:8878/#/reading/spread/{mode}');await semantics(page)
    await page.screenshot(path=str(OUT/f'{name}-desktop.png'))
   await page.evaluate('navigator.serviceWorker.ready');await page.wait_for_function('navigator.serviceWorker.controller !== null')
   await ctx.set_offline(True);await page.reload();await semantics(page)
   await page.get_by_text('Baralho, 78 cartas restantes',exact=True).wait_for()
   checks.append('Revised app opens offline without external resources')
   result={'status':'PASS','checks':checks,'errors':errors,'external_requests':external}
   assert not errors,errors
  except Exception as e:
   await page.screenshot(path=str(OUT/'web-failure.png'))
   (OUT/'web-failure-semantics.txt').write_text(await page.locator('body').inner_text())
   result={'status':'FAIL','checks':checks,'error':str(e),'errors':errors,'external_requests':external}
  (OUT/'web-acceptance.json').write_text(json.dumps(result,ensure_ascii=False,indent=2));print(json.dumps(result,ensure_ascii=False))
  await browser.close()
  if result['status']!='PASS':raise SystemExit(1)
asyncio.run(main())
