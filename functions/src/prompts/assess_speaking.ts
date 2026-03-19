// functions/src/prompts/assess_speaking.ts
// SO'ZONA — Speaking Assessment
// ✅ Prompt talabi:
//   - AI foydalanuvchiga gapirish vazifasi beradi
//   - pronunciation bo'yicha baholaydi
//   - grammar bo'yicha baholaydi
//   - fluency bo'yicha baholaydi

import { aiRouter } from '../ai/ai_router';
import { saveActivity, type SkillType } from '../trackers/user_activity_tracker';
import * as admin from 'firebase-admin';

// ═══════════════════════════════════════════════════════════════
// TYPES
// ═══════════════════════════════════════════════════════════════

export interface SpeakingTaskRequest {
    userId: string;
    language: 'en' | 'de';
    level: string;
    topic?: string;
    taskType: 'describe' | 'narrate' | 'opinion' | 'roleplay' | 'read_aloud';
}

export interface SpeakingTask {
    taskId: string;
    instruction: string;       // "Describe your favorite place"
    hints: string[];           // Yordam beruvchi savollar
    vocabulary: string[];      // Ishlatishi kerak bo'lgan so'zlar
    timeLimit: number;         // Soniyalarda
    criteria: string[];        // Baholash mezonlari
}

export interface SpeakingAssessRequest {
    userId: string;
    taskId: string;
    language: 'en' | 'de';
    level: string;
    topic: string;
    transcribedText: string;   // STT orqali olingan matn
    audioDuration: number;     // Soniyalarda
}

export interface SpeakingAssessment {
    // Asosiy ballar (0-100)
    pronunciationScore: number;
    grammarScore: number;
    fluencyScore: number;
    vocabularyScore: number;
    overallScore: number;

    // Batafsil tahlil
    pronunciationFeedback: string;
    grammarFeedback: string;
    fluencyFeedback: string;
    vocabularyFeedback: string;

    // Grammatik xatolar
    grammarErrors: GrammarError[];

    // So'z boyligi tahlili
    vocabularyUsed: string[];
    suggestedVocabulary: string[];

    // Umumiy tavsiya
    overallFeedback: string;
    improvementTips: string[];

    // Keyingi qadam
    nextTask?: string;

    metadata: {
        model: string;
        wordsPerMinute: number;
        totalWords: number;
        audioDuration: number;
    };
}

export interface GrammarError {
    original: string;      // Xato gap
    corrected: string;     // To'g'ri shakl
    explanation: string;   // Tushuntirish
    rule: string;          // Grammatik qoida nomi
}

// ═══════════════════════════════════════════════════════════════
// 1. SPEAKING VAZIFA YARATISH
// ═══════════════════════════════════════════════════════════════

/**
 * Foydalanuvchi darajasiga mos speaking vazifa yaratish.
 * Masalan: "Describe your favorite place", "Tell about your day"
 */
