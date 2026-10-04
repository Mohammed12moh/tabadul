import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../providers/providers.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(listingProvider(id));
    final uid = ref.watch(supabaseProvider).auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الإعلان')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('تعذّر تحميل الإعلان\n$e')),
        data: (item) {
          final isOwner = uid == item.userId;
          return ListView(
            children: [
              if (item.imageUrl != null)
                CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox(
                      height: 260,
                      child: Center(child: Icon(Icons.broken_image_outlined))),
                )
              else
                Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_outlined,
                      size: 64, color: Colors.grey),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      Chip(label: Text(item.category)),
                      if (item.city.isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.location_on_outlined,
                              size: 16),
                          label: Text(item.city),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      item.price == null
                          ? 'للتبادل'
                          : '${item.price!.toStringAsFixed(0)} ر.س',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy/MM/dd').format(item.createdAt.toLocal()),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                    const Divider(height: 32),
                    Text(item.description.isEmpty
                        ? 'لا يوجد وصف'
                        : item.description),
                    const SizedBox(height: 32),
                    FilledButton.icon(
                      onPressed: () => context.push('/chat/${item.id}'),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(isOwner ? 'رسائل الإعلان' : 'تواصل مع البائع'),
                    ),
                    if (isOwner) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () => _confirmDelete(context, ref, item),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('حذف الإعلان'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Listing item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(listingRepoProvider).delete(item.id);
      ref.invalidate(listingsProvider);
      ref.invalidate(myListingsProvider);
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تعذّر الحذف: $e')));
      }
    }
  }
}

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});

  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  String _category = kCategories.first;
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _price.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        _toast('حجم الصورة كبير (الحد الأقصى 5 ميغابايت)');
        return;
      }
      setState(() => _imageBytes = bytes);
    } catch (_) {
      _toast('تعذّر اختيار الصورة');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(listingRepoProvider);
      String? url;
      if (_imageBytes != null) url = await repo.uploadImage(_imageBytes!);
      final priceText = _price.text.trim();
      await repo.create(
        title: _title.text,
        description: _desc.text,
        price: priceText.isEmpty ? null : double.parse(priceText),
        category: _category,
        city: _city.text,
        imageUrl: url,
      );
      ref.invalidate(listingsProvider);
      ref.invalidate(myListingsProvider);
      if (mounted) context.pop();
    } catch (e) {
      _toast('تعذّر نشر الإعلان: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعلان جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _saving ? null : _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: _imageBytes == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 44),
                          SizedBox(height: 8),
                          Text('أضف صورة (اختياري)'),
                        ],
                      )
                    : Image.memory(_imageBytes!,
                        fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'العنوان'),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.length < 3) return 'العنوان قصير جداً';
                return null;
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'التصنيف'),
              items: kCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'السعر (اتركه فارغاً للتبادل)',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                final n = double.tryParse(t);
                if (n == null || n < 0 || n > 100000000) {
                  return 'سعر غير صالح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _city,
              maxLength: 40,
              decoration: const InputDecoration(labelText: 'المدينة'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _desc,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'الوصف',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('نشر الإعلان'),
            ),
          ],
        ),
      ),
    );
  }
}
