import 'dart:io';

void main() {
  final path = 'lib/review_idea_screen.dart';
  final bytes = File(path).readAsBytesSync();
  final text = String.fromCharCodes(bytes);

  // Fix the catch block: replace the misspelled showSnackbar/Snackbar/AppColors.error
  // with the correct showSnackbar/Snackbar/AppColors.danger, and remove the
  // stray _severityColor method that references the now-removed FindingSeverity.
  final bad = '''      ScaffoldMessenger.of(context).showSnackbar(
        Snack(
          content: Text('Evaluation failed: \$e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Color _severityColor(FindingSeverity s) {
    return switch (s) {
      FindingSeverity.critical => AppColors.danger,
      FindingSeverity.major => AppColors.warning,
      FindingSeverity.minor => AppColors.textSoft,
      FindingSeverity.suggestion => AppColors.accent,
    };
  }

  Widget _actionButton({'''

  final good = '''      ScaffoldMessenger.of(context).showSnackbar(
        Snack(
          content: Text('Evaluation failed: \$e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _actionButton({'''

  if (!text.contains(bad)) {
    print('PATTERN NOT FOUND');
    return;
  }
  final fixed = text.replaceFirst(bad, good);
  File(path).writeAsStringSync(fixed);
  print('FIXED');
}