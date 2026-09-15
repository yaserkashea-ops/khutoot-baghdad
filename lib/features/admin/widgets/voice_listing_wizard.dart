import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/import/listing_text_parser.dart';
import '../../../core/import/voice_listing_commands.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/voice/web_speech_recognition.dart';

class VoiceWizardResult {
  const VoiceWizardResult({
    required this.draft,
    required this.publishNow,
  });

  final ParsedListingDraft draft;
  final bool publishNow;
}

/// Guided structured voice capture.
Future<VoiceWizardResult?> showVoiceListingWizard(BuildContext context) {
  return showModalBottomSheet<VoiceWizardResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _VoiceListingWizard(),
  );
}

class _VoiceListingWizard extends StatefulWidget {
  const _VoiceListingWizard();

  @override
  State<_VoiceListingWizard> createState() => _VoiceListingWizardState();
}

class _VoiceListingWizardState extends State<_VoiceListingWizard> {
  final _draft = VoiceListingDraft();
  final _manual = TextEditingController();
  final _scroll = ScrollController();

  int _stepIndex = 0;
  bool _listening = false;
  String? _heard;
  String? _error;
  String _mode = 'guided';

  List<VoiceListingStep> get _steps =>
      [..._draft.steps, VoiceListingStep.done];

  VoiceListingStep get _step => _steps[_stepIndex.clamp(0, _steps.length - 1)];

  bool get _speechOk => kIsWeb && WebSpeechRecognition.isSupported;

  bool get _canFinish => _draft.isComplete && _draft.toListing() != null;

