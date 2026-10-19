import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await dotenv.load(fileName: '.env');
  final url = (dotenv.env['SUPABASE_URL'] ?? dotenv.env['URL'] ?? '').trim();
  final key = (dotenv.env['SUPABASE_ANON_KEY'] ??
          dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
          dotenv.env['SUPABASE_PUBLICK_KEY'] ??
          dotenv.env['PublishableKeySupabase'] ??
          '')
      .trim();

  if (url.isEmpty || key.isEmpty) {
    throw StateError(
      'Заполните SUPABASE_URL и SUPABASE_ANON_KEY в файле .env '
      '(Project URL + anon / publishable key из Supabase → API).',
    );
  }
  if (url.contains('your-project') ||
      key.contains('your_publishable') ||
      key.contains('your_anon')) {
    throw StateError(
      'В .env до сих пор заглушки. Подставьте реальный Project URL и ключ.',
    );
  }
  if (key.startsWith('sb_secret_') || key.contains('service_role')) {
    throw StateError(
      'В клиентском .env нельзя класть secret/service_role. '
      'Используйте anon key (eyJ...) или sb_publishable_...',
    );
  }

  await Supabase.initialize(url: url, anonKey: key);
}

SupabaseClient get supabase => Supabase.instance.client;