export async function generateSpeakingTask(params: SpeakingTaskRequest): Promise<SpeakingTask> {
    const { language, level, topic, taskType } = params;
    const langName = language === 'en' ? 'ingliz' : 'nemis';

    const taskTypeMap: Record<string, string> = {
        describe: 'Tavsiflab bering (Describe)',
        narrate: 'Hikoya qiling (Tell a story)',
        opinion: 'Fikringizni ayting (Give your opinion)',
        roleplay: 'Rol o\'ynang (Roleplay)',
        read_aloud: 'Ovoz chiqarib o\'qing (Read aloud)',
    };

    const timeLimits: Record<string, number> = {
        A1: 30, A2: 45, B1: 60, B2: 90, C1: 120,
    };

    const prompt = `${level} darajali o'quvchi uchun ${langName} tilida speaking vazifa yarating.
Vazifa turi: ${taskTypeMap[taskType] ?? 'Describe'}
${topic ? `Mavzu: ${topic}` : 'Mavzu: kundalik hayot'}

Faqat JSON:
{
  "instruction": "${langName} tilida vazifa matni (masalan: 'Describe your favorite food and why you like it')",
  "hints": ["Yordam savol 1", "Yordam savol 2", "Yordam savol 3"],
  "vocabulary": ["ishlatishi kerak so'z1", "so'z2", "so'z3", "so'z4", "so'z5"],
  "criteria": ["Baholash mezoni 1", "Mezoni 2", "Mezoni 3"]
}`;

    const response = await aiRouter({ prompt, maxTokens: 500, temperature: 0.8, schema: null });
    const text = (response.text ?? '').replace(/```json|```/g, '').trim();

    try {
        const parsed = JSON.parse(text) as Record<string, unknown>;
        return {
            taskId: `spk_${Date.now()}`,
            instruction: (parsed.instruction as string) ?? 'Describe your day.',
            hints: (parsed.hints as string[]) ?? [],
            vocabulary: (parsed.vocabulary as string[]) ?? [],
            timeLimit: timeLimits[level] ?? 60,
            criteria: (parsed.criteria as string[]) ?? [],
        };
    } catch {
        return {
            taskId: `spk_${Date.now()}`,
            instruction: language === 'en'
                ? 'Tell me about your favorite hobby. What do you like about it?'
                : 'Erzählen Sie mir von Ihrem Lieblingshobby. Was gefällt Ihnen daran?',
            hints: ['What is it?', 'How often?', 'Why do you like it?'],
            vocabulary: ['enjoy', 'often', 'because', 'favorite', 'interesting'],
            timeLimit: timeLimits[level] ?? 60,
            criteria: ['Grammar', 'Vocabulary', 'Fluency'],
        };
    }
}

// ═══════════════════════════════════════════════════════════════
// 2. SPEAKING BAHOLASH
// ═══════════════════════════════════════════════════════════════

/**
 * Foydalanuvchi javobini AI orqali baholash.
 * 
 * STT (Speech-to-Text) orqali olingan matnni tahlil qiladi:
 * - Pronunciation — 0-100
 * - Grammar — 0-100
 * - Fluency — 0-100
 * - Vocabulary — 0-100
 */
