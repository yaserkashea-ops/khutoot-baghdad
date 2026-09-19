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
  ScrollController? _scrollController;
  bool _showAll = true;
  bool _framePinned = false;
  Rect? _lastRect;

  List<String> Function()? _optionsOf;
  String Function()? _queryOf;
  String? _leadingOption;
  String? _trailingOption;
  double _maxHeight = 220;
  ValueChanged<String>? _onSelected;
  ValueChanged<String>? _onArmSelect;
  VoidCallback? _onCancelArm;
  VoidCallback? _onChanged;
  Object? _tapRegionGroupId;

  bool get isOpen => _entry != null;

  void dispose() => close();

  void close() {
    _framePinned = false;
    _lastRect = null;
    _entry?.remove();
    _entry = null;
    _overlay = null;
    _scrollController?.dispose();
    _scrollController = null;
    _optionsOf = null;
    _queryOf = null;
    _leadingOption = null;
    _trailingOption = null;
    _onSelected = null;
    _onArmSelect = null;
    _onCancelArm = null;
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
    String? trailingOption,
    double maxHeight = 220,
    VoidCallback? onChanged,
    ValueChanged<String>? onArmSelect,
    VoidCallback? onCancelArm,
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
      trailingOption: trailingOption,
      maxHeight: maxHeight,
      onChanged: onChanged,
      onArmSelect: onArmSelect,
      onCancelArm: onCancelArm,
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
    String? trailingOption,
    double maxHeight = 220,
    VoidCallback? onChanged,
    ValueChanged<String>? onArmSelect,
    VoidCallback? onCancelArm,
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
    _trailingOption = trailingOption;
    _onSelected = onSelected;
    _onArmSelect = onArmSelect;
    _onCancelArm = onCancelArm;
    _onChanged = onChanged;
    _tapRegionGroupId = tapRegionGroupId;
    _scrollController = ScrollController();

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
    // Keep scroll offset when the filtered set shrinks/grows.
    _entry?.markNeedsBuild();
  }

  void _scheduleFramePin() {
    if (!_framePinned || _entry == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_framePinned || _entry == null) return;
      final rect = _targetRectInOverlay();
      // Only rebuild when the anchor moves (keyboard/layout) — rebuilding every
      // frame was resetting scroll and closing the browse gesture.
      if (rect != _lastRect) {
        _lastRect = rect;
        _entry!.markNeedsBuild();
      }
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
    final targetGlobal = targetBox.localToGlobal(Offset.zero);
    final overlayGlobal = overlayBox.localToGlobal(Offset.zero);
    final topLeft = targetGlobal - overlayGlobal;
    return topLeft & targetBox.size;
  }

  void _pick(String option) {
    final onSelected = _onSelected;
    final onChanged = _onChanged;
    // Call selection BEFORE removing the overlay — removing mid-gesture
    // can cancel InkWell onTap on Flutter web.
    onSelected?.call(option);
    close();
    onChanged?.call();
  }

  Widget _buildOverlay(BuildContext ctx) {
    final c = ctx.colors;
    final rect = _targetRectInOverlay();
    if (rect == null) return const SizedBox.shrink();

    final options = _optionsOf?.call() ?? const <String>[];
    final query = _queryOf?.call() ?? '';
    final leading = _leadingOption;
    final trailing = _trailingOption;
    final items = _visibleOptions(
      options: options,
      query: query,
      leadingOption: leading,
      trailingOption: trailing,
    );
    final groupId = _tapRegionGroupId;
    final scroll = _scrollController;

    final overlayBox = _overlay!.context.findRenderObject() as RenderBox;
    final keyboard = MediaQuery.viewInsetsOf(ctx).bottom;
    final overlayH = overlayBox.size.height;
    final usableBottom = overlayH - keyboard;
    final spaceBelow = (usableBottom - rect.bottom - 4).clamp(0.0, overlayH);
    final spaceAbove = (rect.top - 4).clamp(0.0, overlayH);
    final openUpward = spaceBelow < 140 && spaceAbove > spaceBelow;
    final available = openUpward ? spaceAbove : spaceBelow;
    final maxH = available <= 0
        ? _maxHeight
        : (available < 48 ? available : available.clamp(48.0, _maxHeight));
    if (maxH < 40) return const SizedBox.shrink();

    final top = openUpward
        ? (rect.top - maxH - 4).clamp(0.0, usableBottom)
        : (rect.bottom + 4).clamp(0.0, usableBottom);

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
                  controller: scroll,
                  primary: false,
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: c.border.withValues(alpha: 0.8),
                  ),
                  itemBuilder: (context, index) {
                    final option = items[index];
                    final isLeading = option == leading;
                    final isTrailing = option == trailing;
                    return _PlaceOptionTile(
                      label: option,
                      emphasize: isLeading || isTrailing,
                      emphasizeColor: c.primary,
                      textColor: c.text,
                      onArm: () => _onArmSelect?.call(option),
                      onCancelArm: () => _onCancelArm?.call(),
                      onPick: () => _pick(option),
                    );
                  },
                ),
              ),
      ),
    );

    if (groupId != null) {
      menu = TapRegion(groupId: groupId, child: menu);
    }

    // Absorb vertical drag so the page behind does not steal the scroll.
    return Positioned(
      left: rect.left,
      top: top,
      width: rect.width,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) => true,
        child: menu,
      ),
    );
  }

  List<String> _visibleOptions({
    required List<String> options,
    required String query,
    String? leadingOption,
    String? trailingOption,
  }) {
    final seen = <String>{};
    final pool = <String>[];
    for (final o in options) {
      if (o == trailingOption) continue;
      if (seen.add(o)) pool.add(o);
    }
    final q = query.trim();
    final matched = (_showAll || q.isEmpty)
        ? pool
        : pool.where((o) => BaghdadPlaces.matchesQuery(o, q)).toList();
    final out = <String>[];
    if (leadingOption != null) {
      out.add(leadingOption);
      out.addAll(matched.where((o) => o != leadingOption));
    } else {
      out.addAll(matched);
    }
    // Always offer admin contact when searching or browsing the full list.
    if (trailingOption != null &&
        (_showAll || q.isNotEmpty) &&
        !out.contains(trailingOption)) {
      out.add(trailingOption);
    }
    return out;
  }
}

