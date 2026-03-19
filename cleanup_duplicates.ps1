#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# SO'ZONA — H bo'limi: Duplicate fayllar o'chirish skripti
# I bo'limi: Functions papka tartibga solish
#
# ISHLATISH: bash cleanup_duplicates.sh
# ⚠️ AVVAL flutter analyze qiling, keyin shu skriptni bajaring
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════"
echo "1-QADAM: Import yo'llarini tuzatish"
echo "═══════════════════════════════════════"

# ── 1. ai_chat_screen.dart: chat_provider → ai_chat_provider ──
echo "Fixing: ai_chat_screen.dart"
sed -i "s|import 'package:my_first_app/features/student/ai_chat/presentation/providers/chat_provider.dart';|import 'package:my_first_app/features/student/ai_chat/presentation/providers/ai_chat_provider.dart';|g" \
  lib/features/student/ai_chat/presentation/screens/ai_chat_screen.dart

# ── 2. quiz_detail_screen.dart: loading_widget → app_loading_widget ──
echo "Fixing: quiz_detail_screen.dart"
sed -i "s|import 'package:my_first_app/core/widgets/loading_widget.dart';|import 'package:my_first_app/core/widgets/app_loading_widget.dart';|g" \
  lib/features/student/quiz/presentation/screens/quiz_detail_screen.dart

# ── 3. content_gen_repository_impl.dart: content_generator_remote_datasource → content_gen_remote_datasource ──
echo "Fixing: content_gen_repository_impl.dart"
sed -i "s|import 'package:my_first_app/features/teacher/content_generator/data/datasources/content_generator_remote_datasource.dart';|import 'package:my_first_app/features/teacher/content_generator/data/datasources/content_gen_remote_datasource.dart';|g" \
  lib/features/teacher/content_generator/data/repositories/content_gen_repository_impl.dart

# ── 4. content_gen_provider.dart: content_generator_remote_datasource → content_gen_remote_datasource ──
echo "Fixing: content_gen_provider.dart (datasource import)"
sed -i "s|import 'package:my_first_app/features/teacher/content_generator/data/datasources/content_generator_remote_datasource.dart';|import 'package:my_first_app/features/teacher/content_generator/data/datasources/content_gen_remote_datasource.dart';|g" \
  lib/features/teacher/content_generator/presentation/providers/content_gen_provider.dart

# ── 5. content_gen_provider.dart: content_generator_repository_impl → content_gen_repository_impl ──
echo "Fixing: content_gen_provider.dart (repository import)"
sed -i "s|import 'package:my_first_app/features/teacher/content_generator/data/repositories/content_generator_repository_impl.dart';|import 'package:my_first_app/features/teacher/content_generator/data/repositories/content_gen_repository_impl.dart';|g" \
  lib/features/teacher/content_generator/presentation/providers/content_gen_provider.dart

# ── 6. content_generator_screen.dart: content_generator_provider → content_gen_provider ──
echo "Fixing: content_generator_screen.dart"
sed -i "s|import 'package:my_first_app/features/teacher/content_generator/presentation/providers/content_generator_provider.dart';|import 'package:my_first_app/features/teacher/content_generator/presentation/providers/content_gen_provider.dart';|g" \
  lib/features/teacher/content_generator/presentation/screens/content_generator_screen.dart

echo ""
echo "═══════════════════════════════════════"
echo "2-QADAM: Duplicate fayllarni o'chirish"
echo "═══════════════════════════════════════"

# Re-export va duplicate fayllar — xavfsiz o'chirish
FILES_TO_DELETE=(
  # Typo dublikat
  "lib/features/auth/presentation/screens/fortgot_password_screen.dart"

  # Flashcard dublikat (flashcard_entity.dart bor)
  "lib/features/student/flashcards/domain/entities/flashcard.dart"

  # AI Chat eski datasource (chat_remote_datasource.dart qoladi)
  "lib/features/student/ai_chat/data/datasources/ai_chat_remote_datasource.dart"

  # AI Chat re-export fayllar
  "lib/features/student/ai_chat/data/repositories/chat_repository_impl.dart"
  "lib/features/student/ai_chat/domain/repositories/ai_chat_repository.dart"
  "lib/features/student/ai_chat/presentation/providers/chat_provider.dart"

  # Content generator re-export fayllar
  "lib/features/teacher/content_generator/data/datasources/content_generator_remote_datasource.dart"
  "lib/features/teacher/content_generator/presentation/providers/content_generator_provider.dart"
  "lib/features/teacher/content_generator/data/repositories/content_generator_repository_impl.dart"

  # Flashcard re-export
  "lib/features/student/flashcards/domain/usecases/create_flashcard.dart"

  # Eski dublikat screen
  "lib/features/student/flashcards/presentation/screens/search_cards_screen.dart"

  # Core widget re-export fayllar
  "lib/core/widgets/app_empty_widget.dart"
  "lib/core/widgets/empty_state_widget.dart"
  "lib/core/widgets/error_widget.dart"
  "lib/core/widgets/loading_widget.dart"

  # Domain'da turadigan impl (data/ da haqiqiy impl bor)
  "lib/features/student/listening/domain/repositories/listening_repository_impl.dart"
)

for f in "${FILES_TO_DELETE[@]}"; do
  if [ -f "$f" ]; then
    echo "  O'chirildi: $f"
    rm "$f"
  else
    echo "  ⚠️ Topilmadi: $f"
  fi
done

echo ""
echo "═══════════════════════════════════════"
echo "3-QADAM: Tekshiruv"
echo "═══════════════════════════════════════"

# Import tekshiruvi — o'chirilgan fayllar hali import qilinayotganmi
echo "O'chirilgan fayllar hali import qilinayotganmi tekshirilmoqda..."
ERRORS=0
for f in "${FILES_TO_DELETE[@]}"; do
  BASENAME=$(basename "$f" .dart)
  FOUND=$(grep -rn "$BASENAME" lib/ --include="*.dart" 2>/dev/null | grep "import " | grep -v "^Binary" | head -3)
  if [ -n "$FOUND" ]; then
    echo "  ⛔ XATO: '$BASENAME' hali import qilinmoqda:"
    echo "    $FOUND"
    ERRORS=$((ERRORS + 1))
  fi
done

if [ $ERRORS -eq 0 ]; then
  echo "  ✅ Barcha importlar toza — xatolik yo'q!"
else
  echo "  ⛔ $ERRORS ta import muammosi topildi — yuqoridagilarni tuzating!"
fi

echo ""
echo "═══════════════════════════════════════"
echo "4-QADAM: flutter analyze"
echo "═══════════════════════════════════════"
echo "Quyidagi buyruqni ishga tushiring:"
echo "  flutter analyze"
echo ""

echo "═══════════════════════════════════════"
echo "YAKUNLANDI!"
echo "O'chirilgan fayllar: ${#FILES_TO_DELETE[@]} ta"
echo "Import tuzatilgan fayllar: 6 ta"
echo "═══════════════════════════════════════"