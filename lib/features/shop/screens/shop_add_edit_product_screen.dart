import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:judo_app/core/constants/app_colors.dart';
import 'package:judo_app/core/models/shop_product_model.dart';
import 'package:judo_app/core/utils/cloudinary_upload.dart';
import 'package:judo_app/features/shop/providers/shop_provider.dart';
import 'package:judo_app/shared/widgets/gradient_button.dart';

class ShopAddEditProductScreen extends ConsumerStatefulWidget {
  const ShopAddEditProductScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ShopAddEditProductScreen> createState() =>
      _ShopAddEditProductScreenState();
}

class _ShopAddEditProductScreenState
    extends ConsumerState<ShopAddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _oldPriceCtrl = TextEditingController();
  final _coachNoteCtrl = TextEditingController();

  ShopCategory _category = ShopCategory.merch;
  ShopBadge? _badge;
  bool _isActive = true;
  bool _isFeatured = false;
  bool _isNew = false;
  bool _isInStock = true;

  List<String> _imageUrls = [];
  List<ShopProductVariant> _variants = [];

  bool _initialized = false;
  bool _saving = false;
  bool _uploadingPhoto = false;

  bool get _isEdit => widget.productId != null;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _oldPriceCtrl.dispose();
    _coachNoteCtrl.dispose();
    super.dispose();
  }

  void _initFromProduct(ShopProduct p) {
    if (_initialized) return;
    _initialized = true;
    _titleCtrl.text = p.title;
    _descCtrl.text = p.description;
    _priceCtrl.text = p.price.toStringAsFixed(0);
    _oldPriceCtrl.text = p.oldPrice?.toStringAsFixed(0) ?? '';
    _coachNoteCtrl.text = p.coachNote ?? '';
    _category = p.category;
    _badge = p.badge;
    _isActive = p.isActive;
    _isFeatured = p.isFeatured;
    _isNew = p.isNew;
    _isInStock = p.isInStock;
    _imageUrls = List<String>.from(p.imageUrls);
    _variants = List<ShopProductVariant>.from(p.variants);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit) {
      final productAsync =
          ref.watch(shopProductProvider(widget.productId!));

      return productAsync.when(
        loading: () => Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (e, _) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(),
          body: Center(
            child: Text('Помилка: $e',
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ),
        data: (product) {
          if (product != null) _initFromProduct(product);
          return _buildScaffold();
        },
      );
    }

    return _buildScaffold();
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      title: Text(
        _isEdit ? 'Редагувати товар' : 'Додати товар',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            _sectionHeader('Основна інформація'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _titleCtrl,
              label: 'Назва товару',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Обов\'язкове поле' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descCtrl,
              label: 'Опис',
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            _buildCategoryDropdown(),
            const SizedBox(height: 20),
            _sectionHeader('Ціна'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceCtrl,
                    label: 'Ціна (грн)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'))
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Обов\'язкове поле';
                      }
                      if (double.tryParse(v) == null) {
                        return 'Невірний формат';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _oldPriceCtrl,
                    label: 'Стара ціна (грн)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'))
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            Builder(builder: (_) {
              final price = double.tryParse(_priceCtrl.text.trim());
              final old = double.tryParse(_oldPriceCtrl.text.trim());
              if (price != null && old != null && old > price) {
                final pct = ((old - price) / old * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-$pct% знижка',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 20),
            _sectionHeader('Мітки та налаштування'),
            const SizedBox(height: 12),
            _buildBadgeDropdown(),
            const SizedBox(height: 16),
            _buildSwitchRow('Активний', _isActive,
                (v) => setState(() => _isActive = v)),
            _buildSwitchRow('Рекомендований', _isFeatured,
                (v) => setState(() => _isFeatured = v)),
            _buildSwitchRow('Новинка', _isNew,
                (v) => setState(() => _isNew = v)),
            _buildSwitchRow('В наявності', _isInStock,
                (v) => setState(() => _isInStock = v)),
            const SizedBox(height: 20),
            _sectionHeader('Нотатка тренера'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _coachNoteCtrl,
              label: 'Нотатка тренера (необов\'язково)',
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            _buildVariantsSection(),
            const SizedBox(height: 20),
            _buildImageUrlsSection(),
            const SizedBox(height: 28),
            GradientButton(
              isLoading: _saving,
              onPressed: _saving ? null : _save,
              child: Text(
                _isEdit ? 'Зберегти зміни' : 'Додати товар',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.accent,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<ShopCategory>(
      initialValue: _category,
      dropdownColor: AppColors.surface2,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Категорія',
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: ShopCategory.values.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Text('${c.emoji} ${c.label}'),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _category = v);
      },
    );
  }

  Widget _buildBadgeDropdown() {
    return DropdownButtonFormField<ShopBadge?>(
      initialValue: _badge,
      dropdownColor: AppColors.surface2,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Мітка',
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: [
        const DropdownMenuItem<ShopBadge?>(
          value: null,
          child: Text('Без мітки'),
        ),
        ...ShopBadge.values.map((b) {
          return DropdownMenuItem<ShopBadge?>(
            value: b,
            child: Text(b.label),
          );
        }),
      ],
      onChanged: (v) => setState(() => _badge = v),
    );
  }

  Widget _buildSwitchRow(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionHeader('Варіанти (${_variants.length})'),
              const Spacer(),
              TextButton.icon(
                onPressed: _addVariant,
                icon: const Icon(Icons.add,
                    size: 18, color: AppColors.accent),
                label: const Text(
                  'Додати варіант',
                  style: TextStyle(color: AppColors.accent, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (_variants.isNotEmpty) ...[
            const SizedBox(height: 10),
            ..._variants.asMap().entries.map((entry) {
              final i = entry.key;
              final v = entry.value;
              return _VariantRow(
                variant: v,
                onEdit: () => _editVariant(i),
                onDelete: () => setState(() => _variants.removeAt(i)),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildImageUrlsSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionHeader('Фото (${_imageUrls.length})'),
              const Spacer(),
              TextButton.icon(
                onPressed: (_uploadingPhoto || _saving) ? null : _addImageUrl,
                icon: const Icon(Icons.link,
                    size: 18, color: AppColors.textSecondary),
                label: const Text(
                  'URL',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: (_uploadingPhoto || _saving) ? null : _uploadPhoto,
                icon: _uploadingPhoto
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      )
                    : const Icon(Icons.upload_outlined,
                        size: 18, color: AppColors.accent),
                label: const Text(
                  'Завантажити',
                  style: TextStyle(color: AppColors.accent, fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          if (_imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _imageUrls.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  if (i == _imageUrls.length) {
                    return GestureDetector(
                      onTap: (_uploadingPhoto || _saving) ? null : _uploadPhoto,
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AppColors.accent, size: 22),
                            SizedBox(height: 4),
                            Text(
                              'Додати',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final url = _imageUrls[i];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: url.startsWith('assets/')
                            ? Image.asset(
                                url,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              )
                            : CachedNetworkImage(
                                imageUrl: url,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 90,
                                  height: 90,
                                  color: AppColors.surface2,
                                  child: const Icon(Icons.image_outlined,
                                      color: AppColors.textSecondary),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  width: 90,
                                  height: 90,
                                  color: AppColors.surface2,
                                  child: const Icon(Icons.broken_image_outlined,
                                      color: AppColors.error),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _imageUrls.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final productId = widget.productId ?? const Uuid().v4();
      final publicId =
          'shop_products/${productId}_${DateTime.now().millisecondsSinceEpoch}';
      final url = await uploadImageToCloudinary(bytes, publicId);
      setState(() => _imageUrls.add(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка завантаження: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _addImageUrl() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _ImageUrlDialog(controller: ctrl),
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() => _imageUrls.add(result.trim()));
    }
  }

  void _addVariant() async {
    final productId = widget.productId ?? 'new';
    final result = await showDialog<ShopProductVariant>(
      context: context,
      builder: (_) => _VariantDialog(
        productId: productId,
      ),
    );
    if (result != null) {
      setState(() => _variants.add(result));
    }
  }

  void _editVariant(int index) async {
    final result = await showDialog<ShopProductVariant>(
      context: context,
      builder: (_) => _VariantDialog(
        productId: widget.productId ?? 'new',
        existing: _variants[index],
      ),
    );
    if (result != null) {
      setState(() => _variants[index] = result);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final price = double.parse(_priceCtrl.text.trim());
      final oldPriceText = _oldPriceCtrl.text.trim();
      final oldPrice =
          oldPriceText.isNotEmpty ? double.tryParse(oldPriceText) : null;
      final coachNote = _coachNoteCtrl.text.trim();

      if (_isEdit) {
        final existingAsync =
            ref.read(shopProductProvider(widget.productId!));
        final existing = existingAsync.valueOrNull;

        final product = ShopProduct(
          id: widget.productId!,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _category,
          price: price,
          oldPrice: oldPrice,
          imageUrls: _imageUrls,
          badge: _badge,
          isActive: _isActive,
          isFeatured: _isFeatured,
          isNew: _isNew,
          isInStock: _isInStock,
          coachNote: coachNote.isEmpty ? null : coachNote,
          variants: _variants,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        );

        await ref
            .read(shopNotifierProvider.notifier)
            .updateProduct(product);
      } else {
        final id = const Uuid().v4();
        final product = ShopProduct(
          id: id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _category,
          price: price,
          oldPrice: oldPrice,
          imageUrls: _imageUrls,
          badge: _badge,
          isActive: _isActive,
          isFeatured: _isFeatured,
          isNew: _isNew,
          isInStock: _isInStock,
          coachNote: coachNote.isEmpty ? null : coachNote,
          variants: _variants,
          createdAt: now,
          updatedAt: now,
        );

        await ref
            .read(shopNotifierProvider.notifier)
            .addProduct(product);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.variant,
    required this.onEdit,
    required this.onDelete,
  });

  final ShopProductVariant variant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (variant.size != null && variant.size!.isNotEmpty) {
      parts.add('Розмір: ${variant.size}');
    }
    if (variant.color != null && variant.color!.isNotEmpty) {
      parts.add('Колір: ${variant.color}');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (parts.isNotEmpty)
                  Text(
                    parts.join(' / '),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  'Залишок: ${variant.stockQuantity}'
                  '${variant.priceModifier != 0 ? ' · +${variant.priceModifier.toStringAsFixed(0)} грн' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.textSecondary),
            onPressed: onEdit,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.error),
            onPressed: onDelete,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
          ),
        ],
      ),
    );
  }
}

class _VariantDialog extends StatefulWidget {
  const _VariantDialog({required this.productId, this.existing});

  final String productId;
  final ShopProductVariant? existing;

  @override
  State<_VariantDialog> createState() => _VariantDialogState();
}

class _VariantDialogState extends State<_VariantDialog> {
  final _sizeCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _modifierCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _sizeCtrl.text = widget.existing!.size ?? '';
      _colorCtrl.text = widget.existing!.color ?? '';
      _stockCtrl.text = widget.existing!.stockQuantity.toString();
      _modifierCtrl.text = widget.existing!.priceModifier != 0
          ? widget.existing!.priceModifier.toStringAsFixed(0)
          : '';
    } else {
      _stockCtrl.text = '0';
    }
  }

  @override
  void dispose() {
    _sizeCtrl.dispose();
    _colorCtrl.dispose();
    _stockCtrl.dispose();
    _modifierCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing != null
                  ? 'Редагувати варіант'
                  : 'Додати варіант',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _field(_sizeCtrl, 'Розмір (напр. M, 160)'),
            const SizedBox(height: 10),
            _field(_colorCtrl, 'Колір (необов\'язково)'),
            const SizedBox(height: 10),
            _field(
              _stockCtrl,
              'Кількість на складі',
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 10),
            _field(
              _modifierCtrl,
              'Цінова надбавка (грн)',
              keyboardType: TextInputType.number,
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]'))
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Скасувати',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _submit,
                    child: const Text('Зберегти'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  void _submit() {
    final size = _sizeCtrl.text.trim();
    final color = _colorCtrl.text.trim();
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    final modifier =
        double.tryParse(_modifierCtrl.text.trim()) ?? 0.0;

    final variant = ShopProductVariant(
      id: widget.existing?.id ?? const Uuid().v4(),
      productId: widget.productId,
      size: size.isEmpty ? null : size,
      color: color.isEmpty ? null : color,
      stockQuantity: stock,
      priceModifier: modifier,
    );

    Navigator.of(context).pop(variant);
  }
}

class _ImageUrlDialog extends StatelessWidget {
  const _ImageUrlDialog({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Додати URL фото',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Для завантаження фото використовуйте Cloudinary',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'https://res.cloudinary.com/...',
                hintStyle: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.borderSoft),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.borderSoft),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Скасувати',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () =>
                        Navigator.of(context).pop(controller.text),
                    child: const Text('Додати'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
