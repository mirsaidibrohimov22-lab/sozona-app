// lib/features/flashcard/presentation/screens/folders_screen.dart
// So'zona — Flashcard papkalar ekrani
// Barcha papkalar ro'yxati va yaratish

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/constants/app_sizes.dart';
import 'package:my_first_app/core/widgets/app_empty_state.dart';
import 'package:my_first_app/core/widgets/app_error_widget.dart';
import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:my_first_app/features/student/flashcards/presentation/providers/flashcard_provider.dart';
import 'package:my_first_app/features/student/flashcards/presentation/widgets/folder_card_widget.dart';
import 'package:my_first_app/core/router/route_names.dart';

/// Flashcard papkalar ekrani
class FoldersScreen extends ConsumerStatefulWidget {
  const FoldersScreen({super.key});

  @override
  ConsumerState<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends ConsumerState<FoldersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFolders();
    });
  }

  void _loadFolders() {
    final userId = ref.read(authNotifierProvider).user?.id;
    if (userId != null) {
      ref.read(foldersProvider.notifier).loadFolders(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersState = ref.watch(foldersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartochkalarim'),
        centerTitle: true,
        actions: [
          // Qidiruv
          IconButton(
            onPressed: () => context.push(RoutePaths.flashcardSearch),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: foldersState.isLoading
          ? const AppLoadingWidget()
          : foldersState.error != null
              ? AppErrorWidget(
                  message: foldersState.error!,
                  onRetry: _loadFolders,
                )
              : foldersState.folders.isEmpty
                  ? AppEmptyWidget.noFlashcards(
                      onAction: _showCreateFolderDialog,
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _loadFolders(),
                      child: _buildFoldersList(foldersState),
                    ),
      // Yangi papka yaratish
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateFolderDialog,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFoldersList(FoldersState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      itemCount: state.folders.length,
      itemBuilder: (context, index) {
        final folder = state.folders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spacingMd),
          child: FolderCardWidget(
            folder: folder,
            onTap: () => context.push(
              '/student/flashcards/folder/${folder.id}',
            ),
            onDelete: () async {
              final confirm = await _showDeleteConfirm(folder.name);
              if (confirm) {
                ref.read(foldersProvider.notifier).deleteFolder(folder.id);
              }
            },
          ),
        );
      },
    );
  }

  /// Yangi papka yaratish dialogi
  Future<void> _showCreateFolderDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: const Text(
          'Yangi papka',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Papka nomi *',
                hintText: 'Masalan: A1 so\'zlar',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Tavsif (ixtiyoriy)',
                hintText: 'Qisqacha izoh',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('Yaratish'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final userId = ref.read(authNotifierProvider).user?.id;
      if (userId != null) {
        await ref.read(foldersProvider.notifier).createFolder(
              userId: userId,
              name: nameController.text.trim(),
              description: descController.text.trim().isNotEmpty
                  ? descController.text.trim()
                  : null,
            );
      }
    }

    nameController.dispose();
    descController.dispose();
  }

  /// O'chirish tasdiqlash
  Future<bool> _showDeleteConfirm(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Papkani o\'chirish'),
        content: Text(
          '"$name" papkasi va undagi barcha kartochkalar o\'chiriladi. Davom etasizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
