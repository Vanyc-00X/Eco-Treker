import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await dotenv.load(fileName: '.env');
  final url = dotenv.env['SUPABASE_URL'] ?? dotenv.env['URL'];
  final key =
      dotenv.env['SUPABASE_ANON_KEY'] ?? dotenv.env['PublishableKeySupabase'];

  if (url == null || url.isEmpty || key == null || key.isEmpty) {
    throw StateError('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
  }

  await Supabase.initialize(url: url, publishableKey: key);
}

SupabaseClient get supabase => Supabase.instance.client;