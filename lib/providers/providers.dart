import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models.dart';
import '../data/repositories.dart';

final supabaseProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authRepoProvider =
    Provider((ref) => AuthRepository(ref.watch(supabaseProvider)));
final listingRepoProvider =
    Provider((ref) => ListingRepository(ref.watch(supabaseProvider)));
final chatRepoProvider =
    Provider((ref) => ChatRepository(ref.watch(supabaseProvider)));

final categoryFilterProvider = StateProvider<String>((ref) => 'الكل');
final searchQueryProvider = StateProvider<String>((ref) => '');

final listingsProvider = FutureProvider.autoDispose<List<Listing>>((ref) {
  final category = ref.watch(categoryFilterProvider);
  final query = ref.watch(searchQueryProvider);
  return ref
      .watch(listingRepoProvider)
      .fetch(category: category, query: query);
});

final myListingsProvider = FutureProvider.autoDispose<List<Listing>>(
    (ref) => ref.watch(listingRepoProvider).mine());

final listingProvider = FutureProvider.autoDispose.family<Listing, String>(
    (ref, id) => ref.watch(listingRepoProvider).byId(id));

final messagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>(
        (ref, listingId) => ref.watch(chatRepoProvider).stream(listingId));
