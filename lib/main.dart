import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app.dart';
import 'core/config/supabase_config.dart';
import 'core/di/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final container = ProviderContainer();
  await bootstrapSettings(container);

  runApp(UncontrolledProviderScope(
    container: container,
    child: const MindFlowApp(),
  ));
}
