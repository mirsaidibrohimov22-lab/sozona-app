// functions/src/middleware/cost_monitor.ts
// SO'ZONA — Cost Monitor (YANGILANGAN)
// ✅ Gemini 2.0 Flash narxi qo'shildi

import * as admin from 'firebase-admin';

// Gemini 2.0 Flash — juda arzon (1M token uchun)
const PRICING: Record<string, { input: number; output: number }> = {
    'gemini-2.0-flash': {
        input: 0.10 / 1_000_000,   // $0.10 per 1M input tokens
        output: 0.40 / 1_000_000,  // $0.40 per 1M output tokens
    },
    'gemini-1.5-flash': {
        input: 0.075 / 1_000_000,
        output: 0.30 / 1_000_000,
    },
    'gemini-pro': {
        input: 0.00,
        output: 0.00,
    },
    'gpt-4o-mini': {
        input: 0.15 / 1_000_000,
        output: 0.60 / 1_000_000,
    },
};

interface CostData {
    promptTokens: number;
    completionTokens: number;
    totalTokens: number;
    model: string;
    cost: number;
}

export function calculateCost(
    model: string,
    promptTokens: number,
    completionTokens: number
): number {
    const pricing = PRICING[model] ?? PRICING['gemini-2.0-flash'];
    return promptTokens * pricing.input + completionTokens * pricing.output;
}

export async function logCost(
    uid: string,
    functionName: string,
    data: CostData
): Promise<void> {
    try {
        const costDoc = {
            uid,
            functionName,
            model: data.model,
            promptTokens: data.promptTokens,
            completionTokens: data.completionTokens,
            totalTokens: data.totalTokens,
            cost: data.cost,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        };

        await admin.firestore().collection('ai_costs').add(costDoc);

        const userCostRef = admin.firestore().collection('user_costs').doc(uid);

        await admin.firestore().runTransaction(async (transaction: admin.firestore.Transaction) => {
            const doc = await transaction.get(userCostRef);
            if (!doc.exists) {
                transaction.set(userCostRef, {
                    totalCost: data.cost,
                    totalTokens: data.totalTokens,
                    requestCount: 1,
                    lastRequest: admin.firestore.FieldValue.serverTimestamp(),
                });
            } else {
                transaction.update(userCostRef, {
                    totalCost: admin.firestore.FieldValue.increment(data.cost),
                    totalTokens: admin.firestore.FieldValue.increment(data.totalTokens),
                    requestCount: admin.firestore.FieldValue.increment(1),
                    lastRequest: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        });

        console.log(`💰 Cost logged: $${data.cost.toFixed(6)} for ${uid} [${functionName}]`);
    } catch (error) {
        console.error('Error logging cost:', error);
    }
}

export async function getUserCost(uid: string): Promise<{
    totalCost: number;
    totalTokens: number;
    requestCount: number;
}> {
    const doc = await admin.firestore().collection('user_costs').doc(uid).get();

    if (!doc.exists) {
        return { totalCost: 0, totalTokens: 0, requestCount: 0 };
    }

    const data = doc.data()!;
    return {
        totalCost: (data.totalCost as number) ?? 0,
        totalTokens: (data.totalTokens as number) ?? 0,
        requestCount: (data.requestCount as number) ?? 0,
    };
}