import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/listing.dart';
import '../../../core/theme/app_colors.dart';
import 'gallery_image_save.dart';
import 'listing_share_poster.dart';

Future<void> openShareListingCardPage(
  BuildContext context,
  Listing listing,
) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ShareListingCardPage(listing: listing),
    ),
  );
}

/// Full-screen card preview: رجوع + حفظ الصورة على الهاتف فقط.
class ShareListingCardPage extends StatefulWidget {
  const ShareListingCardPage({super.key, required this.listing});

  final Listing listing;

  @override
  State<ShareListingCardPage> createState() => _ShareListingCardPageState();
}

class _ShareListingCardPageState extends State<ShareListingCardPage> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;
  bool _preparing = true;
  Uint8List? _pngBytes;
  String _fileName = 'khutoot_card.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _precacheBrand();
      if (mounted) await _preparePng();
    });
  }

  Future<void> _precacheBrand() async {
    try {
      await precacheImage(
        const AssetImage(ListingSharePoster.appIconAsset),
        context,
      );
    } catch (_) {
      try {
        await precacheImage(
          const AssetImage('assets/branding/brand-mark.png'),
          context,
        );
      } catch (_) {}
    }
  }

  Future<void> _preparePng() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(Duration(milliseconds: i == 0 ? 120 : 50));
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) continue;
      try {
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final png = bytes?.buffer.asUint8List();
        if (png != null && png.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _pngBytes = png;
            _fileName =
                'khutoot_${DateTime.now().millisecondsSinceEpoch}.png';
            _preparing = false;
          });
          return;
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _preparing = false);
  }

  Future<void> _ensureReady() async {
    if (_pngBytes != null) return;
    setState(() {
      _busy = true;
      _preparing = true;
    });
    await _preparePng();
    if (mounted) setState(() => _busy = false);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg, style: GoogleFonts.ibmPlexSansArabic()),
      ),
    );
  }

  Future<void> _onSave() async {
    if (_busy) return;
    await _ensureReady();
    final bytes = _pngBytes;
    if (!mounted || bytes == null) {
      _toast('تعذّر تجهيز الصورة');
      return;
    }

    setState(() => _busy = true);
    try {
      final outcome = await savePngToGallery(
        bytes: bytes,
        filename: _fileName,
      );
      if (!mounted) return;
      switch (outcome) {
        case GallerySaveOutcome.savedToGallery:
          _toast('تم حفظ الصورة في الاستوديو');
        case GallerySaveOutcome.downloaded:
          _toast('تم حفظ الصورة على الهاتف');
        case GallerySaveOutcome.openedShareSheet:
        case GallerySaveOutcome.dismissed:
          break;
        case GallerySaveOutcome.failed:
          _toast('تعذّر حفظ الصورة');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const posterW = 360.0;
    final ready = _pngBytes != null && !_preparing;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1413),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0B1413),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            tooltip: 'رجوع',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          title: Text(
            widget.listing.isDriver ? 'بطاقة الخط' : 'بطاقة الراكب',
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: -10000,
                    top: 0,
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: ListingSharePoster(
                        listing: widget.listing,
                        width: posterW,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: ready && _pngBytes != null
                        ? Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(
                                _pngBytes!,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          )
                        : Center(
                            child: SingleChildScrollView(
                              child: ListingSharePoster(
                                listing: widget.listing,
                                width: posterW,
                              ),
                            ),
                          ),
                  ),
                  if (_preparing)
                    Positioned(
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'جاري تجهيز الصورة…',
                              style: GoogleFonts.ibmPlexSansArabic(
                                color: Colors.white,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF102221),
                  border: Border(
                    top: BorderSide(color: c.border.withValues(alpha: 0.2)),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'احفظ البطاقة كصورة على هاتفك',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSansArabic(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: (_busy || _preparing) ? null : _onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFC5A059),
                          foregroundColor: const Color(0xFF102221),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_rounded),
                        label: Text(
                          'حفظ الصورة على الهاتف',
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
