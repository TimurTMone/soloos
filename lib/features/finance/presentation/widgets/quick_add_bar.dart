import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

class QuickAddBar extends StatefulWidget {
  final bool isLoading;
  final void Function(String text) onSubmit;
  final VoidCallback? onManualAdd;

  const QuickAddBar({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    this.onManualAdd,
  });

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final _ctrl = TextEditingController();

  static const _hints = [
    'e.g. "I earn \$3000/month freelancing"',
    'e.g. "Spent \$12 on lunch"',
    'e.g. "I owe John \$500"',
    'e.g. "Spotify \$10/month"',
    'e.g. "YouTube revenue \$800/month"',
    'e.g. "Got paid \$2000 for app dev"',
    'e.g. "Chalet booking \$500"',
    'e.g. "Rent \$800 every month"',
  ];

  int _hintIndex = 0;

  @override
  void initState() {
    super.initState();
    _cycleHint();
  }

  void _cycleHint() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
      _cycleHint();
    });
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.isLoading) return;
    widget.onSubmit(text);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A3E), width: 1),
        ),
      ),
      child: Row(
        children: [
          if (widget.onManualAdd != null) ...[
            SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                onPressed: widget.onManualAdd,
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 24),
                padding: EdgeInsets.zero,
                tooltip: 'Add manually',
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: TextField(
                key: ValueKey(_hintIndex),
                controller: _ctrl,
                enabled: !widget.isLoading,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: _hints[_hintIndex],
                  hintStyle: const TextStyle(
                      color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('✨', style: TextStyle(fontSize: 16)),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 0),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 11),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 40,
            height: 40,
            child: widget.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Icon(Icons.arrow_upward, size: 18),
                  ),
          ),
        ],
      ),
    );
  }
}
