# 🦅 So'zona — Nemis/Ingliz Tili O'rganish Ilovasi

> Flutter + Firebase + AI — O'zbekiston uchun yaratilgan til o'rganish platformasi

---

## 📱 Ilova haqida

**So'zona** — nemis yoki ingliz tilini o'rganuvchilar uchun mobil ilova. Ustoz-talaba tizimi, AI yordamida kontent generatsiyasi va shaxsiylashtirilgan o'rganish yo'li.

### Asosiy xususiyatlar
- 📚 **Flashcardlar** — offline rejim, TTS, spaced repetition
- ❓ **Quiz** — MCQ, true/false, bo'sh to'ldirish; AI tomonidan yaratilgan
- 🎧 **Listening** — audio mashqlar, transkripsiya, tezlik nazorati
- 🎤 **Speaking** — AI suhbat sherigi, talaffuz baholash
- 🇩🇪 **Artikel mashq** — der/die/das — nemis tili uchun
- 🤖 **AI Chat** — grammatika, so'zlar, mavzular bo'yicha suhbat
- 🔁 **Micro-sessions** — 10 daqiqalik zaif tomonlar mashqi
- 👨‍🏫 **O'qituvchi paneli** — sinf boshqaruvi, AI kontent yaratish, analitika

---

## 🏗️ Texnik arxitektura

```
Flutter (Dart)
├── Clean Architecture (Domain / Data / Presentation)
├── Riverpod — State management
├── GoRouter — Navigation
└── Hive — Local cache

Firebase
├── Firestore — Ma'lumotlar bazasi
├── Authentication — Foydalanuvchi tizimi
├── Storage — Fayl saqlash
├── Cloud Functions (TypeScript) — AI, notifications
├── Cloud Messaging — Push xabarnomalar
└── Crashlytics — Xato kuzatish
```

---

## 📁 Papka tuzilmasi

```
lib/
├── core/
│   ├── constants/      # App, Firestore, asset konstantalar
│   ├── error/          # Failures, exceptions, error handler
│   ├── network/        # API client, connectivity
│   ├── providers/      # Global Riverpod providers
│   ├── router/         # GoRouter + guards
│   ├── services/       # TTS, notification, crashlytics, storage
│   ├── theme/          # Colors, text styles, dimensions
│   ├── usecases/       # Base UseCase interface
│   ├── utils/          # Validators, date utils, extensions
│   └── widgets/        # Reusable widgets
├── features/
│   ├── auth/           # Login, register, forgot password, role select
│   ├── onboarding/     # Kirish sahnalari
│   ├── profile/        # Profil, sozlamalar, GDPR
│   ├── student/
│   │   ├── home/       # Kunlik reja, streak
│   │   ├── flashcards/ # Flashcard to'plamlari, mashq
│   │   ├── quiz/       # Quiz ro'yxati, o'ynash, natija
│   │   ├── listening/  # Audio mashqlar
│   │   ├── speaking/   # AI dialog
│   │   ├── ai_chat/    # AI suhbat
│   │   ├── artikel/    # Der/die/das mashq
│   │   ├── progress/   # XP, streak, zaif tomonlar
│   │   └── join_class/ # Sinfga qo'shilish
│   └── teacher/
│       ├── dashboard/      # Umumiy statistika
│       ├── classes/        # Sinf boshqaruvi
│       ├── content_generator/ # AI kontent yaratish
│       ├── publishing/     # Kontent e'lon qilish
│       └── analytics/      # Sinf analitikasi
functions/
├── src/
│   ├── ai/             # OpenAI → Gemini router, clientlar
│   ├── middleware/     # Auth, rate limit, cost monitor
│   ├── prompts/        # AI prompt builderlar
│   ├── schemas/        # JSON schema validator
│   └── triggers/       # Firestore triggers
test/
├── integration/        # E2E testlar
├── unit/               # Business logic testlar
└── widget/             # UI testlar
```

---

## 🚀 O'rnatish va ishga tushirish

### Talablar
- Flutter 3.19+
- Dart 3.3+
- Node.js 18+
- Firebase CLI
- Android Studio yoki Xcode

### 1. Loyihani klonlash
```bash
git clone https://github.com/yourorg/sozona.git
cd sozona/my_first_app
```

### 2. Flutter paketlarini o'rnatish
```bash
flutter pub get
```

### 3. Firebase sozlash
```bash
# Firebase CLI o'rnatish
npm install -g firebase-tools

# Tizimga kirish
firebase login

# Flutter uchun Firebase sozlash
flutterfire configure --project=sozona-prod
```

### 4. Cloud Functions
```bash
cd functions
npm install

# Local test
npm run serve

# AI kalitlarini sozlash
firebase functions:config:set \
  openai.key="sk-proj-..." \
  gemini.key="AIza..."
```

### 5. Ilovani ishga tushirish
```bash
cd ..
flutter run
```

---

## 🔒 Deploy

### Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Firestore Indexes
```bash
firebase deploy --only firestore:indexes
```

### Storage Rules
```bash
firebase deploy --only storage:rules
```

### Cloud Functions
```bash
firebase deploy --only functions
```

### Flutter Build

**Android:**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**iOS:**
```bash
flutter build ipa --release
# Output: build/ios/ipa/
```

---

## 🧪 Testlar

```bash
# Unit testlar
flutter test test/unit/

# Widget testlar
flutter test test/widget/

# Integration testlar (real qurilmada)
flutter test integration_test/

# Cloud Functions testlar
cd functions
npm test
```

---

## 🗄️ Firestore ma'lumotlar tuzilmasi

```
users/{userId}
  ├── role: 'student' | 'teacher'
  ├── level: 'A1' | 'A2' | 'B1' | 'B2' | 'C1'
  ├── preferredLanguage: 'en' | 'de'
  ├── currentStreak, longestStreak, totalXp
  ├── notifications: {microSession, streak, teacherContent}
  ├── preferences: {microSessionEnabled, premiumTtsEnabled, ...}
  └── weakItems/{itemId}      ← Zaif elementlar

classes/{classId}
  ├── teacherId, name, language, level
  ├── joinCode (6 belgili)
  └── members/{userId}

content/{contentId}
  ├── type: 'quiz' | 'flashcard' | 'listening' | 'speaking' | 'artikel'
  ├── classId, createdBy, isPublished
  └── data: {...}             ← Turdga qarab farqli

attempts/{attemptId}
  ├── userId, contentId, contentType
  ├── isCorrect, percentage
  └── createdAt

progress/{userId}
  ├── skillScores, recentActivity[30 days]
  └── daily/{date}            ← Kunlik reja

sessions/{sessionId}          ← Micro-sessions
rateLimits/{key}              ← Rate limiting
aiUsage/{userId_date}         ← AI xarajat nazorati
dataRequests/{reqId}          ← GDPR so'rovlar
```

---

## 👥 Jamoa

| Rol | Mas'uliyat |
|-----|-----------|
| Flutter Dev | UI, state management, offline |
| Backend Dev | Cloud Functions, Firestore rules |
| AI Engineer | Prompt engineering, schema validation |
| Designer | UI/UX, animatsiyalar |

---

## 📄 Litsenziya

MIT License © 2026 So'zona Team

---

## 🆘 Yordam

Muammo yoki savol bo'lsa:
- **GitHub Issues**: [github.com/yourorg/sozona/issues](https://github.com/yourorg/sozona/issues)
- **Email**: dev@sozona.uz
