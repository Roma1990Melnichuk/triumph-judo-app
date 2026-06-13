import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:judo_app/core/constants/app_colors.dart';
import 'package:judo_app/core/models/child_model.dart';
import 'package:judo_app/core/models/club_post_model.dart';
import 'package:judo_app/core/utils/cloudinary_upload.dart';
import 'package:judo_app/features/auth/providers/auth_provider.dart';
import 'package:judo_app/features/news/providers/news_provider.dart';
import 'package:judo_app/features/team/providers/children_provider.dart';
import 'package:judo_app/shared/widgets/gradient_button.dart';

class NewsCreatePostScreen extends ConsumerStatefulWidget {
  const NewsCreatePostScreen({super.key, this.postId});

  final String? postId;

  @override
  ConsumerState<NewsCreatePostScreen> createState() =>
      _NewsCreatePostScreenState();
}

class _NewsCreatePostScreenState extends ConsumerState<NewsCreatePostScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _compNameCtrl = TextEditingController();
  final _compCityCtrl = TextEditingController();
  final _compVenueCtrl = TextEditingController();
  final _coachCommentCtrl = TextEditingController();
  final _goldCtrl = TextEditingController();
  final _silverCtrl = TextEditingController();
  final _bronzeCtrl = TextEditingController();

  // State
  ClubPostType _type = ClubPostType.clubNews;
  bool _isPublished = false;
  bool _isPinned = false;
  bool _commentsEnabled = true;
  String? _coverImageUrl;
  List<ClubPostImage> _images = [];
  List<ClubPostAthleteMention> _mentions = [];
  DateTime? _compDate;
  bool _saving = false;
  bool _uploadingCover = false;
  bool _uploadingGallery = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.postId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.listenManual(
          clubPostProvider(widget.postId!),
          (_, next) {
            final post = next.asData?.value;
            if (post != null && !_initialized) {
              _initFromPost(post);
            }
          },
          fireImmediately: true,
        );
      });
    }
  }

  void _initFromPost(ClubPost post) {
    if (_initialized) return;
    _initialized = true;
    setState(() {
      _titleCtrl.text = post.title;
      _descCtrl.text = post.description;
      _contentCtrl.text = post.content;
      _compNameCtrl.text = post.competitionName ?? '';
      _compCityCtrl.text = post.competitionCity ?? '';
      _compVenueCtrl.text = post.competitionVenue ?? '';
      _type = post.type;
      _isPublished = post.isPublished;
      _isPinned = post.isPinned;
      _commentsEnabled = post.commentsEnabled;
      _coverImageUrl = post.coverImageUrl;
      _images = List<ClubPostImage>.from(post.images);
      _mentions = List<ClubPostAthleteMention>.from(post.mentions);
      _compDate = post.competitionDate;
      if (post.goldMedals != null) _goldCtrl.text = post.goldMedals.toString();
      if (post.silverMedals != null) _silverCtrl.text = post.silverMedals.toString();
      if (post.bronzeMedals != null) _bronzeCtrl.text = post.bronzeMedals.toString();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _contentCtrl.dispose();
    _compNameCtrl.dispose();
    _compCityCtrl.dispose();
    _compVenueCtrl.dispose();
    _coachCommentCtrl.dispose();
    _goldCtrl.dispose();
    _silverCtrl.dispose();
    _bronzeCtrl.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final userAsync = ref.read(currentUserModelProvider);
    final user = userAsync.asData?.value;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final now = DateTime.now();
      final goldMedals = int.tryParse(_goldCtrl.text.trim());
      final silverMedals = int.tryParse(_silverCtrl.text.trim());
      final bronzeMedals = int.tryParse(_bronzeCtrl.text.trim());

      final mentionedAthleteIds =
          _mentions.map((m) => m.athleteId).toList();

      final post = ClubPost(
        id: widget.postId ?? const Uuid().v4(),
        authorId: user.uid,
        authorName: user.name,
        type: _type,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        coverImageUrl: _coverImageUrl,
        isPinned: _isPinned,
        isPublished: _isPublished,
        commentsEnabled: _commentsEnabled,
        images: _images,
        mentions: _mentions,
        mentionedAthleteIds: mentionedAthleteIds,
        competitionName: _compNameCtrl.text.trim().isEmpty
            ? null
            : _compNameCtrl.text.trim(),
        competitionCity: _compCityCtrl.text.trim().isEmpty
            ? null
            : _compCityCtrl.text.trim(),
        competitionVenue: _compVenueCtrl.text.trim().isEmpty
            ? null
            : _compVenueCtrl.text.trim(),
        goldMedals: goldMedals,
        silverMedals: silverMedals,
        bronzeMedals: bronzeMedals,
        competitionDate: _compDate,
        publishedAt: _isPublished ? now : null,
        createdAt: now,
        updatedAt: now,
      );

      final notifier = ref.read(clubPostNotifierProvider.notifier);
      if (widget.postId != null) {
        await notifier.updatePost(post);
      } else {
        await notifier.createPost(post);
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

  // ── Upload helpers ─────────────────────────────────────────────────────────

  Future<void> _pickAndUploadCover() async {
    if (_uploadingCover) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() => _uploadingCover = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await uploadImageToCloudinary(
        bytes,
        'club_posts/covers/${const Uuid().v4()}',
      );
      if (mounted) setState(() => _coverImageUrl = url);
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
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Future<void> _pickAndUploadGalleryImage() async {
    if (_uploadingGallery) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;

    setState(() => _uploadingGallery = true);
    try {
      final bytes = await picked.readAsBytes();
      final id = const Uuid().v4();
      final url = await uploadImageToCloudinary(
        bytes,
        'club_posts/gallery/$id',
      );
      if (mounted) {
        setState(() {
          _images = [
            ..._images,
            ClubPostImage(
              id: id,
              postId: widget.postId ?? '',
              imageUrl: url,
              sortOrder: _images.length,
              createdAt: DateTime.now(),
            ),
          ];
        });
      }
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
      if (mounted) setState(() => _uploadingGallery = false);
    }
  }

  // ── Shared decoration ─────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  // ── Builder helpers ────────────────────────────────────────────────────────

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      );

  Widget _textField(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: _inputDecoration(label),
        validator: required
            ? (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Поле обов\'язкове';
                }
                return null;
              }
            : null,
      );

  Widget _switchRow(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
              inactiveTrackColor: AppColors.surface2,
              inactiveThumbColor: AppColors.textSecondary,
            ),
          ],
        ),
      );

  Widget _typeDropdown() => DropdownButtonFormField<ClubPostType>(
        initialValue: _type,
        dropdownColor: AppColors.surface2,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: _inputDecoration('Тип публікації'),
        items: ClubPostType.values
            .map(
              (t) => DropdownMenuItem(
                value: t,
                child: Text(t.label),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _type = v);
        },
      );

  Widget _coverPicker() {
    if (_coverImageUrl != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: _coverImageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.surface2,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surface2,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textSecondary,
                    size: 40,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() => _coverImageUrl = null),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.borderSoft),
          backgroundColor: AppColors.surface2,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: _uploadingCover
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.textSecondary,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Завантажити обкладинку'),
        onPressed: _uploadingCover ? null : _pickAndUploadCover,
      ),
    );
  }

  Widget _gallerySection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._images.asMap().entries.map((entry) {
            final img = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: img.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.surface2,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.surface2,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _images = _images
                              .where((i) => i.id != img.id)
                              .toList();
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(
            height: 80,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.borderSoft),
                backgroundColor: AppColors.surface2,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _uploadingGallery
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: AppColors.textSecondary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined, size: 20),
              label: const Text('Додати фото', style: TextStyle(fontSize: 13)),
              onPressed: _uploadingGallery ? null : _pickAndUploadGalleryImage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mentionsSection() {
    return Consumer(
      builder: (context, ref, _) {
        final childrenAsync = ref.watch(allChildrenProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_mentions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _mentions.map((m) {
                    return Chip(
                      label: Text(
                        m.athleteName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      backgroundColor: AppColors.surface2,
                      side: const BorderSide(color: AppColors.borderSoft),
                      deleteIcon: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      onDeleted: () {
                        setState(() {
                          _mentions =
                              _mentions.where((x) => x.id != m.id).toList();
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.borderSoft),
                  backgroundColor: AppColors.surface2,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_outlined),
                label: const Text('Відмітити спортсмена'),
                onPressed: () {
                  final children =
                      childrenAsync.asData?.value ?? <ChildModel>[];
                  _showAthletePickerSheet(children);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAthletePickerSheet(List<ChildModel> allChildren) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AthletePickerSheet(
        allChildren: allChildren,
        alreadyMentioned: _mentions.map((m) => m.athleteId).toSet(),
        onPick: (child) {
          setState(() {
            final alreadyAdded =
                _mentions.any((m) => m.athleteId == child.id);
            if (!alreadyAdded) {
              _mentions = [
                ..._mentions,
                ClubPostAthleteMention(
                  id: const Uuid().v4(),
                  athleteId: child.id,
                  athleteName: child.fullName,
                ),
              ];
            }
          });
        },
      ),
    );
  }

  Widget _datePicker() {
    final dateText = _compDate != null
        ? DateFormat('d MMMM yyyy', 'uk').format(_compDate!)
        : 'Дата змагань';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _compDate ?? DateTime.now(),
          firstDate: DateTime(2010),
          lastDate: DateTime(2040),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.surface2,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _compDate = picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              dateText,
              style: TextStyle(
                color: _compDate != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            if (_compDate != null)
              GestureDetector(
                onTap: () => setState(() => _compDate = null),
                child: const Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _medalCounters() {
    final numFmt = FilteringTextInputFormatter.digitsOnly;
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _goldCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [numFmt],
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: _inputDecoration('🥇').copyWith(labelText: '🥇 Золото'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _silverCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [numFmt],
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: _inputDecoration('🥈').copyWith(labelText: '🥈 Срібло'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _bronzeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [numFmt],
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: _inputDecoration('🥉').copyWith(labelText: '🥉 Бронза'),
          ),
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.postId != null;
    final showCompFields = _type == ClubPostType.photoReport ||
        _type == ClubPostType.competition;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          isEdit ? 'Редагувати' : 'Нова публікація',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // ── Основне ────────────────────────────────────────────────────
            _section('Основне'),
            _typeDropdown(),
            const SizedBox(height: 12),
            _textField(_titleCtrl, 'Заголовок', required: true),
            const SizedBox(height: 12),
            _textField(_descCtrl, 'Короткий опис', maxLines: 2),
            const SizedBox(height: 12),
            _textField(
              _contentCtrl,
              'Повний текст (необов\'язково)',
              maxLines: 5,
            ),
            const SizedBox(height: 20),

            // ── Обкладинка ─────────────────────────────────────────────────
            _section('Обкладинка'),
            _coverPicker(),
            const SizedBox(height: 20),

            // ── Налаштування ───────────────────────────────────────────────
            _section('Налаштування'),
            _switchRow(
              'Опублікувати',
              _isPublished,
              (v) => setState(() => _isPublished = v),
            ),
            _switchRow(
              'Закріпити',
              _isPinned,
              (v) => setState(() => _isPinned = v),
            ),
            _switchRow(
              'Коментарі',
              _commentsEnabled,
              (v) => setState(() => _commentsEnabled = v),
            ),
            const SizedBox(height: 20),

            // ── Про змагання (умовно) ──────────────────────────────────────
            if (showCompFields) ...[
              _section('Про змагання'),
              _textField(_compNameCtrl, 'Назва змагань'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _textField(_compCityCtrl, 'Місто')),
                  const SizedBox(width: 8),
                  Expanded(child: _textField(_compVenueCtrl, 'Місце')),
                ],
              ),
              const SizedBox(height: 12),
              _datePicker(),
              const SizedBox(height: 12),
              _medalCounters(),
              const SizedBox(height: 20),
            ],

            // ── Фотогалерея ────────────────────────────────────────────────
            _section('Фотогалерея'),
            _gallerySection(),
            const SizedBox(height: 20),

            // ── Відмітити спортсменів ──────────────────────────────────────
            _section('Відмітити спортсменів'),
            _mentionsSection(),
            const SizedBox(height: 28),

            // ── Кнопка збереження ──────────────────────────────────────────
            GradientButton(
              isLoading: _saving,
              onPressed: _saving ? null : _save,
              child: Text(
                isEdit ? 'Зберегти' : 'Опублікувати',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Athlete picker bottom sheet ───────────────────────────────────────────────

class _AthletePickerSheet extends StatefulWidget {
  const _AthletePickerSheet({
    required this.allChildren,
    required this.alreadyMentioned,
    required this.onPick,
  });

  final List<ChildModel> allChildren;
  final Set<String> alreadyMentioned;
  final ValueChanged<ChildModel> onPick;

  @override
  State<_AthletePickerSheet> createState() => _AthletePickerSheetState();
}

class _AthletePickerSheetState extends State<_AthletePickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ChildModel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.allChildren;
    return widget.allChildren
        .where((c) =>
            c.firstName.toLowerCase().contains(q) ||
            c.lastName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Відмітити спортсмена',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Пошук...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
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
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Спортсменів не знайдено',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final child = filtered[i];
                        final alreadyAdded =
                            widget.alreadyMentioned.contains(child.id);
                        return ListTile(
                          title: Text(
                            child.fullName,
                            style: TextStyle(
                              color: alreadyAdded
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            '${child.birthYear} р.н.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          trailing: alreadyAdded
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.primary,
                                  size: 20,
                                )
                              : null,
                          onTap: alreadyAdded
                              ? null
                              : () {
                                  widget.onPick(child);
                                  Navigator.of(context).pop();
                                },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
