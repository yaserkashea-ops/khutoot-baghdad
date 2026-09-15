import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/baghdad_places.dart';
import '../../../core/theme/app_colors.dart';

/// Shared place-options popup via Overlay.
/// Arrow can open the full list without keyboard; typing can open filtered suggestions
/// while keeping field focus.
class PlaceOptionsMenuController {
  PlaceOptionsMenuController();

  final LayerLink layerLink = LayerLink();
  OverlayEntry? _entry;
  bool _showAll = true;

  List<String> Function()? _optionsOf;
  String Function()? _queryOf;
  String? _leadingOption;
  double _width = 280;
  double _maxHeight = 220;
  ValueChanged<String>? _onSelected;
  VoidCallback? _onChanged;
  Object? _tapRegionGroupId;

  bool get isOpen => _entry != null;

  void dispose() => close();

  void close() {
    _entry?.remove();
    _entry = null;
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
    _width = width;
    _maxHeight = maxHeight;
    _optionsOf = optionsOf;
    _queryOf = queryOf;
    _leadingOption = leadingOption;
    _onSelected = onSelected;
    _onChanged = onChanged;
    _tapRegionGroupId = tapRegionGroupId;

    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context, rootOverlay: true).insert(_entry!);
    onChanged?.call();
  }

  /// Call after typing so an open menu refilters live.
  void refilter() {
    if (!isOpen) return;
    _showAll = false;
    _entry?.markNeedsBuild();
  }

  Widget _buildOverlay(BuildContext ctx) {
    final c = ctx.colors;
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

    Widget menu = Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      color: c.surface,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: _width,
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
                constraints: BoxConstraints(maxHeight: _maxHeight),
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

    return CompositedTransformFollower(
      link: layerLink,
      showWhenUnlinked: false,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 4),
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
