import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_palette.dart';

/// The design's 50×28 toggle — accent track when on, `neutral-400` when off,
/// a white 22px thumb with a soft shadow.
///
/// [onChanged] null draws it without taking taps. [busy] dims it while the
/// change it started is on its way, so a second tap cannot race the first.
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool busy;

  const AppSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.busy = false,
  });

  static const Duration _duration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tappable = onChanged != null && !busy;

    return Semantics(
      toggled: value,
      enabled: tappable,
      child: GestureDetector(
        onTap: tappable ? () => onChanged!(!value) : null,
        child: AnimatedOpacity(
          duration: _duration,
          opacity: busy ? .5 : 1,
          child: AnimatedContainer(
            duration: _duration,
            width: 50.r,
            height: 28.r,
            padding: EdgeInsets.all(3.r),
            decoration: BoxDecoration(
              color: value ? p.accent : p.line2,
              borderRadius: BorderRadius.circular(999),
            ),
            child: AnimatedAlign(
              duration: _duration,
              // The design justifies the thumb to flex-end when on — the
              // right in LTR, the left in RTL: the end, either way.
              alignment: value
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Container(
                width: 22.r,
                height: 22.r,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
