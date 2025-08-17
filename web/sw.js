self.addEventListener('install', (e)=>{
  e.waitUntil(caches.open('ondoku-v1').then(c=>c.addAll([
    './', './index.html','./style.css','./app.js','./alignment.js','./features.js','./asr.js','./manifest.webmanifest',
    './kids.html','./kids.css','./kids.js'
  ])));
});
self.addEventListener('fetch', (e)=>{
  e.respondWith(caches.match(e.request).then(r=> r || fetch(e.request)));
});