export async function assessSpeaking(params: SpeakingAssessRequest): Promise<SpeakingAssessment> {
    const { userId, language, level, topic, transcribedText, audioDuration } = params;
    const langName = language === 'en' ? 'English' : 'German';

    // So'z soni va WPM hisoblash
    const words = transcribedText.trim().split(/\s+/);
    const totalWords = words.length;
    const wpm = audioDuration > 0 ? Math.round((totalWords / audioDuration) * 60) : 0;

    // Fluency taxminiy baholash — WPM asosida
    const expectedWpm: Record<string, { min: number; ideal: number; max: number }> = {
        A1: { min: 40, ideal: 70, max: 100 },
        A2: { min: 60, ideal: 90, max: 120 },
        B1: { min: 80, ideal: 110, max: 140 },
        B2: { min: 100, ideal: 130, max: 160 },
    };
    const wpmRange = expectedWpm[level] ?? expectedWpm.A1;

    const prompt = `You are a ${langName} language assessment expert. Evaluate this student's speaking response.

STUDENT LEVEL: ${level}
TOPIC: ${topic}
TRANSCRIBED TEXT: "${transcribedText}"
DURATION: ${audioDuration} seconds
WORDS: ${totalWords}
WPM: ${wpm}
EXPECTED WPM RANGE: ${wpmRange.min}-${wpmRange.max} (ideal: ${wpmRange.ideal})

Evaluate and return ONLY valid JSON:
{
  "pronunciationScore": 0-100,
  "grammarScore": 0-100,
  "fluencyScore": 0-100,
  "vocabularyScore": 0-100,
  "pronunciationFeedback": "O'zbek tilida qisqa baholash",
  "grammarFeedback": "O'zbek tilida qisqa baholash",
  "fluencyFeedback": "O'zbek tilida qisqa baholash",
  "vocabularyFeedback": "O'zbek tilida qisqa baholash",
  "grammarErrors": [
    {
      "original": "Xato gap",
      "corrected": "To'g'ri shakl",
      "explanation": "O'zbek tilida tushuntirish",
      "rule": "Grammatik qoida nomi"
    }
  ],
  "vocabularyUsed": ["ishlatilgan", "so'zlar"],
  "suggestedVocabulary": ["yangi", "so'zlar", "tavsiya"],
  "overallFeedback": "Umumiy baholash (o'zbek tilida, 2-3 gap, rag'batlantiruvchi)",
  "improvementTips": ["Maslahat 1", "Maslahat 2", "Maslahat 3"],
  "nextTask": "Keyingi speaking vazifa tavsiyasi"
}

MUHIM:
- ${level} darajasiga mos baholang (A1 uchun yumshoqroq)
- Agar matn juda qisqa bo'lsa (< 10 so'z), ballarni pasaytiring
- Agar WPM juda past (< ${wpmRange.min}), fluency ballini pasaytiring
- Agar WPM juda yuqori (> ${wpmRange.max}), fluency ballini biroz pasaytiring
- Grammatik xatolarni ANIQ ko'rsating
- Rag'batlantiruvchi ohangda yozing`;

    try {
        const response = await aiRouter({
            prompt,
            maxTokens: 1500,
            temperature: 0.5,
            schema: null,
        });

        const text = (response.text ?? '').replace(/```json|```/g, '').trim();
        const parsed = JSON.parse(text) as Record<string, unknown>;

        const pronunciationScore = clampScore(parsed.pronunciationScore as number);
        const grammarScore = clampScore(parsed.grammarScore as number);
        const fluencyScore = clampScore(parsed.fluencyScore as number);
        const vocabularyScore = clampScore(parsed.vocabularyScore as number);
        const overallScore = Math.round(
            (pronunciationScore * 0.25 + grammarScore * 0.30 + fluencyScore * 0.25 + vocabularyScore * 0.20)
        );

        const grammarErrors = ((parsed.grammarErrors as unknown[]) ?? []).map((e: unknown) => {
            const err = e as Record<string, string>;
            return {
                original: err.original ?? '',
                corrected: err.corrected ?? '',
                explanation: err.explanation ?? '',
                rule: err.rule ?? '',
            };
        });

        // Faoliyatni saqlash
        await saveActivity({
            userId,
            skillType: 'speaking' as SkillType,
            topic,
            difficulty: 'medium',
            correctAnswers: overallScore >= 60 ? 1 : 0,
            wrongAnswers: overallScore < 60 ? 1 : 0,
            responseTime: audioDuration,
            vocabularyUsed: (parsed.vocabularyUsed as string[]) ?? [],
            grammarErrors: grammarErrors.map(e => e.rule),
            language,
            level,
            timestamp: admin.firestore.Timestamp.now(),
            scorePercent: overallScore,
            weakItems: grammarErrors.map(e => e.rule),
            strongItems: [],
        });

        return {
            pronunciationScore,
            grammarScore,
            fluencyScore,
            vocabularyScore,
            overallScore,
            pronunciationFeedback: (parsed.pronunciationFeedback as string) ?? '',
            grammarFeedback: (parsed.grammarFeedback as string) ?? '',
            fluencyFeedback: (parsed.fluencyFeedback as string) ?? '',
            vocabularyFeedback: (parsed.vocabularyFeedback as string) ?? '',
            grammarErrors,
            vocabularyUsed: (parsed.vocabularyUsed as string[]) ?? [],
            suggestedVocabulary: (parsed.suggestedVocabulary as string[]) ?? [],
            overallFeedback: (parsed.overallFeedback as string) ?? '',
            improvementTips: (parsed.improvementTips as string[]) ?? [],
            nextTask: parsed.nextTask as string | undefined,
            metadata: {
                model: response.model || 'gemini-2.0-flash',
                wordsPerMinute: wpm,
                totalWords,
                audioDuration,
            },
        };
    } catch (error: unknown) {
        console.error('Speaking assessment xatosi:', error);
        throw new Error(`Speaking baholash xatosi: ${error instanceof Error ? error.message : String(error)}`);
    }
}

// ═══════════════════════════════════════════════════════════════
// YORDAMCHI
// ═══════════════════════════════════════════════════════════════

function clampScore(score: unknown): number {
    const n = typeof score === 'number' ? score : 50;
    return Math.max(0, Math.min(100, Math.round(n)));
}