/// Fills on pointer-down (beats web IME/focus race); cancels if the user scrolls.
class _PlaceOptionTile extends StatefulWidget {
  const _PlaceOptionTile({
    required this.label,
    required this.onPick,
    required this.onArm,
    required this.onCancelArm,
    required this.emphasize,
    required this.emphasizeColor,
    required this.textColor,
  });

  final String label;
  final VoidCallback onPick;
  final VoidCallback onArm;
  final VoidCallback onCancelArm;
  final bool emphasize;
  final Color emphasizeColor;
  final Color textColor;

  @override
  State<_PlaceOptionTile> createState() => _PlaceOptionTileState();
}

class _PlaceOptionTileState extends State<_PlaceOptionTile> {
  static const _tapSlop = 18.0;
  Offset? _down;
  bool _moved = false;
  bool _armed = false;
  bool _picked = false;

  void _reset() {
    _down = null;
    _moved = false;
    _armed = false;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) {
          _down = e.position;
          _moved = false;
          _picked = false;
          _armed = true;
          // Apply the suggestion immediately — before focus/IME can lock the prefix.
          widget.onArm();
        },
        onPointerMove: (e) {
          final start = _down;
          if (start == null || _moved) return;
          if ((e.position - start).distance > _tapSlop) {
            _moved = true;
            if (_armed) {
              _armed = false;
              widget.onCancelArm();
            }
          }
        },
        onPointerUp: (e) {
          final start = _down;
          final wasTap = start != null &&
              !_moved &&
              (e.position - start).distance <= _tapSlop;
          final shouldPick = wasTap && _armed && !_picked;
          _reset();
          if (shouldPick) {
            _picked = true;
            widget.onPick();
          }
        },
        onPointerCancel: (_) {
          if (_armed) widget.onCancelArm();
          _reset();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          child: Text(
            widget.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.ibmPlexSansArabic(
              fontWeight:
                  widget.emphasize ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
              color: widget.emphasize ? widget.emphasizeColor : widget.textColor,
            ),
          ),
        ),
      ),
    );
  }
}
