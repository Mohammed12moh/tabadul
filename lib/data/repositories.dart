import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class AuthRepository {
  AuthRepository(this._c);
  final SupabaseClient _c;

  Future<void> signIn(String email, String password) async {
    await _c.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _c.auth.signUp(email: email.trim(), password: password);
  }

  Future<void> signOut() => _c.auth.signOut();
}

class ListingRepository {
  ListingRepository(this._c);
  final SupabaseClient _c;

  Future<List<Listing>> fetch({String? category, String? query}) async {
    try {
      var q = _c.from('listings').select();
      if (category != null && category.isNotEmpty && category != 'الكل') {
        q = q.eq('category', category);
      }
      final text = (query ?? '').trim();
      if (text.isNotEmpty) {
        final safe = text.replaceAll(RegExp(r'[%_,()]'), ' ');
        q = q.ilike('title', '%$safe%');
      }
      final rows = await q.order('created_at', ascending: false).limit(100);
      return rows.map<Listing>((r) => Listing.fromMap(r)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<List<Listing>> mine() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return [];
    try {
      final rows = await _c
          .from('listings')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      return rows.map<Listing>((r) => Listing.fromMap(r)).toList();
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Listing> byId(String id) async {
    try {
      final row = await _c.from('listings').select().eq('id', id).single();
      return Listing.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<String?> uploadImage(Uint8List bytes) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return null;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await _c.storage.from('listings').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      return _c.storage.from('listings').getPublicUrl(path);
    } on StorageException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> create({
    required String title,
    required String description,
    required double? price,
    required String category,
    required String city,
    String? imageUrl,
  }) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw Exception('يجب تسجيل الدخول أولاً');
    try {
      await _c.from('listings').insert({
        'user_id': uid,
        'title': title.trim(),
        'description': description.trim(),
        'price': price,
        'category': category,
        'city': city.trim(),
        'image_url': imageUrl,
      });
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _c.from('listings').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}

class ChatRepository {
  ChatRepository(this._c);
  final SupabaseClient _c;

  Stream<List<ChatMessage>> stream(String listingId) {
    return _c
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('listing_id', listingId)
        .order('created_at', ascending: true)
        .map((rows) => rows.map(ChatMessage.fromMap).toList());
  }

  Future<void> send(String listingId, String content) async {
    final uid = _c.auth.currentUser?.id;
    final text = content.trim();
    if (uid == null || text.isEmpty) return;
    if (text.length > 1000) throw Exception('الرسالة طويلة جداً');
    try {
      await _c.from('messages').insert({
        'listing_id': listingId,
        'sender_id': uid,
        'content': text,
      });
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    }
  }
}
