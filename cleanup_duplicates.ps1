# ═══════════════════════════════════════════════════════════════
# SO'ZONA — H bo'limi: Duplicate fayllar o'chirish (WINDOWS PowerShell)
# ISHLATISH: loyiha papkasida PowerShell ochib:
#   .\cleanup_duplicates.ps1
# ═══════════════════════════════════════════════════════════════

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "1-QADAM: Import yo'llarini tuzatish" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# 1. ai_chat_screen.dart: chat_provider → ai_chat_provider
$f1 = "lib\features\student\ai_chat\presentation\screens\ai_chat_screen.dart"
if (Test-Path $f1) {
    (Get-Content $f1) -replace "providers/chat_provider\.dart", "providers/ai_chat_provider.dart" | Set-Content $f1
    Write-Host "  Fixed: ai_chat_screen.dart" -ForegroundColor Green
}

# 2. quiz_detail_screen.dart: loading_widget → app_loading_widget
$f2 = "lib\features\student\quiz\presentation\screens\quiz_detail_screen.dart"
if (Test-Path $f2) {
    (Get-Content $f2) -replace "widgets/loading_widget\.dart", "widgets/app_loading_widget.dart" | Set-Content $f2
    Write-Host "  Fixed: quiz_detail_screen.dart" -ForegroundColor Green
}

# 3. content_gen_repository_impl.dart: content_generator_remote_datasource → content_gen_remote_datasource
$f3 = "lib\features\teacher\content_generator\data\repositories\content_gen_repository_impl.dart"
if (Test-Path $f3) {
    (Get-Content $f3) -replace "datasources/content_generator_remote_datasource\.dart", "datasources/content_gen_remote_datasource.dart" | Set-Content $f3
    Write-Host "  Fixed: content_gen_repository_impl.dart" -ForegroundColor Green
}

# 4-5. content_gen_provider.dart: 2 ta import fix
$f4 = "lib\features\teacher\content_generator\presentation\providers\content_gen_provider.dart"
if (Test-Path $f4) {
    (Get-Content $f4) -replace "datasources/content_generator_remote_datasource\.dart", "datasources/content_gen_remote_datasource.dart" -replace "repositories/content_generator_repository_impl\.dart", "repositories/content_gen_repository_impl.dart" | Set-Content $f4
    Write-Host "  Fixed: content_gen_provider.dart" -ForegroundColor Green
}

# 6. content_generator_screen.dart: content_generator_provider → content_gen_provider
$f5 = "lib\features\teacher\content_generator\presentation\screens\content_generator_screen.dart"
if (Test-Path $f5) {
    (Get-Content $f5) -replace "providers/content_generator_provider\.dart", "providers/content_gen_provider.dart" | Set-Content $f5
    Write-Host "  Fixed: content_generator_screen.dart" -ForegroundColor Green
}

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "2-QADAM: Duplicate fayllarni o'chirish" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

$filesToDelete = @(
    "lib\features\auth\presentation\screens\fortgot_password_screen.dart",
    "lib\features\student\flashcards\domain\entities\flashcard.dart",
    "lib\features\student\ai_chat\data\datasources\ai_chat_remote_datasource.dart",
    "lib\features\student\ai_chat\data\repositories\chat_repository_impl.dart",
    "lib\features\student\ai_chat\domain\repositories\ai_chat_repository.dart",
    "lib\features\student\ai_chat\presentation\providers\chat_provider.dart",
    "lib\features\teacher\content_generator\data\datasources\content_generator_remote_datasource.dart",
    "lib\features\teacher\content_generator\presentation\providers\content_generator_provider.dart",
    "lib\features\teacher\content_generator\data\repositories\content_generator_repository_impl.dart",
    "lib\features\student\flashcards\domain\usecases\create_flashcard.dart",
    "lib\features\student\flashcards\presentation\screens\search_cards_screen.dart",
    "lib\core\widgets\app_empty_widget.dart",
    "lib\core\widgets\empty_state_widget.dart",
    "lib\core\widgets\error_widget.dart",
    "lib\core\widgets\loading_widget.dart",
    "lib\features\student\listening\domain\repositories\listening_repository_impl.dart"
)

$deleted = 0
foreach ($file in $filesToDelete) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Host "  O'chirildi: $file" -ForegroundColor Yellow
        $deleted++
    } else {
        Write-Host "  Topilmadi: $file" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "YAKUNLANDI!" -ForegroundColor Green
Write-Host "O'chirilgan fayllar: $deleted ta" -ForegroundColor Green
Write-Host "Import tuzatilgan: 6 ta fayl" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Endi quyidagini ishga tushiring:" -ForegroundColor White
Write-Host "  flutter analyze" -ForegroundColor Yellow