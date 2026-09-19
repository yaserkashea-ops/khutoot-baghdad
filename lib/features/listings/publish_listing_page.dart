import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../core/config/admin_contact.dart';
import '../../core/config/directory_launch.dart';
import '../../core/auth/publisher_auth_controller.dart';
import '../../core/auth/publisher_limits.dart';
import '../../core/data/baghdad_places.dart';
import '../../core/data/learned_places_store.dart';
import '../../core/data/places_catalog.dart';
import '../../core/models/listing.dart';
import '../../core/models/listing_subscription.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/place_text_rules.dart';
import '../../data/listings_repository.dart';
import '../../data/publisher_repository.dart';
import 'publisher_auth_sheet.dart';
import 'widgets/suggestible_text_field.dart';

/// Publish / edit form for transit listings.
class PublishListingPage extends StatefulWidget {
  const PublishListingPage({
    super.key,
    required this.repository,
    this.initial,
    this.initialType,
    this.draftOnly = false,
    this.allowFreeTextPlaces = false,
    this.asDirectoryRequest = false,
  });

  final ListingsRepository repository;
  final Listing? initial;

  /// Preferred type when opening a blank form (from publish chooser).
  final ListingType? initialType;

  /// When true, save returns the [Listing] via `Navigator.pop` without writing to the repo.
  final bool draftOnly;

  /// Admin panel: main area/destination accept any text (suggestions still available).
  /// Public publish/edit stays list-only.
  final bool allowFreeTextPlaces;

  /// Driver submits a review request (not live in the directory).
  final bool asDirectoryRequest;

  @override
  State<PublishListingPage> createState() => _PublishListingPageState();
}

class _PublishListingPageState extends State<PublishListingPage> {
  final _formKey = GlobalKey<FormState>();

  late ListingType _type;
  late GenderRequirement _gender;
  TimePeriod? _timePeriod;
  late final TextEditingController _area;
  late final TextEditingController _destination;
  late final TextEditingController _originSubInput;
  late final TextEditingController _destinationSubInput;
  late final TextEditingController _departureTime;
  late final TextEditingController _returnTime;
  late final TextEditingController _vehicle;
  late final TextEditingController _seats;
  late final TextEditingController _phone;
  late final TextEditingController _telegram;

  String? _editingId;
  bool _saving = false;
  List<String> _originSubs = [];
  List<String> _destinationSubs = [];

  List<String> get _knownAreas => PlacesCatalog.shared.areas;
  List<String> get _knownDestinations => PlacesCatalog.shared.destinations;

