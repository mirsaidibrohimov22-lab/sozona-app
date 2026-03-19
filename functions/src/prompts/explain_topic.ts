// functions/src/prompts/explain_topic.ts
// SO'ZONA — Explain Topic (AI Chat)

import { callAIWithRetry } from '../ai/ai_router';
import { parseAndValidate } from '../schemas/schema_validator';
import { checkRateLimit } from '../middleware/rate_limiter';
import { calculateCost, logCost } from '../middleware/cost_monitor';
import explainSchema from '../schemas/explain_topic_schema.json';

interface ExplainTopicRequest {
    topic: string;
    language: 'english' | 'deutsch';
    level: 'beginner' | 'intermediate' | 'advanced';
    userQuestion?: string;
}

export async function explainTopic(data: ExplainTopicRequest, uid: string): Promise<unknown> {
    await checkRateLimit(uid);

    const prompt = buildExplainPrompt(data);

    const aiResponse = await callAIWithRetry({
        messages: [
            { role: 'system', content: 'You are a friendly language tutor who explains grammar and vocabulary clearly with examples.' },
            { role: 'user', content: prompt },
        ],
        temperature: 0.7,
        maxTokens: 1000,
    });

    const { data: explanation, errors } = parseAndValidate(aiResponse.content, explainSchema);

    if (errors) {
        console.error('Validation errors:', errors);
        throw new Error(`AI javob noto'g'ri: ${errors.join(', ')}`);
    }

    const cost = calculateCost(
        aiResponse.model,
        aiResponse.usage?.promptTokens ?? 0,
        aiResponse.usage?.completionTokens ?? 0
    );

    await logCost(uid, 'explainTopic', {
        model: aiResponse.model,
        promptTokens: aiResponse.usage?.promptTokens ?? 0,
        completionTokens: aiResponse.usage?.completionTokens ?? 0,
        totalTokens: aiResponse.usage?.totalTokens ?? 0,
        cost,
    });

    return explanation;
}

function buildExplainPrompt(data: ExplainTopicRequest): string {
    const levelGuide = getExplainLevelGuide(data.level);
    const question = data.userQuestion ? `\n\nSpecific question: "${data.userQuestion}"` : '';

    return `Explain this ${data.language} grammar topic for ${data.level} learners: "${data.topic}"${question}

${levelGuide}

Return ONLY a valid JSON object:
{
  "topic": "${data.topic}",
  "explanation": "Clear, simple explanation in Uzbek",
  "examples": [{"sentence": "Example", "translation": "Tarjima", "note": "Tip"}],
  "commonMistakes": [{"wrong": "X", "correct": "Y", "why": "Reason"}],
  "tips": ["Tip 1", "Tip 2"],
  "relatedTopics": ["Topic 1", "Topic 2"]
}`;
}

function getExplainLevelGuide(level: string): string {
    switch (level) {
        case 'beginner': return 'Use very simple language, basic examples, avoid complex grammar terms';
        case 'intermediate': return 'Use clear language, practical examples, some grammar terminology';
        case 'advanced': return 'Use detailed explanations, complex examples, proper grammar terminology';
        default: return '';
    }
}
