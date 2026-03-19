// QO'YISH: lib/features/teacher/classes/presentation/screens/class_list_screen.dart
// So'zona — O'qituvchi sinflar ro'yxati ekrani
// Teacher barcha sinflarini ko'radi, yangi sinf yaratadi

import 'package:flutter/material.dart';
import 'package:my_first_app/core/widgets/app_empty_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:my_first_app/core/router/route_names.dart';
import 'package:my_first_app/core/theme/app_colors.dart';
import 'package:my_first_app/core/theme/app_text_styles.dart';
import 'package:my_first_app/core/widgets/app_error_widget.dart';
import 'package:my_first_app/core/widgets/app_loading_widget.dart';
import 'package:my_first_app/features/teacher/classes/domain/entities/school_class.dart';
import 'package:my_first_app/features/teacher/classes/presentation/providers/class_provider.dart';
import 'package:my_first_app/features/teacher/classes/presentation/screens/class_create_screen.dart';
import 'package:my_first_app/features/teacher/classes/presentation/widgets/class_card.dart';

/// O'qituvchi sinflar ro'yxati ekrani
class ClassListScreen extends ConsumerWidget {
  const ClassListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(teacherClassesProvider);

    return Scaffold(
      
      appBar: AppBar(
        title: Text('Sinflarim', style: AppTextStyles.titleLarge),
        centerTitle: false,
        
        elevation: 0,
        actions: [
          // Yangilash tugmasi
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yangilash',
            onPressed: () =>
                ref.read(teacherClassesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: classesAsync.when(
        loading: () => const AppLoadingWidget(
          message: 'Sinflar yuklanmoqda...',
        ),
        error: (error, _) => AppErrorWidget(
          message: error.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.read(teacherClassesProvider.notifier).refresh(),
        ),
        data: (classes) {
          if (classes.isEmpty) {
            return AppEmptyWidget(
              icon: Icons.class_rounded,
              title: 'Hali sinf yo\'q',
              message:
                  'Birinchi sinfingizni yarating va o\'quvchilarni taklif qiling',
              actionLabel: 'Sinf yaratish',
              onAction: () => _showCreateClassDialog(context, ref),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                ref.read(teacherClassesProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return ClassCard(
                  schoolClass: classes[index],
                  onTap: () => _openClassDetail(context, ref, classes[index]),
                );
              },
            ),
          );
        },
      ),
      // Yangi sinf yaratish tugmasi
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateClassDialog(context, ref),
        
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Sinf yaratish'),
      ),
    );
  }

  /// Sinf tafsilotlari ekraniga o'tish
  void _openClassDetail(
    BuildContext context,
    WidgetRef ref,
    SchoolClass schoolClass,
  ) {
    ref.read(selectedClassIdProvider.notifier).state = schoolClass.id;
    context.push(
      RoutePaths.classDetail.replaceAll(':id', schoolClass.id),
    );
  }

  /// Sinf yaratish dialog'ini ko'rsatish
  void _showCreateClassDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      
      builder: (context) => const ClassCreateScreen(),
    );
  }
}
