'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "7ccd0871e1fc6de82ac256e100acdc35",
"assets/AssetManifest.bin.json": "5bfad47b8c353545632287a0795a7a62",
"assets/AssetManifest.json": "1fc8e5d14a51524df9b66b07e8ca949d",
"assets/assets/icon/app_icon.png": "07992ee76e7c790c0bd158acad4ce1ed",
"assets/assets/icon/splash_icon.png": "813cf3d3e593bfa206554c44b9f95735",
"assets/assets/icons/icon_add.svg": "51101d53a5600f05ef977a4a4f5acc3c",
"assets/assets/icons/icon_analytics.svg": "ab9961e334e30eadb667aad894bd07d3",
"assets/assets/icons/icon_anchor.svg": "34276ce36079f685bc8edeacd55ff82a",
"assets/assets/icons/icon_api_key.svg": "0d2eb6c7c4d98f420b72d6ef1c8aeb94",
"assets/assets/icons/icon_check.svg": "1e70231a3545251285d905e0ffa3a9c8",
"assets/assets/icons/icon_chevron_right.svg": "d3c19efd96782bb91a6bd43229869e29",
"assets/assets/icons/icon_close.svg": "a716db3257e59be0eb973e34e1ba37a3",
"assets/assets/icons/icon_data.svg": "43b4fd8d70bb63efc1ee9dcdbc4312d4",
"assets/assets/icons/icon_delete.svg": "14fd4af6cbc2f936f7dd7511e85db32c",
"assets/assets/icons/icon_download.svg": "9a7d5515981b9f5b9eb6b5f1ec51a717",
"assets/assets/icons/icon_edit.svg": "de355e48e5d608c1428d1899141aa8db",
"assets/assets/icons/icon_explore.svg": "060e18872a590f7443ae9ec2a9c18c0c",
"assets/assets/icons/icon_habit.svg": "175e801c74812aea28b8670d3be1d1a9",
"assets/assets/icons/icon_menu.svg": "1766e1c9ffb401f9f655cbd66a995ae1",
"assets/assets/icons/icon_notification.svg": "8d1508a06729605fe86d72bb743b433a",
"assets/assets/icons/icon_notification_outlined.svg": "5c243da72f99af293bd0705f828e179b",
"assets/assets/icons/icon_pause.svg": "f0aed0ce0340d42431a2024d0d696311",
"assets/assets/icons/icon_pin.svg": "62ac7cf5d42b01b8ac27568cf1df885d",
"assets/assets/icons/icon_plan.svg": "e39053a76f339b5b94af83a83d252303",
"assets/assets/icons/icon_play.svg": "88a6bd22ba08cf1476d846a02c47b12f",
"assets/assets/icons/icon_refresh.svg": "d0e56b081d1c1e872ed1caaf24ddcac1",
"assets/assets/icons/icon_settings.svg": "b958abeca5f7062f5738c52157f4c374",
"assets/assets/icons/icon_upload.svg": "85dcb22ab5d824f91e242a7b79bd873d",
"assets/assets/images/alipay_qr.png": "cda0bcfe5e1041c51fdcdc4670dc02c1",
"assets/assets/images/app_icon.png": "1438c24e8257d4147f84b21b9c800392",
"assets/assets/images/splash_screen.png": "00e261dec71bb44d0ec418adedaa3b4c",
"assets/assets/images/success_popup_reference.png": "b0a68ed04c2d1d3e2625fea4c327f74f",
"assets/assets/images/wechat_pay_qr.png": "9376fb56df3ed7418869e2fa3dbf7325",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "50cefce826e1b1f63bf837215a410e0e",
"assets/NOTICES": "54bb40b5666f9c2d4866a269bb4bff7b",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "66177750aff65a66cb07bb44b8c6422b",
"canvaskit/canvaskit.js.symbols": "48c83a2ce573d9692e8d970e288d75f7",
"canvaskit/canvaskit.wasm": "1f237a213d7370cf95f443d896176460",
"canvaskit/chromium/canvaskit.js": "671c6b4f8fcc199dcc551c7bb125f239",
"canvaskit/chromium/canvaskit.js.symbols": "a012ed99ccba193cf96bb2643003f6fc",
"canvaskit/chromium/canvaskit.wasm": "b1ac05b29c127d86df4bcfbf50dd902a",
"canvaskit/skwasm.js": "694fda5704053957c2594de355805228",
"canvaskit/skwasm.js.symbols": "262f4827a1317abb59d71d6c587a93e2",
"canvaskit/skwasm.wasm": "9f0c0c02b82a910d12ce0543ec130e60",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "f393d3c16b631f36852323de8e583132",
"flutter_bootstrap.js": "8e273ea77d58e77502591806da332061",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "aaca8c6d8410006fba04114bf6ba25b8",
"/": "aaca8c6d8410006fba04114bf6ba25b8",
"main.dart.js": "be0ef07ef458c4df58ecf11d4f360e98",
"manifest.json": "df5d03d478793113a2aa0f038da64844",
"version.json": "83619673d4abf673e2c838ad5c994dc4"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
