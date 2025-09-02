import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'join_expert_page.dart';
import 'provider/join_expert_provider.dart';

class JoinExpertDemo extends StatelessWidget {
  const JoinExpertDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JoinExpertProvider(),
      child: const JoinExpertPage(),
    );
  }
}
