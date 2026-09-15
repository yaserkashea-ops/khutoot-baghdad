import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/baghdad_places.dart';
import '../../../core/theme/app_colors.dart';

/// Place-options popup anchored to a field via [targetKey] geometry.
class PlaceOptionsMenuController {
  PlaceOptionsMenuController();

  /// Attach this key to the field widget that the menu should sit under.
  final GlobalKey targetKey = GlobalKey();

  OverlayEntry? _entry;
  OverlayState? _overlay;
  bool _showAll = true;
  bool _framePinned = false;

  List<String> Function()? _optionsOf;
  String Function()? _queryOf;
  String? _leadingOption;
  double _maxHeight = 220;
  ValueChanged<String>? _onSelected;
  VoidCallback? _onChanged;
  Object? _tapRegionGroupId;

  bool get isOpen => _entry != null;

  void dispose() => close();

  void close() {
    _framePinned = false;
    _entry?.remove();
    _entry = null;
    _overlay = null;
    _optionsOf = null;
    _queryOf = null;
    _onSelected = null;
    _onChanged = null;
    _tapRegionGroupId = null;
  }

  void toggle({
    required BuildContext context,
    required double width,
    required List<String> Function() optionsOf,
    required String Function() queryOf,
    required ValueChanged<String> onSelected,
    String? leadingOption,
    double maxHeight = 220,
    VoidCallback? onChanged,
    Object? tapRegionGroupId,
    bool keepFocus = false,
  }) {
    if (isOpen) {
      close();
      onChanged?.call();
      return;
    }
    open(
      context: context,
      width: width,
      optionsOf: optionsOf,
      queryOf: queryOf,
      onSelected: onSelected,
      leadingOption: leadingOption,
      maxHeight: maxHeight,
      onChanged: onChanged,
      tapRegionGroupId: tapRegionGroupId,
      keepFocus: keepFocus,
      showAll: true,
    );
  }

  void open({
    required BuildContext context,
    required double width,
    required List<String> Function() optionsOf,
    required String Function() queryOf,
    required ValueChanged<String> onSelected,
    String? leadingOption,
    double maxHeight = 220,
    VoidCallback? onChanged,
    Object? tapRegionGroupId,
    bool keepFocus = false,
    bool showAll = true,
  }) {
    if (!keepFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    close();
    _showAll = showAll;
    _maxHeight = maxHeight;
    _optionsOf = optionsOf;
    _queryOf = queryOf;
    _leadingOption = leadingOption;
    _onSelected = onSelected;
    _onChanged = onChanged;
    _tapRegionGroupId = tapRegionGroupId;

    _overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(builder: _buildOverlay);
    _overlay!.insert(_entry!);
    _framePinned = true;
    _scheduleFramePin();
    onChanged?.call();
  }

  void refilter() {
    if (!isOpen) return;
    _showAll = false;
    _entry?.markNeedsBuild();
  }

  void _scheduleFramePin() {
    if (!_framePinned || _entry == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_framePinned || _entry == null) return;
      _entry!.markNeedsBuild();
      _scheduleFramePin();
    });
  }

  Rect? _targetRectInOverlay() {
    final targetCtx = targetKey.currentContext;
    final overlay = _overlay;
    if (targetCtx == null || overlay == null) return null;
    final targetBox = targetCtx.findRenderObject() as RenderBox?;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (targetBox == null ||
        overlayBox == null ||
        !targetBox.hasSize ||
        !overlayBox.hasSize) {
      return null;
    }
    final topLeft = targetBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    return topLeft & targetBox.size;
  }

  Widget _buildOverlay(BuildContext ctx) {
    final c = ctx.colors;
    final rect = _targetRectInOverlay();
    if (rect == null) return const SizedBox.shrink();

    final options = _optionsOf?.call() ?? const <String>[];
    final query = _queryOf?.call() ?? '';
    final leading = _leadingOption;
    final items = _visibleOptions(
      options: options,
      query: query,
      leadingOption: leading,
    );
    final onSelected = _onSelected;
    final onChanged = _onChanged;
    final groupId = _tapRegionGroupId;

    // Keep menu on-screen vertically when near the bottom.
    final overlayBox = _overlay!.context.findRenderObject() as RenderBox;
    final overlayH = overlayBox.size.height;
    final spaceBelow = overlayH - (rect.bottom + 4);
    final openUpward = spaceBelow < 120 && rect.top > spaceBelow;
    final maxH = _maxHeight.clamp(80.0, openUpward ? rect.top - 8 : spaceBelow);
    final top = openUpward
        ? (rect.top - maxH - 4).clamp(0.0, overlayH)
        : rect.bottom + 4;

    Widget menu = Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: c.surface,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: rect.width,
        child: items.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'لا توجد نتائج',
                  style: GoogleFonts.ibmPlexSansArabic(
                    fontSize: 13,
                    color: c.text.withValues(alpha: 0.55),
                  ),
                ),
              )
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxH),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: c.border.withValues(alpha: 0.8),
                  ),
                  itemBuilder: (context, index) {
                    final option = items[index];
                    final isLeading = option == leading;
                    return InkWell(
                      onTap: () {
                        close();
                        onSelected?.call(option);
                        onChanged?.call();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Text(
                          option,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.ibmPlexSansArabic(
                            fontWeight:
                                isLeading ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 14,
                            color: isLeading ? c.primary : c.text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );

    if (groupId != null) {
      menu = TapRegion(groupId: groupId, child: menu);
    }

    return Positioned(
      left: rect.left,
      top: top,
      width: rect.width,
      child: menu,
    );
  }

  List<String> _visibleOptions({
    required List<String> options,
    required String query,
    String? leadingOption,
  }) {
    final seen = <String>{};
    final pool = <String>[];
    for (final o in options) {
      if (seen.add(o)) pool.add(o);
    }
    final q = query.trim();
    final matched = (_showAll || q.isEmpty)
        ? pool
        : pool.where((o) => BaghdadPlaces.matchesQuery(o, q)).toList();
    if (leadingOption == null) return matched;
    return [
      leadingOption,
      ...matched.where((o) => o != leadingOption),
    ];
  }
}
