# نسخة المعاينة التجريبية

هذه النسخة **لا تتصل بقاعدة إنتاج Supabase** ولا تكتب فيها. البيانات ثابتة في الذاكرة لهذه العملية فقط.

الموقع الحي `https://khutoot-baghdad.web.app` ولوحة التحكم الحية لا يُستبدلان بهذا البناء.

تحويل التطبيق إلى واجهة واحدة يُجرَّب هنا أولاً، ثم يُنشر للإنتاج بعد موافقتك.

## رابط المعاينة الحالي

https://khutoot-baghdad--preview-single-ui-fm2tidem.web.app

قناة Firebase: `preview-single-ui` — تنتهي في 5 تشرين الثاني 2026.

الشارة الظاهرة: **نسخة معاينة تجريبية**

## التشغيل محلياً

من جذر المشروع:

```bash
flutter run -d chrome --dart-define=PREVIEW_MODE=true
```

لوحة التحكم محلياً (كذلك بدون إنتاج):

```bash
flutter run -t lib/admin_main.dart -d chrome --dart-define=PREVIEW_MODE=true
```

بدون `--dart-define=PREVIEW_MODE=true` يبقى التطبيق على مسار الإنتاج الحالي.

## ما لا يُنفَّذ من هنا

- `firebase deploy` للإنتاج
- `git push` إلى `main` / الإنتاج
- أي migration أو كتابة على Supabase الإنتاجي
