# خطوط بغداد (khutoot-baghdad)

تنظيم إعلانات خطوط النقل المشترك في بغداد.

## الروابط

| الخدمة | الرابط |
|---|---|
| الأداة العامة | https://khutoot-baghdad.web.app |
| لوحة التحكم | https://khutoot-baghdad-admin.web.app |
| تصفير الكاش (نادراً) | https://khutoot-baghdad.web.app/reset.html |

الروابط ثابتة: بعد كل نشر تصل التحديثات تلقائياً لنفس العنوان (فحص `version.json` + تعطيل Flutter SW).

`khutoot-baghdad-app.web.app` يحوّل إلى الأداة العامة.

## ما الجديد (v18–v20)

- أيقونة التطبيق الجديدة (سيارة + قوس بغداد) مع ألوان تركواز/ذهبي متناسقة
- مشاركة نظامية احترافية (قائمة النظام أو «مشاركة عبر» متعددة التطبيقات)
- إقلاع أسرع: تهيئة متوازية، شاشة إقلاع أخف، تأجيل Service Worker
- واجهة بحث أولاً، ترتيب الأحدث أولاً، نشر متكرر مسموح

## إعداد مشرف جديد (مرة واحدة)

1. في Supabase → **Authentication** → **Users** → أضف مستخدماً (بريد + كلمة مرور)
2. نفّذ SQL المحدّث من `supabase/schema.sql` في SQL Editor
3. ادخل لوحة التحكم بذلك البريد وكلمة المرور

## الخدمات المرتبطة

| الخدمة | التفاصيل |
|---|---|
| Firebase Hosting | مشروع `khutoot-baghdad-app` — مواقع `main` / `admin` / `app` |
| Supabase | `plqhpbtkgforuvqferou` — `listings` + `admin_reports` + Auth |
| GitHub | https://github.com/yaserkashea-ops/khutoot-baghdad |

## نشر

```bash
flutter build web --release --tree-shake-icons
powershell -ExecutionPolicy Bypass -File tool/patch_flutter_bootstrap.ps1
firebase deploy --only hosting:main,hosting:app,hosting:admin --project khutoot-baghdad-app
```

ارفع رقم الإصدار معاً في: `web/index.html`, `web/admin.html`, `web/sw.js`, `web/version.json`, و`AppHosts.buildLabel`.
بعد البناء شغّل `tool/patch_flutter_bootstrap.ps1` حتى لا يثبّت Flutter Service Worker نسخاً قديمة على الأجهزة.
