import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Two directory lanes that share one layout and differ only in copy + accent.
class DirectoryMode {
  const DirectoryMode({required this.riders});

  final bool riders;

  static const lines = DirectoryMode(riders: false);
  static const ridersLane = DirectoryMode(riders: true);

  IconData get tabIcon =>
      riders ? Icons.hail_outlined : Icons.directions_car_outlined;

  String get tabLabel => riders ? 'طلبات الركاب' : 'خطوط السائقين';

  String get title => tabLabel;

  /// Who this tab is for, then what the list contains.
  String get hint => riders
      ? 'للسائقين — اختر الانطلاق والوجهة'
      : 'للركاب — اختر الانطلاق والوجهة';

  String get fabLabel => 'اضافة';

  String get emptyPromptTitle =>
      riders ? 'ابحث في طلبات الركاب' : 'ابحث في خطوط السائقين';

  String get emptyPromptBody => hint;

  String get emptyMatchTitle =>
      riders ? 'لا طلبات ركاب بهذه التصفية' : 'لا خطوط سائقين بهذه التصفية';

  String get emptyMatchBody => riders
      ? 'لا طلب مطابق. انشر خطك لتصلك طلبات الركاب.'
      : 'لا خط مطابق. انشر طلبك لتصلك عروض السائقين.';

  /// Driver browsing rider requests publishes a line; rider browsing lines publishes a request.
  bool get inviteAsRider => !riders;

  String get inviteCta =>
      riders ? 'نشر خط سائق' : 'نشر طلب راكب';

  String get loading =>
      riders ? 'جاري تحميل طلبات الركاب…' : 'جاري تحميل خطوط السائقين…';

  Color accent(MasaratColors c) => riders ? c.opportunity : c.primary;
}
