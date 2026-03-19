// functions/src/prompts/analyze_weakness.ts
// Analyze Weakness Prompt

import { aiRouter } from '../ai/ai_router';

export async function analyzeWeakness(params: {
    studentId: string;
    weakItems: Array<{
        type: 'word' | 'grammar_rule' | 'question';
        content: string;
        incorrectCount: number;
        lastAttempt: string;
    }>;
    recentScores: number[];
    language: 'en' | 'de';
    currentLevel: string;
}): Promise<{
    weakAreas: string[];
    suggestions: string[];
    recommendedExercises: string[];
    encouragement: string;
}> {
    const { weakItems, recentScores, language, currentLevel } = params;

    const wordErrors = weakItems.filter((item) => item.type === 'word');
    const grammarErrors = weakItems.filter((item) => item.type === 'grammar_rule');
    const averageScore = recentScores.length > 0
        ? recentScores.reduce((a, b) => a + b, 0) / recentScores.length
        : 0;
    const topWeakItems = weakItems.sort((a, b) => b.incorrectCount - a.incorrectCount).slice(0, 5);
    const languageName = language === 'en' ? 'English' : 'German';

    const prompt = `Analyze ${languageName} student weaknesses at ${currentLevel} level.
Average score: ${averageScore.toFixed(1)}%
Vocabulary errors: ${wordErrors.length}, Grammar errors: ${grammarErrors.length}
Top mistakes: ${topWeakItems.map((i) => `${i.type}: "${i.content}" (${i.incorrectCount} errors)`).join(', ')}

Return ONLY valid JSON:
{
  "weakAreas": ["area1", "area2"],
  "suggestions": ["tip1", "tip2", "tip3"],
  "recommendedExercises": ["exercise1", "exercise2"],
  "encouragement": "Motivating message"
}`;

    try {
        const response = await aiRouter({ prompt, maxTokens: 800, temperature: 0.7, schema: null });
        const text = (response.text ?? response.content ?? '').replace(/```json|```/g, '').trim();
        const analysis = JSON.parse(text) as {
            weakAreas: string[];
            suggestions: string[];
            recommendedExercises: string[];
            encouragement: string;
        };

        return {
            weakAreas: (analysis.weakAreas ?? []).slice(0, 4),
            suggestions: (analysis.suggestions ?? []).slice(0, 5),
            recommendedExercises: (analysis.recommendedExercises ?? []).slice(0, 4),
            encouragement: analysis.encouragement ?? '',
        };
    } catch (error: unknown) {
        console.error('Weakness analysis failed:', error);
        const weakAreas: string[] = [];
        if (wordErrors.length > grammarErrors.length) weakAreas.push('Vocabulary');
        if (grammarErrors.length > 0) weakAreas.push('Grammar');

        return {
            weakAreas: weakAreas.length > 0 ? weakAreas : ['General practice needed'],
            suggestions: [
                'Review your mistakes carefully',
                'Practice daily for 10-15 minutes',
                'Focus on one topic at a time',
                'Use flashcards for vocabulary',
            ],
            recommendedExercises: ['Vocabulary flashcards', 'Grammar exercises', 'Listening practice'],
            encouragement: averageScore >= 70
                ? "You're making good progress! Keep it up."
                : "Every mistake is a learning opportunity. You're improving!",
        };
    }
}
