// lib/features/student/flashcards/presentation/screens/flashcard_search_screen.dart
// ✅ PATCH DAY-1-C: /student/flashcards/search route uchun ekran

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:my_first_app/features/student/flashcards/presentation/providers/flashcard_provider.dart';

class FlashcardSearchScreen extends ConsumerStatefulWidget {
  const FlashcardSearchScreen({super.key});

  @override
  ConsumerState<FlashcardSearchScreen> createState() =>
      _FlashcardSearchScreenState();
}

class _FlashcardSearchScreenState extends ConsumerState<FlashcardSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foldersState = ref.watch(foldersProvider);
    final filtered = _query.isEmpty
        ? foldersState.folders
        : foldersState.folders
            .where(
              (f) =>
                  f.name.toLowerCase().contains(_query.toLowerCase()) ||
                  (f.description ?? '')
                      .toLowerCase()
                      .contains(_query.toLowerCase()),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Papka qidirish...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        leading: const BackButton(),
      ),
      body: foldersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        _query.isEmpty
                            ? 'Qidiruv uchun yozing'
                            : '"$_query" bo\'yicha natija topilmadi',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final folder = filtered[index];
                    return ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(folder.name),
                      subtitle: folder.description != null
                          ? Text(
                              folder.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: Text('${folder.cardCount} ta karta'),
                      onTap: () => context.push(
                        '/student/flashcards/folder/${folder.id}',
                      ),
                    );
                  },
                ),
    );
  }
}
