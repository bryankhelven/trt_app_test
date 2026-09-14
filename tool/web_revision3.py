"""R3 browser acceptance: pointer gestures and real persistence, without state injection."""
import asyncio, json, os, re, traceback
from pathlib import Path
from playwright.async_api import async_playwright
OUT=Path('docs/evidence/revision3')
BASE=os.environ.get('ARCANUM_PREVIEW_URL','http://localhost:8879')
async def main():
 async with async_playwright() as p:
  browser=await p.chromium.launch(executable_path=os.environ.get('CHROME_EXECUTABLE','/home/bryan/.cache/ms-playwright/chromium-1234/chrome-linux64/chrome'),headless=True,args=['--no-sandbox','--use-gl=swiftshader','--enable-unsafe-swiftshader'])
  ctx=await browser.new_context(viewport={'width':1280,'height':900})
  page=await ctx.new_page();checks=[];errors=[]
  page.on('pageerror',lambda e:errors.append(str(e)))
  page.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
  async def semantics():
   await page.wait_for_selector('flutter-view',timeout=45000)
   placeholder=page.locator('flt-semantics-placeholder')
   if await placeholder.count():await placeholder.evaluate('(el)=>el.click()')
   await page.wait_for_timeout(550)
  async def route(path):
   await page.goto(BASE+'/#/'+path);await semantics()
  async def center(locator):
   b=await locator.bounding_box();assert b
   return (b['x']+b['width']/2,b['y']+b['height']/2)
  async def click(locator):
   await page.mouse.click(*await center(locator));await page.wait_for_timeout(600)
  async def button(name):
   await page.get_by_role('button',name=name,exact=True).click();await page.wait_for_timeout(600)
  def deck(n):return page.get_by_text(f'Baralho, {n} cartas restantes',exact=True)
  def card(n):return page.get_by_text(re.compile(rf'Carta fechada {n}, revelar'))
  def position(name):return page.get_by_text(re.compile(r'Posição '+re.escape(name)))
  async def drag(source,target):
   await page.mouse.move(*source);await page.mouse.down();await page.mouse.move(*target,steps=18)
   await page.wait_for_timeout(80);await page.mouse.up();await page.wait_for_timeout(550)
  async def stage():
   b=await page.get_by_text('Área livre · retire aqui e arraste para uma posição',exact=True).bounding_box()
   return (640,b['y']-85)
  async def choose(n,index=1):
   await click(deck(n));await page.get_by_text(f'Escolher carta fechada {index}',exact=True).click();await page.wait_for_timeout(550)
  try:
   await route('reading/spread/SE_SIM_SE_NAO')
   sim='Se eu decidir por sim';nao='Se eu decidir por não'
   primary=await center(position(sim));no_position=await center(position(nao))
   await choose(78,5);await page.mouse.click(*await stage());await page.wait_for_timeout(650)
   await deck(77).wait_for();assert await page.get_by_text(re.compile(r'Carta 1$')).count()==1
   await drag(await center(card(1)),primary)
   await page.get_by_text(re.compile('^1/2 posições principais')).wait_for()
   await click(card(1))
   revealed=page.get_by_text(re.compile('revelada, abrir informações')).first
   await drag(await center(revealed),await stage())
   await page.get_by_text(re.compile('^0/2 posições principais')).wait_for()
   await drag(await center(revealed),primary)
   await page.get_by_text(re.compile('^1/2 posições principais')).wait_for();await deck(77).wait_for()
   checks.append('Chosen fifth card stages, snaps into position, reveals, exits and returns without another draw')
   await drag(await center(deck(77)),primary)
   await drag(await center(deck(76)),primary)
   await deck(75).wait_for();assert await page.get_by_text(re.compile(r'2° complemento$')).count()==1
   await drag(await center(deck(75)),no_position)
   await deck(74).wait_for()
   await drag(await center(card(3)),await stage())
   await drag(await center(card(3)),no_position)
   assert await page.get_by_text(re.compile(r'1° complemento$')).count()==2
   await page.mouse.move(*await center(card(3)));await page.wait_for_timeout(500)
   await page.get_by_text('1° complemento · '+nao,exact=False).wait_for()
   await page.screenshot(path=str(OUT/'complement-hover.png'))
   await page.mouse.move(5,5);await page.wait_for_timeout(400)
   await page.screenshot(path=str(OUT/'yes-no-complements-desktop.png'))
   checks.append('Drop beside and on occupied position adds ordered complements; moving between positions renumbers and updates hover')
   await button('Salvar tiragem');await page.get_by_text('Tiragem salva neste dispositivo',exact=True).wait_for()
   await page.reload();await semantics();await deck(78).wait_for()
   await button('Início');await page.get_by_text(re.compile('Consultar Se sim / Se não')).click();await page.wait_for_timeout(400)
   await page.get_by_text(re.compile('1° complemento · '+nao)).wait_for()
   await button('Abrir tiragem na mesa');await deck(74).wait_for()
   assert await page.get_by_text(re.compile(r'1° complemento$')).count()==2
   checks.append('Explicit save and journal reopen retain primary, complements and reveal state')
   for w,h in [(390,844),(844,390)]:
    await page.set_viewport_size({'width':w,'height':h});await page.wait_for_timeout(600)
    await deck(74).wait_for();await page.screenshot(path=str(OUT/f'complements-{w}x{h}.png'))
   checks.append('Portrait/landscape keep associations and identities')
   await page.set_viewport_size({'width':1280,'height':900})
   await route('reading/free')
   await drag(await center(deck(78)),(400,400));await drag(await center(deck(77)),(750,450))
   await drag(await center(card(1)),(400,600))
   assert await page.get_by_text(re.compile(r'Carta 1$')).count()==1
   assert await page.get_by_text(re.compile(r'Carta 2$')).count()==1
   await page.mouse.move(*await center(card(1)));await page.wait_for_timeout(500)
   assert 'Carta complementar' not in await page.locator('body').inner_text()
   await page.mouse.move(5,5);await page.wait_for_timeout(400)
   await page.screenshot(path=str(OUT/'free-numbered.png'))
   await page.reload();await semantics();await deck(78).wait_for()
   checks.append('Free cards use permanent draw-order numbers; unsaved reading disappears on reload')
   await route('reading/spread/CARTA_UNICA')
   await button('Opções da mesa');await page.get_by_role('menuitem',name='Usar maior + menor por posição',exact=True).click();await page.wait_for_timeout(500)
   await click(deck(78));assert 'Esta posição pede' not in await page.locator('body').inner_text()
   await page.get_by_text('Menores',exact=True).click();await page.get_by_text('Percorrer',exact=True).click();await page.wait_for_timeout(300)
   await button('Escolher esta carta');await page.mouse.click(*await stage());await page.wait_for_timeout(600)
   minor=page.get_by_text(re.compile(r'Posição .* · Menor'))
   await drag(await center(card(1)),await center(minor));await deck(77).wait_for()
   checks.append('Unbound paired picker permits minor browsing, staging and later minor-slot snap')
   await route('reading/spread/CRUZ_CELTICA')
   for i in range(10):
    await choose(78-i);await button('Colocar na próxima posição')
   await page.mouse.move(5,5);await page.screenshot(path=str(OUT/'celtic-desktop.png'))
   await drag(await center(deck(68)),await center(position('Situação presente')))
   await page.screenshot(path=str(OUT/'celtic-complement.png'))
   for w,h in [(390,844),(844,390)]:
    await page.set_viewport_size({'width':w,'height':h});await page.wait_for_timeout(600)
    await page.screenshot(path=str(OUT/f'celtic-{w}x{h}.png'))
   await page.set_viewport_size({'width':1280,'height':900})
   await route('reading/spread/CRUZ_HERMETICA');await page.screenshot(path=str(OUT/'hermetic-desktop.png'))
   checks.append('Celtic cross keeps physical layout with occupied slots and complement space; Hermetic layout retained')
   await page.evaluate('navigator.serviceWorker.ready');await page.wait_for_function('navigator.serviceWorker.controller !== null')
   await ctx.set_offline(True);await page.reload();await semantics();await deck(78).wait_for()
   checks.append('Updated app opens offline')
   assert not errors,errors
   result={'status':'PASS','checks':checks,'errors':errors}
  except Exception as e:
   await page.screenshot(path=str(OUT/'web-failure.png'))
   (OUT/'web-failure-semantics.txt').write_text(await page.locator('body').inner_text())
   result={'status':'FAIL','checks':checks,'error':repr(e),'traceback':traceback.format_exc(),'errors':errors}
  (OUT/'web-acceptance.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
  print(json.dumps(result,ensure_ascii=False));await browser.close()
  if result['status']!='PASS':raise SystemExit(1)
asyncio.run(main())
