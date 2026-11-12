import 'dart:io';

void main() {
  final path = 'lib/review_idea_screen.dart';
  final bytes = File(path).readAsBytesSync();
  final text = String.fromCharCodes(bytes);

  // Find the catch block and replace the whole span with a clean version
  // that uses only ASCII characters.
  final start = text.indexOf('    } catch (e) {');
  if (start == -1) {
    print('catch block not found');
    return;
  }
  final end = text.indexOf('\n  Widget _actionButton({', start);
  if (end == -1) {
    print('end marker not found');
    return;
  }

  const replacement = '''    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackbar(
        Snack(
          content: Text('Evaluation failed: \$e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  ''';

  final fixed = text.substring(0, start) + replacement + text.substring(end);
  File(path).writeAsStringSync(fixed);
  print('rewrote catch block region');
}