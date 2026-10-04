class Listing {
  final String id;
  final String userId;
  final String title;
  final String description;
  final double? price;
  final String category;
  final String city;
  final String? imageUrl;
  final DateTime createdAt;

  const Listing({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.city,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Listing.fromMap(Map<String, dynamic> m) {
    return Listing(
      id: m['id'].toString(),
      userId: (m['user_id'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      price: m['price'] == null ? null : (m['price'] as num).toDouble(),
      category: (m['category'] ?? 'أخرى').toString(),
      city: (m['city'] ?? '').toString(),
      imageUrl: m['image_url'] as String?,
      createdAt: DateTime.tryParse((m['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class ChatMessage {
  final String id;
  final String listingId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.listingId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) {
    return ChatMessage(
      id: m['id'].toString(),
      listingId: m['listing_id'].toString(),
      senderId: m['sender_id'].toString(),
      content: (m['content'] ?? '').toString(),
      createdAt: DateTime.tryParse((m['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

const List<String> kCategories = [
  'إلكترونيات',
  'أثاث',
  'ملابس',
  'سيارات',
  'كتب',
  'أخرى',
];
