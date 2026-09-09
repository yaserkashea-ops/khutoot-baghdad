# خطوط بغداد (khutoot-baghdad)

تنظيم إعلانات خطوط النقل المشترك في بغداد.

## الروابط النهائية

| الخدمة | الرابط |
|---|---|
| الأداة العامة | https://khutoot-baghdad.web.app |
| لوحة التحكم | https://khutoot-baghdad-admin.web.app |
| تصفير الكاش (عند عدم ظهور التحديث) | https://khutoot-baghdad.web.app/reset.html |

ملاحظات:
- `https://khutoot-baghdad-app.web.app` يحوّل تلقائياً إلى الرابط العام أعلاه.
- `/admin` على الموقع العام يحوّل إلى موقع لوحة التحكم.

## المستودع

https://github.com/yaserkashea-ops/khutoot-baghdad

## الخدمات المتصلة

| الخدمة | الحالة |
|---|---|
| **Firebase Hosting** | مشروع `khutoot-baghdad-app` — مواقع: `khutoot-baghdad` + `khutoot-baghdad-admin` + تحويل `khutoot-baghdad-app` |
| **Supabase** | مشروع `plqhpbtkgforuvqferou` — جداول `listings` و `admin_reports` (انظر `supabase/schema.sql`) |
| **GitHub** | المستودع أعلاه |

### نشر الويب

```bash
flutter build web --release
firebase deploy --only hosting:main,hosting:app,hosting:admin --project khutoot-baghdad-app
```

بعد كل نشر مهم: ارفع رقم الإصدار في `web/index.html` و `web/admin.html` و `web/sw.js` و `web/version.json` معاً.