  bool get _isEditing =>
      !widget.draftOnly &&
      _editingId != null &&
      _editingId!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _type = ListingType.driver;
    _gender = initial?.genderRequirement ?? GenderRequirement.mixed;
    _timePeriod = initial?.timePeriod;
    _editingId = initial?.id;
    _originSubs = List<String>.from(initial?.originSubs ?? const []);
    _destinationSubs = List<String>.from(initial?.destinationSubs ?? const []);
    _area = TextEditingController(text: initial?.area ?? '');
    _destination = TextEditingController(text: initial?.destination ?? '');
    _originSubInput = TextEditingController();
    _destinationSubInput = TextEditingController();
    _departureTime = TextEditingController(text: initial?.departureTime ?? '');
    _returnTime = TextEditingController(text: initial?.returnTime ?? '');
    _vehicle = TextEditingController(text: initial?.vehicleType ?? '');
    _seats = TextEditingController(
      text: initial?.seatsCount?.toString() ?? '',
    );
    _phone = TextEditingController(text: initial?.contactPhone ?? '');
    _telegram = TextEditingController(text: initial?.contactTelegram ?? '');
    unawaited(LearnedPlacesStore.purgeUserPlaces());
    PlacesCatalog.shared.addListener(_onPlacesChanged);
    unawaited(PlacesCatalog.shared.refresh());
    if (widget.asDirectoryRequest && !_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_ensurePublisherAccountOrLeave());
      });
    }
  }

  /// Directory submissions require a publisher account before filling the form.
  Future<void> _ensurePublisherAccountOrLeave() async {
    final auth = PublisherAuthController.shared;
    if (!auth.isLoaded) await auth.load();
    if (!mounted) return;
    if (auth.isLoggedIn) return;
    final ok = await showPublisherAuthSheet(
      context,
      title: 'إنشاء حساب مطلوب لإضافة خطك',
    );
    if (!mounted) return;
    if (!ok || !PublisherAuthController.shared.isLoggedIn) {
      Navigator.of(context).maybePop();
    }
  }

  void _onPlacesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PlacesCatalog.shared.removeListener(_onPlacesChanged);
    _area.dispose();
    _destination.dispose();
    _originSubInput.dispose();
    _destinationSubInput.dispose();
    _departureTime.dispose();
    _returnTime.dispose();
    _vehicle.dispose();
    _seats.dispose();
    _phone.dispose();
    _telegram.dispose();
    super.dispose();
  }

  void _addToList(
    TextEditingController input,
    List<String> list,
    void Function(List<String>) assign, {
    required bool asArea,
  }) {
    final value = input.text.trim();
    if (value.isEmpty) return;
    final err = PlaceTextRules.validate(
      value,
      maxLength: PlaceTextRules.subMaxLength,
    );
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(_toast(err));
      return;
    }
    if (list.contains(value)) {
      input.clear();
      return;
    }
    setState(() {
      assign([...list, value]);
      input.clear();
    });
  }

  /// Commit any typed sub-place still sitting in the input (without pressing إضافة).
  void _flushPendingSubs() {
    final originPending = _originSubInput.text.trim();
    if (originPending.isNotEmpty &&
        PlaceTextRules.isAllowed(
          originPending,
          maxLength: PlaceTextRules.subMaxLength,
        ) &&
        !_originSubs.contains(originPending)) {
      _originSubs = [..._originSubs, originPending];
      _originSubInput.clear();
    }
    final destPending = _destinationSubInput.text.trim();
    if (destPending.isNotEmpty &&
        PlaceTextRules.isAllowed(
          destPending,
          maxLength: PlaceTextRules.subMaxLength,
        ) &&
        !_destinationSubs.contains(destPending)) {
      _destinationSubs = [..._destinationSubs, destPending];
      _destinationSubInput.clear();
    }
  }

  void _removeFromList(String value, List<String> list, void Function(List<String>) assign) {
    setState(() => assign(list.where((e) => e != value).toList()));
  }

  bool get _listedOnlyPlaces => !widget.allowFreeTextPlaces;

  int get _mainPlaceMaxLength => PlaceTextRules.listedMaxLength;

  /// Free-text custom places stay capped; listed names use the higher field limit.
  int? get _mainPlaceTypingMaxWords =>
      _listedOnlyPlaces ? PlaceTextRules.maxCustomWords : null;

  String? _placeRequired(String? value) {
    if (!_listedOnlyPlaces) {
      // Free-text mode: still accept long catalog names; custom text ≤ 20.
      return PlaceTextRules.validateMain(
        value,
        options: _knownAreas,
        listedOnly: false,
      );
    }
    return PlaceTextRules.validateMain(
      value,
      options: _knownAreas,
      listedOnly: true,
    );
  }

  String? _destinationRequired(String? value) {
    if (!_listedOnlyPlaces) {
      return PlaceTextRules.validateMain(
        value,
        options: _knownDestinations,
        listedOnly: false,
      );
    }
    return PlaceTextRules.validateMain(
      value,
      options: _knownDestinations,
      listedOnly: true,
    );
  }

  String? _placeOptional(String? value) =>
      PlaceTextRules.validate(value, maxLength: PlaceTextRules.subMaxLength);

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'مطلوب';
    return null;
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    _flushPendingSubs();

    for (final s in [..._originSubs, ..._destinationSubs]) {
      final err = PlaceTextRules.validate(
        s,
        maxLength: PlaceTextRules.subMaxLength,
      );
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(_toast(err));
        return;
      }
    }

    final phone = _phone.text.trim();
    final telegram = _telegram.text.trim();
    if (phone.isEmpty && telegram.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _toast('أدخل واتساب (رقم/يوزر) أو تلغرام على الأقل'),
      );
      return;
    }

    if (_timePeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _toast('اختر التوقيت: صباحي أو مسائي'),
      );
      return;
    }

    final areaCanonical = PlaceTextRules.canonicalizeMain(
      _area.text,
      _knownAreas,
      listedOnly: _listedOnlyPlaces,
    );
    final destCanonical = PlaceTextRules.canonicalizeMain(
      _destination.text,
      _knownDestinations,
      listedOnly: _listedOnlyPlaces,
    );
    if (areaCanonical == null || destCanonical == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _toast(
          _listedOnlyPlaces
              ? 'اختر منطقة ووجهة من القائمة فقط'
              : 'أدخل المنطقة والوجهة',
        ),
      );
      return;
    }
    final areaErr = _placeRequired(areaCanonical);
    final destErr = _destinationRequired(destCanonical);
    if (areaErr != null || destErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _toast(areaErr ?? destErr!),
      );
      return;
    }
    if (_area.text.trim() != areaCanonical) {
      _area.text = areaCanonical;
    }
    if (_destination.text.trim() != destCanonical) {
      _destination.text = destCanonical;
    }

    if (_type == ListingType.driver) {
      if (_vehicle.text.trim().isEmpty || _seats.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          _toast('نوع السيارة وعدد المقاعد مطلوبان للسائق'),
        );
        return;
      }
    }

    setState(() => _saving = true);

    try {
      final auth = PublisherAuthController.shared;
      if (!auth.isLoaded) await auth.load();
      if (widget.asDirectoryRequest && !auth.isLoggedIn) {
        if (!mounted) return;
        setState(() => _saving = false);
        final ok = await showPublisherAuthSheet(
          context,
          title: 'إنشاء حساب مطلوب لإضافة خطك',
        );
        if (!mounted || !ok || !PublisherAuthController.shared.isLoggedIn) {
          return;
        }
      }
      if (!_isEditing &&
          !widget.draftOnly &&
          auth.isLoggedIn) {
        final mine = await PublisherRepository.shared.myListings();
        if (mine.length >= PublisherLimits.maxActiveListings) {
          if (!mounted) return;
          setState(() => _saving = false);
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('وصلت للحد الأقصى'),
              content: Text(PublisherLimits.limitReachedMessage),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('حسناً'),
                ),
              ],
            ),
          );
          return;
        }
      }

      final seats = int.tryParse(_seats.text.trim());
      final draft = Listing(
        id: _editingId ?? '',
        type: _type,
        area: _area.text.trim(),
        destination: _destination.text.trim(),
        originSubs: List<String>.from(_originSubs),
        destinationSubs: List<String>.from(_destinationSubs),
        timePeriod: _timePeriod!,
        departureTime: _departureTime.text.trim().isEmpty
            ? null
            : _departureTime.text.trim(),
        returnTime:
            _returnTime.text.trim().isEmpty ? null : _returnTime.text.trim(),
        genderRequirement: _gender,
        vehicleType: _vehicle.text.trim(),
        seatsCount: seats,
        contactPhone: phone.isEmpty ? null : phone,
        contactTelegram: telegram.isEmpty ? null : telegram,
      );

      if (widget.draftOnly) {
        final draftWithId = draft.copyWith(
          id: (_editingId != null && _editingId!.isNotEmpty)
              ? _editingId
              : draft.id,
        );
        if (!mounted) return;
        Navigator.of(context).pop(draftWithId);
        return;
      }

      if (_isEditing) {
        final updated = await widget.repository.update(draft);
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(updated);
        }
      } else if (widget.asDirectoryRequest) {
        var created = await widget.repository.submitRequest(
          draft.copyWith(
            type: ListingType.driver,
            status: ListingStatus.pendingReview,
            governorate: 'بغداد',
            ownerAccountId: auth.accountId,
          ),
        );
        if (auth.isLoggedIn) {
          try {
            created =
                await PublisherRepository.shared.claimListing(created.id);
          } on PostgrestException catch (e) {
            if (e.message.toUpperCase().contains('LISTING_LIMIT')) {
              try {
                await widget.repository.deleteById(created.id);
              } catch (_) {}
              if (mounted) {
                await showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('وصلت للحد الأقصى'),
                    content: Text(PublisherLimits.limitReachedMessage),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('حسناً'),
                      ),
                    ],
                  ),
                );
              }
              return;
            }
          } catch (_) {}
        }
        if (!mounted) return;
        await _showRequestSubmitted(created);
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(created);
        }
      } else {
        // Admin / legacy direct publish → live in directory.
        var created = await widget.repository.insert(
          draft.copyWith(status: ListingStatus.published),
        );
        if (auth.isLoggedIn) {
          try {
            created =
                await PublisherRepository.shared.claimListing(created.id);
          } on PostgrestException catch (e) {
            if (e.message.toUpperCase().contains('LISTING_LIMIT')) {
              try {
                await widget.repository.deleteById(created.id);
              } catch (_) {}
              if (mounted) {
                await showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('وصلت للحد الأقصى'),
                    content: Text(PublisherLimits.limitReachedMessage),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('حسناً'),
                      ),
                    ],
                  ),
                );
              }
              return;
            }
          } catch (_) {}
        }
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(created);
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showRequestSubmitted(Listing created) async {
    final c = context.colors;
    final ref = created.referenceCode ?? created.id;
    final days = ListingSubscription.periodDays;
    final hideFees = DirectoryLaunch.hidePaymentCopy;
    final message = hideFees
        ? 'مرحباً، أرسلت طلب نشر خط في دليل خطوط بغداد.\n'
            'رقم الطلب: $ref\n'
            'المسار: ${created.area} ← ${created.destination}\n'
            'التوقيت: ${created.timePeriodLabel}\n'
            'صلاحية الظهور بعد النشر: $days يوماً، ثم أجدّد النشر بعدها.\n'
            'أرجو مراجعة الطلب وإعلامي عند الجاهزية للنشر.'
        : 'مرحباً، أرسلت طلب نشر خط في دليل خطوط بغداد.\n'
            'رقم الطلب: $ref\n'
            'المسار: ${created.area} ← ${created.destination}\n'
            'التوقيت: ${created.timePeriodLabel}\n'
            'صلاحية الظهور بعد النشر: $days يوماً ثم التجديد.\n'
            'أرجو مراجعة الطلب وإعلامي بخطوات الدفع.';
    final steps = hideFees
        ? '1) تراجع الإدارة الطلب\n'
            '2) قد نتواصل معك عبر واتساب أو تلغرام عند الحاجة\n'
            '3) بعد الموافقة يُنشر الخط في الدليل لمدة $days يوماً\n'
            '4) بعد انتهاء المدة عليك تجديد النشر ليبقى ظاهراً'
        : '1) تراجع الإدارة الطلب\n'
            '2) تُكمل دفع رسوم النشر عبر واتساب أو تلغرام\n'
            '3) بعد تأكيد الدفع يُنشر الخط لمدة $days يوماً\n'
            '4) بعد انتهاء المدة عليك تجديد النشر ليبقى ظاهراً';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'تم إرسال طلبك للمراجعة',
            style: GoogleFonts.ibmPlexSansArabic(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'رقم الطلب: $ref',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  steps,
                  style: GoogleFonts.ibmPlexSansArabic(height: 1.5),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: message));
                    final uri = Uri.parse(AdminContact.whatsappUrl(message));
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('متابعة عبر واتساب'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: message));
                    final uri = Uri.parse(AdminContact.telegram);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('متابعة عبر تلغرام'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: message));
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم نسخ تفاصيل الطلب',
                            style: GoogleFonts.ibmPlexSansArabic(),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('نسخ تفاصيل الطلب'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('تم'),
            ),
          ],
        );
      },
    );
  }

  SnackBar _toast(String message) {
    final c = context.colors;
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.primary,
      content: Text(
        message,
        style: GoogleFonts.ibmPlexSansArabic(
          fontWeight: FontWeight.w400,
          color: c.onPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.draftOnly
              ? ((widget.initial?.id.isNotEmpty ?? false)
                  ? 'تعديل بيانات الخط'
                  : 'تعديل المسودة')
              : widget.asDirectoryRequest
                  ? 'أضف خطك للدليل'
                  : (_isEditing ? 'تعديل الإعلان' : 'نشر إعلان'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 6, 14, 28),
              children: [
            Text(
              widget.asDirectoryRequest
                  ? 'أدخل تفاصيل خطك ليظهر في الدليل لمدة ${ListingSubscription.periodDays} يوماً، ثم جدّد النشر بعدها'
                  : 'أدخل تفاصيل الخط',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12,
                height: 1.45,
                color: c.text.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 14),
            SuggestibleTextField(
              fieldKey: const Key('field_area'),
              label: 'المنطقة التي ينطلق منها الخط',
              controller: _area,
              validator: _placeRequired,
              options: _knownAreas,
              addMissingLabel: BaghdadPlaces.addMissingArea,
              hint: _listedOnlyPlaces
                  ? 'اختر من القائمة'
                  : 'اكتب بحرية أو اختر من القائمة',
              listedOnly: _listedOnlyPlaces,
              maxLength: _mainPlaceMaxLength,
              inputFormatters: [
                PlaceTextInputFormatter(
                  maxLength: _mainPlaceMaxLength,
                  singleOnly: _listedOnlyPlaces,
                  maxWords: _mainPlaceTypingMaxWords,
                  lettersWordsOnly: _listedOnlyPlaces,
                ),
              ],
            ),
            const SizedBox(height: 10),
            SuggestibleTextField(
              fieldKey: const Key('field_destination'),
              label: 'المنطقة التي يصل اليها الخط',
              controller: _destination,
              validator: _destinationRequired,
              options: _knownDestinations,
              addMissingLabel: BaghdadPlaces.addMissingDestination,
              hint: _listedOnlyPlaces
                  ? 'اختر من القائمة'
                  : 'اكتب بحرية أو اختر من القائمة',
              listedOnly: _listedOnlyPlaces,
              maxLength: _mainPlaceMaxLength,
              inputFormatters: [
                PlaceTextInputFormatter(
                  maxLength: _mainPlaceMaxLength,
                  singleOnly: _listedOnlyPlaces,
                  maxWords: _mainPlaceTypingMaxWords,
                  lettersWordsOnly: _listedOnlyPlaces,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SubPlacesBlock(
              title: 'عناوين فرعية ينطلق منها الخط (اختياري)',
              hint:
                  'اذكر الأحياء أو الشوارع التي يمر بها الخط داخل منطقة الانطلاق',
              field: SuggestibleTextField(
                fieldKey: const Key('field_origin_sub'),
                label: '',
                controller: _originSubInput,
                hint: 'مثال: حي الجامعة',
                options: _knownAreas,
                addMissingLabel: BaghdadPlaces.addMissingArea,
                validator: _placeOptional,
                maxLength: PlaceTextRules.subMaxLength,
                subordinate: true,
                onCommitted: (_) => _addToList(
                  _originSubInput,
                  _originSubs,
                  (next) => _originSubs = next,
                  asArea: true,
                ),
                inputFormatters: const [
                  PlaceTextInputFormatter(maxLength: PlaceTextRules.subMaxLength),
                ],
              ),
              chips: _originSubs.isEmpty
                  ? null
                  : _SubChips(
                      items: _originSubs,
                      onRemove: (v) => _removeFromList(
                        v,
                        _originSubs,
                        (next) => _originSubs = next,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            _SubPlacesBlock(
              title: 'عناوين فرعية يصل إليها الخط (اختياري)',
              hint:
                  'اذكر الأحياء أو الشوارع التي يصل إليها الخط داخل الوجهة',
              field: SuggestibleTextField(
                fieldKey: const Key('field_destination_sub'),
                label: '',
                controller: _destinationSubInput,
                hint: 'مثال: مجمع الجادرية',
                options: _knownDestinations,
                addMissingLabel: BaghdadPlaces.addMissingDestination,
                validator: _placeOptional,
                maxLength: PlaceTextRules.subMaxLength,
                subordinate: true,
                onCommitted: (_) => _addToList(
                  _destinationSubInput,
                  _destinationSubs,
                  (next) => _destinationSubs = next,
                  asArea: false,
                ),
                inputFormatters: const [
                  PlaceTextInputFormatter(maxLength: PlaceTextRules.subMaxLength),
                ],
              ),
              chips: _destinationSubs.isEmpty
                  ? null
                  : _SubChips(
                      items: _destinationSubs,
                      onRemove: (v) => _removeFromList(
                        v,
                        _destinationSubs,
                        (next) => _destinationSubs = next,
                      ),
                    ),
            ),
            if (_originSubs.isNotEmpty || _destinationSubs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 10),
                child: Text(
                  '${_originSubs.isEmpty ? '—' : _originSubs.join('، ')}  ←  ${_destinationSubs.isEmpty ? '—' : _destinationSubs.join('، ')}',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    height: 1.4,
                    color: c.primary.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            _Field(
              fieldKey: const Key('field_vehicle'),
              label: 'نوع السيارة',
              controller: _vehicle,
              validator: _required,
            ),
            const SizedBox(height: 10),
            _Field(
              fieldKey: const Key('field_seats'),
              label: 'عدد المقاعد',
              controller: _seats,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTheme.manrope(fontSize: 14, color: c.text),
              validator: _required,
            ),
            const SizedBox(height: 10),
            Text('التوقيت', style: _sectionLabel(c)),
            const SizedBox(height: 2),
            Text(
              'صباحي أو مسائي — إلزامي',
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: c.text.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _ChoiceChip(
                    label: 'صباحي',
                    selected: _timePeriod == TimePeriod.morning,
                    onTap: () =>
                        setState(() => _timePeriod = TimePeriod.morning),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ChoiceChip(
                    label: 'مسائي',
                    selected: _timePeriod == TimePeriod.evening,
                    onTap: () =>
                        setState(() => _timePeriod = TimePeriod.evening),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                leading: Icon(Icons.tune_rounded, color: c.primary, size: 22),
                title: Text('فلاتر إضافية', style: _sectionLabel(c)),
                subtitle: Text(
                  'الجنس · ساعات الانطلاق والعودة (اختياري)',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w400,
                    fontSize: 11,
                    color: c.text.withValues(alpha: 0.5),
                  ),
                ),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('الجنس المطلوب', style: _sectionLabel(c)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final option in GenderRequirement.values) ...[
                        if (option != GenderRequirement.values.first)
                          const SizedBox(width: 6),
                        Expanded(
                          child: _ChoiceChip(
                            label: switch (option) {
                              GenderRequirement.femaleOnly => 'اناث',
                              GenderRequirement.maleOnly => 'ذكور',
                              GenderRequirement.mixed => 'مختلط',
                            },
                            selected: _gender == option,
                            onTap: () => setState(() => _gender = option),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('ساعات الانطلاق والعودة', style: _sectionLabel(c)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          fieldKey: const Key('field_departure'),
                          label: 'ساعة الانطلاق (اختياري)',
                          controller: _departureTime,
                          hint: '7:30',
                          style: AppTheme.manrope(fontSize: 14, color: c.text),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Field(
                          fieldKey: const Key('field_return'),
                          label: 'ساعة العودة (اختياري)',
                          controller: _returnTime,
                          hint: '2:00',
                          style: AppTheme.manrope(fontSize: 14, color: c.text),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('وسيلة التواصل', style: _sectionLabel(c)),
            const SizedBox(height: 2),
            Text(
              'واتساب أو تلغرام — واحد منهما على الأقل',
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w400,
                fontSize: 11,
                color: c.text.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            _Field(
              fieldKey: const Key('field_phone'),
              label: 'واتساب (رقم أو يوزر)',
              controller: _phone,
              keyboardType: TextInputType.text,
              hint: '07XXXXXXXXX أو @username',
              style: AppTheme.manrope(fontSize: 14, color: c.text),
            ),
            const SizedBox(height: 10),
            _Field(
              fieldKey: const Key('field_telegram'),
              label: 'تلغرام (رابط أو يوزر)',
              controller: _telegram,
              hint: '@user أو https://t.me/...',
              style: AppTheme.manrope(fontSize: 14, color: c.text),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.ibmPlexSansArabic(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.onPrimary,
                        ),
                      )
                    : Text(
                        _isEditing
                            ? 'حفظ التعديل'
                            : (widget.asDirectoryRequest
                                ? 'إرسال للمراجعة'
                                : 'نشر'),
                      ),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _sectionLabel(MasaratColors c) {
    return GoogleFonts.ibmPlexSansArabic(
      fontWeight: FontWeight.w600,
      fontSize: 11,
      color: c.text.withValues(alpha: 0.5),
    );
  }
}

/// Nested block so sub-place fields read as secondary to the main places.
class _SubPlacesBlock extends StatelessWidget {
  const _SubPlacesBlock({
    required this.title,
    required this.hint,
    required this.field,
    this.chips,
  });

  final String title;
  final String hint;
  final Widget field;
  final Widget? chips;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 10),
      padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.text.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(8),
        border: BorderDirectional(
          start: BorderSide(
            color: c.primary.withValues(alpha: 0.28),
            width: 2.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: c.text.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hint,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w400,
              fontSize: 11,
              height: 1.35,
              color: c.text.withValues(alpha: 0.52),
            ),
          ),
          const SizedBox(height: 6),
          field,
          if (chips != null) ...[
            const SizedBox(height: 4),
            chips!,
          ],
        ],
      ),
    );
  }
}
class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected
          ? c.primary.withValues(alpha: 0.12)
          : c.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? c.primary.withValues(alpha: 0.7)
                  : c.border.withValues(alpha: 0.85),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
              color: selected ? c.primary : c.text.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    this.fieldKey,
    required this.label,
    required this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.style,
  });

  final Key? fieldKey;
  final String label;
  final TextEditingController controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(8);
    final base = style ??
        GoogleFonts.ibmPlexSansArabic(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        );
    final textStyle = base.copyWith(color: style?.color ?? c.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.ibmPlexSansArabic(
            fontWeight: FontWeight.w600,
            fontSize: 10,
            color: c.text.withValues(alpha: 0.48),
          ),
        ),
        const SizedBox(height: 3),
        TextFormField(
          key: fieldKey,
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: textStyle,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w400,
              fontSize: 11,
              color: c.text.withValues(alpha: 0.35),
            ),
            isDense: true,
            filled: true,
            fillColor: c.surface.withValues(alpha: 0.92),
            contentPadding: const EdgeInsetsDirectional.fromSTEB(8, 6, 8, 6),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.border.withValues(alpha: 0.8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.border.withValues(alpha: 0.8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.primary.withValues(alpha: 0.8)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: c.riderAccent),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubChips extends StatelessWidget {
  const _SubChips({
    required this.items,
    required this.onRemove,
  });

  final List<String> items;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final item in items)
            InputChip(
              label: Text(
                item,
                style: GoogleFonts.ibmPlexSansArabic(fontSize: 12),
              ),
              onDeleted: () => onRemove(item),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              deleteIconColor: c.text.withValues(alpha: 0.5),
              side: BorderSide(color: c.border.withValues(alpha: 0.85)),
              backgroundColor: c.surface.withValues(alpha: 0.92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }
}
