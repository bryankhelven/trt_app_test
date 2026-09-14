"""Generate a content-versioned cache of local Web build assets only."""
import hashlib
import json
import re
from pathlib import Path
root=Path('build/web')
index=root/'index.html'
registration='''<!-- arcanum-offline:start -->
<p id="offline-warning" hidden role="status">O modo offline não pôde ser ativado neste navegador. Suas leituras continuam locais.</p>
<aside id="app-update" hidden role="status" style="position:fixed;bottom:16px;left:16px;right:16px;z-index:2147483647;padding:16px;border:1px solid #cab78a;border-radius:12px;background:#211a31;color:#f4e9d5;font:16px sans-serif">
  Nova versão disponível. Salve sua tiragem antes de atualizar.
  <button id="apply-update" type="button" style="margin:8px;padding:8px 16px">Atualizar agora</button>
</aside>
<script>
if ('serviceWorker' in navigator) {
  let updateRequested = false;
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (updateRequested) window.location.reload();
  });
  navigator.serviceWorker.register('offline-worker.js', {updateViaCache: 'none'}).then(registration => {
    const offerUpdate = () => {
      if (!registration.waiting || !navigator.serviceWorker.controller) return;
      document.getElementById('app-update').hidden = false;
      document.getElementById('apply-update').onclick = () => {
        updateRequested = true;
        registration.waiting?.postMessage({type: 'ACTIVATE_UPDATE'});
      };
    };
    offerUpdate();
    registration.addEventListener('updatefound', () => {
      registration.installing?.addEventListener('statechange', offerUpdate);
    });
    registration.update().catch(() => {});
    window.addEventListener('focus', () => registration.update().catch(() => {}));
  }).catch(() => {
    document.getElementById('offline-warning').hidden = false;
  });
}
</script>
<!-- arcanum-offline:end -->
'''
s=index.read_text()
s=re.sub(r'<!-- arcanum-offline:start -->.*?<!-- arcanum-offline:end -->\s*', '', s, flags=re.S)
index.write_text(s.replace('</body>',registration+'</body>'))
files=sorted(p for p in root.rglob('*') if p.is_file() and p.name!='offline-worker.js')
version=hashlib.sha256(b''.join(str(p.relative_to(root)).encode()+p.read_bytes() for p in files)).hexdigest()[:20]
resources=['./']+[str(p.relative_to(root)) for p in files]
worker='''const PREFIX = 'arcanum-assets-' + encodeURIComponent(self.registration.scope) + '-';
const CACHE = PREFIX + '__VERSION__';
const FILES = __FILES__;
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(FILES)));
});
self.addEventListener('message', event => {
  if (event.data?.type === 'ACTIVATE_UPDATE') self.skipWaiting();
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key.startsWith(PREFIX) && key !== CACHE).map(key => caches.delete(key)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || url.origin !== self.location.origin || !url.href.startsWith(self.registration.scope)) return;
  event.respondWith(caches.open(CACHE).then(async cache => {
    const cached = await cache.match(event.request, {ignoreSearch: true});
    return cached || fetch(event.request);
  }));
});
'''
(root/'offline-worker.js').write_text(worker.replace('__VERSION__',version).replace('__FILES__',json.dumps(resources)))
print(f'Offline cache {version}: {len(resources)} local resources; no user data cached.')