  @override
  void dispose() {
    WebSpeechRecognition.cancel();
    _manual.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _listenAndApply() async {
    if (!_speechOk) {
      setState(() {
        _error =
            'التعرّف الصوتي يحتاج متصفح Chrome على الويب مع إذن الميكروفون';
      });
      return;
    }
    setState(() {
      _listening = true;
      _error = null;
      _heard = null;
    });
    final text = await WebSpeechRecognition.listenOnce(lang: 'ar-IQ');
    if (!mounted) return;
    setState(() => _listening = false);
    if (text == null || text.trim().isEmpty) {
      setState(() => _error = 'لم يُلتقط كلام — حاول مجدداً قرب الميكروفون');
      return;
    }
    setState(() => _heard = text);
    _applyTranscript(text);
  }

  void _applyTranscript(String text) {
    if (_mode == 'oneshot') {
      final parsed = VoiceListingCommands.parseStructuredLine(text);
      if (parsed == null) {
        setState(() {
          _error =
              'لم تُفهم الجملة. مثال: سائق من العامرية الى الجادرية صباحي مختلط رقم …';
        });
        return;
      }
      _copyDraft(parsed);
      setState(() {
        _stepIndex = _steps.length - 1;
        _error = null;
      });
      _scrollToActions();
      return;
    }

    if (_step == VoiceListingStep.done) return;

    final result = VoiceListingCommands.parseStep(_step, text);
    if (!result.isOk) {
      setState(() => _error = result.error);
      return;
    }
    if (!result.skipped) {
      VoiceListingCommands.apply(_draft, _step, result.value);
    } else {
      VoiceListingCommands.apply(_draft, _step, null);
    }
    setState(() {
      _error = null;
      _manual.clear();
      if (_stepIndex < _steps.length - 1) {
        _stepIndex++;
        if (_stepIndex >= _steps.length) {
          _stepIndex = _steps.length - 1;
        }
      }
    });
    if (_step == VoiceListingStep.done || _canFinish) {
      _scrollToActions();
    }
  }

  void _copyDraft(VoiceListingDraft parsed) {
    _draft
      ..type = parsed.type
      ..area = parsed.area
      ..originSubs = List<String>.from(parsed.originSubs)
      ..destination = parsed.destination
      ..destinationSubs = List<String>.from(parsed.destinationSubs)
      ..period = parsed.period
      ..gender = parsed.gender
      ..phone = parsed.phone
      ..telegram = parsed.telegram
      ..vehicle = parsed.vehicle
      ..seats = parsed.seats;
  }

  void _scrollToActions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _applyManual() {
    final t = _manual.text.trim();
    if (t.isEmpty) return;
    setState(() => _heard = t);
    _applyTranscript(t);
  }

  void _back() {
    if (_stepIndex <= 0) return;
    setState(() {
      _stepIndex--;
      _error = null;
      _heard = null;
    });
  }

  void _finish({required bool publishNow}) {
    final listing = _draft.toListing();
    if (listing == null) {
      setState(() => _error = 'أكمل النوع والمنطقة والوجهة أولاً');
      return;
    }
    final warnings = <String>[];
    if (_draft.period == null) warnings.add('التوقيت افترض صباحي');
    if (_draft.gender == null) warnings.add('الفئة افترضت مختلط');
    if ((listing.contactPhone ?? '').isEmpty &&
        (listing.contactTelegram ?? '').isEmpty) {
      warnings.add('لا يوجد رقم أو تلغرام');
    }
    Navigator.of(context).pop(
      VoiceWizardResult(
        draft: ParsedListingDraft(
          sourceText: 'أوامر صوتية: ${_draft.summaryLines.join(' · ')}',
          listing: listing,
          warnings: warnings,
          selected: true,
        ),
        publishNow: publishNow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final step = _step;
    final progress = (_stepIndex + 1) / _steps.length;
    final height = MediaQuery.sizeOf(context).height * 0.92;

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'أوامر صوتية منظمة',
              style: GoogleFonts.ibmPlexSansArabic(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'خطوات دقيقة بالعربية — الأفضل على Chrome',
              style: GoogleFonts.ibmPlexSansArabic(
                fontSize: 12.5,
                color: c.text.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'guided', label: Text('خطوة بخطوة')),
                ButtonSegment(value: 'oneshot', label: Text('جملة واحدة')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) {
                if (s.isEmpty) return;
                setState(() {
                  _mode = s.first;
                  _error = null;
                  _heard = null;
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: _scroll,
                children: [
                  if (_mode == 'guided') ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: c.border.withValues(alpha: 0.5),
                        color: c.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'الخطوة ${_stepIndex + 1} من ${_steps.length}: ${step.title}',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        step.prompt,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'قل جملة واحدة:\n'
                        'سائق من [منطقة] الى [وجهة] صباحي مختلط رقم […] تلغرام […]\n'
                        'ويمكن إضافة: يمر حي الجامعة و الخضراء',
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (_heard != null) ...[
                    Text(
                      'سمعت: $_heard',
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        color: c.text.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: GoogleFonts.ibmPlexSansArabic(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (step != VoiceListingStep.done || _mode == 'oneshot') ...[
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _listening ? null : _listenAndApply,
                        icon: Icon(
                          _listening ? Icons.hearing : Icons.mic,
                          size: 22,
                        ),
                        label: Text(
                          _listening ? 'جارٍ الاستماع…' : 'اضغط وتكلم',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _manual,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _applyManual(),
                      decoration: InputDecoration(
                        labelText: 'أو اكتب الرد يدوياً',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          onPressed: _applyManual,
                          icon: const Icon(Icons.check),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'الملخص',
                    style: GoogleFonts.ibmPlexSansArabic(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ..._draft.summaryLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        line,
                        style: GoogleFonts.ibmPlexSansArabic(
                          fontSize: 12.5,
                          color: c.text.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_mode == 'guided' && _stepIndex > 0)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton(
                        onPressed: _listening ? null : _back,
                        child: const Text('رجوع'),
                      ),
                    ),
                  if (_mode == 'guided' &&
                      step != VoiceListingStep.done &&
                      step.isOptional) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed:
                          _listening ? null : () => _applyTranscript('تخطي'),
                      child: const Text('تخطي هذه الخطوة'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Always visible action area when data is enough.
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _canFinish
                              ? 'البيانات كافية — أكمل الإجراء:'
                              : 'أكمل النوع + المنطقة + الوجهة لتفعيل أزرار النشر',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _canFinish
                                ? c.primary
                                : c.text.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _canFinish && !_listening
                                ? () => _finish(publishNow: false)
                                : null,
                            icon: const Icon(Icons.playlist_add_check),
                            label: Text(
                              'أضف للمسودات',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _canFinish && !_listening
                                ? () => _finish(publishNow: true)
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: c.accent,
                              foregroundColor: c.onPrimary,
                              disabledBackgroundColor:
                                  c.border.withValues(alpha: 0.5),
                            ),
                            icon: const Icon(Icons.publish_outlined),
                            label: Text(
                              'أضف وانشر مباشرة',
                              style: GoogleFonts.ibmPlexSansArabic(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
