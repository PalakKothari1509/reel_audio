import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {}

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    
    children.add(const Text('Test'));
    children.add(const SizedBox(height: 16));
    
    // Test spread with if
    if (true) {
      children.add(const Text('Test'));
    }
    
    // Test spread with for loop
    for (int i = 0; i < 3; i++) {
      children.add(Text('Item $i'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}