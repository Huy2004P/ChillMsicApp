import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/localization/localization_extension.dart';

// ==========================================
// 1. BUTTONS (MetaButton)
// ==========================================
enum MetaButtonType {
  primary,   // Marketing black pill
  buyCta,    // Cobalt blue primary pill
  secondary, // Outlined thick border black
  ghost,     // Quieter outlined variant
}

class MetaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final MetaButtonType type;
  final IconData? icon;

  const MetaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = MetaButtonType.primary,
    this.icon,
  });

  @override
  State<MetaButton> createState() => _MetaButtonState();
}

class _MetaButtonState extends State<MetaButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    Color bg;
    Color textCol;
    Border? border;

    switch (widget.type) {
      case MetaButtonType.primary:
        bg = isDisabled
            ? AppColors.stone
            : (_isPressed ? AppColors.charcoal : AppColors.inkDeep);
        textCol = AppColors.canvas;
        break;
      case MetaButtonType.buyCta:
        bg = isDisabled
            ? AppColors.stone
            : (_isPressed ? AppColors.primaryDeep : AppColors.primary);
        textCol = AppColors.canvas;
        break;
      case MetaButtonType.secondary:
        bg = Colors.transparent;
        textCol = isDisabled ? AppColors.stone : AppColors.inkDeep;
        border = Border.all(
          color: isDisabled ? AppColors.stone : AppColors.inkDeep,
          width: 2.0,
        );
        break;
      case MetaButtonType.ghost:
        bg = Colors.transparent;
        textCol = isDisabled ? AppColors.stone : AppColors.inkDeep;
        border = Border.all(
          color: isDisabled ? AppColors.stone : const Color(0x1E0A1317), // rgba(10, 19, 23, 0.12)
          width: 2.0,
        );
        break;
    }

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(100), // {rounded.full}
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 16, color: textCol),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: AppTypography.buttonMd.copyWith(color: textCol),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. CIRCULAR ICON BUTTON (button-icon-circular)
// ==========================================
class MetaIconCircularButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;

  const MetaIconCircularButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 40.0,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  State<MetaIconCircularButton> createState() => _MetaIconCircularButtonState();
}

class _MetaIconCircularButtonState extends State<MetaIconCircularButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColors.canvas,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairlineSoft, width: 1),
          boxShadow: _isPressed
              ? [
                  const BoxShadow(
                    color: Color(0x3314161A), // rgba(20, 22, 26, 0.2)
                    offset: Offset(1, 1),
                    blurRadius: 0,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Icon(
          widget.icon,
          size: widget.size * 0.5,
          color: widget.iconColor ?? AppColors.inkDeep,
        ),
      ),
    );
  }
}

// ==========================================
// 3. PILL TAB NAVIGATION (PillTabNav)
// ==========================================
class PillTabNav extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const PillTabNav({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  String _translateCategory(BuildContext context, String cat) {
    if (cat == 'Discover') return context.tr('tab_discover');
    if (cat == 'My Playlist') return context.tr('tab_my_playlist');
    if (cat == 'Charts') return context.tr('tab_charts');
    if (cat == 'Mặc định') return context.tr('default_preset');
    if (cat == 'Lofi Thư giãn') return context.tr('lofi_relax_preset');
    if (cat == 'Tăng Bass (Bass Boost)') return context.tr('bass_boost_preset');
    if (cat == 'Tùy chỉnh') return context.tr('custom_preset');
    return cat;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final isSelected = cat == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: () => onSelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.inkDeep : AppColors.canvas,
                  borderRadius: BorderRadius.circular(100),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.hairline, width: 1),
                ),
                child: Text(
                  _translateCategory(context, cat),
                  style: AppTypography.bodySmBold.copyWith(
                    color: isSelected ? AppColors.canvas : AppColors.ink,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ==========================================
// 4. SEARCH PILL (search-pill)
// ==========================================
class SearchPill extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const SearchPill({
    super.key,
    required this.onChanged,
    this.onSubmitted,
    this.hintText = 'Tìm kiếm bài hát, ca sĩ...',
    this.controller,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(100), // {rounded.full}
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search, color: AppColors.slate, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: AppTypography.bodySm.copyWith(color: AppColors.inkDeep),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.bodySm.copyWith(color: AppColors.steel),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 5. RADIO OPTION WIDGET (radio-option)
// ==========================================
class RadioOptionWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailingLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const RadioOptionWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailingLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.canvas.withAlpha(AppColors.isDarkMode ? 115 : 166),
          borderRadius: BorderRadius.circular(8), // {rounded.lg}
          border: isSelected
              ? Border.all(color: AppColors.primaryDeep, width: 2.0)
              : Border.all(color: const Color(0x1E0A1317), width: 1.0), // 1px hairline soft
        ),
        child: Row(
          children: [
            // Radio circle
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryDeep : AppColors.steel,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmBold.copyWith(
                      color: isSelected ? AppColors.primaryDeep : AppColors.inkDeep,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(color: AppColors.charcoal),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                trailingLabel,
                style: AppTypography.captionBold.copyWith(
                  color: isSelected ? AppColors.primaryDeep : AppColors.steel,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. TECHNICAL SPECS TABLE (tech-specs-table)
// ==========================================
class SpecsTable extends StatelessWidget {
  final Map<String, String> specs;

  const SpecsTable({super.key, required this.specs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: specs.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.hairlineSoft, width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: AppTypography.bodySmBold.copyWith(color: AppColors.ink),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  entry.value,
                  style: AppTypography.bodySm.copyWith(color: AppColors.charcoal),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ==========================================
// 7. FAQ ACCORDION (faq-accordion)
// ==========================================
class FaqAccordionItem extends StatefulWidget {
  final String question;
  final String answer;

  const FaqAccordionItem({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  State<FaqAccordionItem> createState() => _FaqAccordionItemState();
}

class _FaqAccordionItemState extends State<FaqAccordionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.hairlineSoft, width: 1),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpand,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: AppTypography.subtitleLg.copyWith(
                        fontSize: 16,
                        color: AppColors.inkDeep,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_animation),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.steel,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _animation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.answer,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.charcoal,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
