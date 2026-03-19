// functions/src/prompts/motivation_message.ts
// Motivation Message Prompt — YANGILANDI
// ✅ Har kirganida turli xil xabar
// ✅ Vaqtga qarab (tong/kun/tun) moslashadi
// ✅ O'zbek va ingliz tillarida
// ✅ Foydalanuvchi ismi dinamik

import { aiRouter } from '../ai/ai_router';

export async function generateMotivationMessage(params: {
    studentName: string;
    context: 'low_performance' | 'good_streak' | 'level_up' | 'long_absence' | 'milestone' | 'user_returned' | 'streak_risk';
    language: 'uz' | 'en';
    details?: {
        currentStreak?: number;
        recentScore?: number;
        daysAbsent?: number;
        milestone?: string;
        timeOfDay?: 'morning' | 'afternoon' | 'evening' | 'night';
    };
}): Promise<string> {
    const { studentName, context, language, details = {} } = params;

    // Vaqtni aniqlash
    const hour = new Date().getHours();
    const timeOfDay = details.timeOfDay ?? (
        hour < 12 ? 'morning' :
            hour < 17 ? 'afternoon' :
                hour < 21 ? 'evening' : 'night'
    );

    const timeGreetingUz: Record<string, string> = {
        morning: 'Xayrli tong',
        afternoon: 'Xayrli kun',
        evening: 'Xayrli kech',
        night: 'Xayrli tun',
    };
    const timeGreetingEn: Record<string, string> = {
        morning: 'Good morning',
        afternoon: 'Good afternoon',
        evening: 'Good evening',
        night: 'Good night',
    };

    const greeting = language === 'uz' ? timeGreetingUz[timeOfDay] : timeGreetingEn[timeOfDay];

    // Kontekstga qarab prompt tuzish
    const contextDescriptions: Record<string, string> = {
        user_returned: language === 'uz'
            ? `Foydalanuvchi ${studentName} ilovaga qaytib kirdi. "${greeting}, ${studentName}!" bilan boshlang. Uni ko'rib xursandligingizni bildiring, til o'rganish safarida davom etishiga ilhom bering. Bugun nima o'rganishi mumkinligiga ishora qiling. Samimiy va yurakdan gapirilgan 2-3 ta gap yozing.`
            : `User ${studentName} has returned to the app. Start with "${greeting}, ${studentName}!". Express joy at seeing them, inspire them to continue their language learning journey. Hint at what they can learn today. Write 2-3 warm, heartfelt sentences.`,

        low_performance: language === 'uz'
            ? `${studentName} so'nggi testda ${details.recentScore ?? 50}% oldi. "${greeting}, ${studentName}!" bilan boshlang. Muvaffaqiyatsizlik o'rganishning bir qismi ekanini tushuntiring. Uni ruhlantirib, qaytadan urinishga undang. Kuchli, ta'sirli 2-3 gap yozing.`
            : `${studentName} scored ${details.recentScore ?? 50}% recently. Start with "${greeting}, ${studentName}!". Explain that failure is part of learning. Encourage them strongly to try again. Write 2-3 powerful, motivating sentences.`,

        good_streak: language === 'uz'
            ? `${studentName} ${details.currentStreak ?? 5} kun ketma-ket mashq qildi! "${greeting}, ${studentName}!" bilan boshlang. Bu g'ayrat va intizomni maqtang. Davom etishga ilhom bering. Hayajonli, quvnoq 2-3 gap yozing.`
            : `${studentName} has practiced ${details.currentStreak ?? 5} days in a row! Start with "${greeting}, ${studentName}!". Praise this dedication and discipline. Inspire them to continue. Write 2-3 exciting, joyful sentences.`,

        streak_risk: language === 'uz'
            ? `${studentName}ning ${details.currentStreak ?? 0} kunlik streaki yo'qolish xavfida — bugun hali mashq qilinmagan. "${greeting}, ${studentName}!" bilan boshlang. Streakni saqlab qolishga undang. Faqat 5-10 daqiqa yetishini aytib, harakat qildiring. Kuchli, shoshilinch 2-3 gap yozing.`
            : `${studentName}'s ${details.currentStreak ?? 0}-day streak is at risk — no practice yet today. Start with "${greeting}, ${studentName}!". Urge them to keep the streak alive. Tell them only 5-10 minutes is enough. Write 2-3 urgent but encouraging sentences.`,

        level_up: language === 'uz'
            ? `${studentName} yangi darajaga o'tishga tayyor! "${greeting}, ${studentName}!" bilan boshlang. Bu ulkan yutuqni nishonlang. Yangi bosqichda yangi imkoniyatlar kutishini aytib ilhom bering. Tantanali, g'urur to'la 2-3 gap yozing.`
            : `${studentName} is ready to level up! Start with "${greeting}, ${studentName}!". Celebrate this huge achievement. Tell them new opportunities await at the next level. Write 2-3 triumphant, proud sentences.`,

        long_absence: language === 'uz'
            ? `${studentName} ${details.daysAbsent ?? 7} kundan keyin qaytib keldi. "${greeting}, ${studentName}!" bilan boshlang. Qaytganidan juda xursandligingizni bildiring. Hech narsa yo'qolmaganini, hozirdan boshlasa bo'lishini aytib rag'batlantiring. Iliq, quchoqlovchi 2-3 gap yozing.`
            : `${studentName} is back after ${details.daysAbsent ?? 7} days. Start with "${greeting}, ${studentName}!". Express great joy at their return. Tell them nothing is lost and they can start right now. Write 2-3 warm, welcoming sentences.`,

        milestone: language === 'uz'
            ? `${studentName} muhim yutuqqa erishdi: ${details.milestone ?? '100 ta mashq bajarildi'}! "${greeting}, ${studentName}!" bilan boshlang. Bu erishuvni quvonch bilan nishonlang. Davom etishga undang. Festiv, g'urur to'la 2-3 gap yozing.`
            : `${studentName} achieved a milestone: ${details.milestone ?? '100 exercises completed'}! Start with "${greeting}, ${studentName}!". Celebrate this achievement joyfully. Encourage them to continue. Write 2-3 festive, proud sentences.`,
    };

    const langInstruction = language === 'uz'
        ? "Faqat O'zbek tilida yozing (lotin yozuvida). Hech qanday izoh, qo'shtirnoq yoki qo'shimcha matn qo'shmang."
        : "Write ONLY in English. No explanations, quotes, or extra text.";

    const randomnessNote = language === 'uz'
        ? "MUHIM: Har safar yangi, original, boshqacha xabar yozing. Bir xil so'zlarni takrorlamang."
        : "IMPORTANT: Write a fresh, original, different message each time. Never repeat the same phrases.";

    const prompt = `Siz do'stona va ilhomlantiruvchi til o'rganish kouchi (AI Coach)siz.

${contextDescriptions[context] ?? contextDescriptions['user_returned']}

${langInstruction}
${randomnessNote}
Faqat xabar matnini qaytaring. Hech narsa qo'shmang.`;

    try {
        const response = await aiRouter({ prompt, maxTokens: 200, temperature: 0.92, schema: null });
        let message = (response.text ?? response.content ?? '').replace(/```/g, '').trim();

        // Tirnoqlarni olib tashlash
        message = message.replace(/^["'«»]|["'«»]$/g, '').trim();

        if (!message || message.length < 10) throw new Error('Message too short');
        if (message.length > 600) {
            const sentences = message.match(/[^.!?]+[.!?]+/g) ?? [];
            message = sentences.slice(0, 3).join(' ').trim();
        }
        return message;
    } catch (error: unknown) {
        console.error('Motivation message failed:', error);
        return buildFallback(studentName, context, language, timeOfDay, details);
    }
}

// ═══════════════════════════════════════════════════════════════
// FALLBACK — AI ishlamasa kuchli statik xabarlar
// Har safar tasodifiy tanlanadi
// ═══════════════════════════════════════════════════════════════

function buildFallback(
    name: string,
    context: string,
    language: 'uz' | 'en',
    timeOfDay: string,
    details: Record<string, unknown>
): string {
    const streak = (details.currentStreak as number) ?? 0;
    const score = (details.recentScore as number) ?? 50;

    const greetingUz: Record<string, string> = {
        morning: 'Xayrli tong', afternoon: 'Xayrli kun',
        evening: 'Xayrli kech', night: 'Xayrli tun',
    };
    const greetingEn: Record<string, string> = {
        morning: 'Good morning', afternoon: 'Good afternoon',
        evening: 'Good evening', night: 'Good night',
    };

    const g = language === 'uz' ? greetingUz[timeOfDay] : greetingEn[timeOfDay];

    const fallbacksUz: Record<string, string[]> = {
        user_returned: [
            `${g}, ${name}! 🌟 Seni bu yerda ko'rib turganimizdan bag'oyat xursandmiz. Har bir kun o'rganish uchun yangi imkoniyat — bugun ham katta qadam tashlaysan!`,
            `${g}, ${name}! ☀️ Ilovaga kirganingdan quvonamiz. Sen til o'rganish yo'lida eng muhim narsani qilding — BoshladINg. Davom et, g'alaba yaqin!`,
            `${g}, ${name}! 💫 Biz seni doim kutib turamiz. Bugun ozgina bo'lsa ham mashq qilsang, bir yildan keyin sen boshqa odam bo'lasan. Ishlaymizmi?`,
            `${g}, ${name}! 🚀 Sening muvaffaqiyating bizga ilhom beradi. Bugun ham yangi bilim orttir — har bir so'z yangi eshik ochadi!`,
            `${g}, ${name}! 🏆 Ko'p odam boshlaydi, lekin davom ettirish — bu g'oliblar ishi. Sen o'sha g'oliblardan birisan. Bugun ham birlashib ketamizmi?`,
        ],
        low_performance: [
            `${g}, ${name}! 💪 ${score}% — bu boshlash uchun ajoyib nuqta! Dunyoning eng buyuk odamlari ham avval xato qilgan. Sen to'g'ri yo'ldasан — davom et!`,
            `${g}, ${name}! 🌱 Xato qilish — o'rganishning eng yaxshi usuli. Har bir noto'g'ri javob miyangni kuchaytiradi. Yana bir bor urinib ko'ramizmi?`,
            `${g}, ${name}! ⭐ Qiyinchilik seni to'xtatib qo'ymaydi — u seni kuchaytiradi. Bugun bir oz ko'proq mashq qilsang, ertaga boshqacha bo'lasan!`,
        ],
        good_streak: [
            `${g}, ${name}! 🔥 ${streak} kun ketma-ket! Bu oddiy odam qila olmaydi — bu intizom, bu g'ayrat! Sen ajoyibsan, davom et!`,
            `${g}, ${name}! 🎯 ${streak} kunlik streak — bu sening qat'iyatingning dalili. Har kun biroz, lekin muntazam — mana muvaffaqiyat siri!`,
            `${g}, ${name}! 🌟 Streakingni ko'rib o'zimiz ham ilhom olamiz! ${streak} kun — bu kichik g'alaba emas, bu ulkan jasorat!`,
        ],
        streak_risk: [
            `${g}, ${name}! ⚡ ${streak > 0 ? `${streak} kunlik streaking` : 'Yangi streaking'} xavfda! Faqat 5 daqiqa — bugungi mashqni tugatib, rekordingni saqlab qol!`,
            `${g}, ${name}! 🔥 Bugun hali mashq qilinmadi. Streakni yo'qotma — 10 daqiqalik flashcard yetarli. Hoziroq boshlasak bo'ladimi?`,
            `${g}, ${name}! ⏰ Kun tugayapti — streakingni unutma! Kichik qadam ham katta farq qiladi. Hozir 5 daqiqa ajrat!`,
        ],
        level_up: [
            `${g}, ${name}! 🎉🚀 Tabriklaymiz! Yangi darajaga chiqdingiz — bu sizning mehnatingizning mevasi! Yangi bosqichda yangi imkoniyatlar kutmoqda!`,
            `${g}, ${name}! 🏆 LEVEL UP! Bu oddiy voqea emas — bu sening o'sishingning isboti. Oldingda yangi dunyo ochildi!`,
        ],
        long_absence: [
            `${g}, ${name}! 🤗 Nihoyat qaytdingiz! Seni juda sog'indik. Hech narsa yo'qolmagan — bilimingiz hamon bor. Keling, birga yangilaymiz!`,
            `${g}, ${name}! 💙 Qaytganingdan xursandmiz! Uzilish bo'lsa ham, maqsad o'zgarmadi. Bugundan yangidan boshlash mumkin — va bu ajoyib!`,
        ],
        milestone: [
            `${g}, ${name}! 🌟🎊 Tabriklaymiz! Bu yutuq — katta mehnatning natijasi. Sen ajoyib ish qildingiz, davom eting!`,
        ],
    };

    const fallbacksEn: Record<string, string[]> = {
        user_returned: [
            `${g}, ${name}! 🌟 We're so happy to see you here! Every day is a new opportunity to learn — take a big step today!`,
            `${g}, ${name}! ☀️ Welcome back! You did the most important thing — you STARTED. Keep going, success is near!`,
            `${g}, ${name}! 💫 We always wait for you. Even a little practice today will make you a different person in a year. Ready?`,
            `${g}, ${name}! 🚀 Your progress inspires us! Learn something new today — every word opens a new door!`,
            `${g}, ${name}! 🏆 Many people start, but continuing is what champions do. You're one of those champions. Let's go!`,
        ],
        low_performance: [
            `${g}, ${name}! 💪 ${score}% is a great starting point! The world's greatest people made mistakes first. You're on the right track — keep going!`,
            `${g}, ${name}! 🌱 Making mistakes is the best way to learn. Every wrong answer strengthens your brain. Shall we try again?`,
            `${g}, ${name}! ⭐ Challenges don't stop you — they make you stronger. A little more practice today means a better you tomorrow!`,
        ],
        good_streak: [
            `${g}, ${name}! 🔥 ${streak} days in a row! This isn't something ordinary people do — this is discipline and dedication! You're amazing, keep it up!`,
            `${g}, ${name}! 🎯 A ${streak}-day streak proves your commitment. A little every day, consistently — that's the secret to success!`,
            `${g}, ${name}! 🌟 Your streak inspires us too! ${streak} days — that's not a small win, that's a massive achievement!`,
        ],
        streak_risk: [
            `${g}, ${name}! ⚡ Your ${streak > 0 ? `${streak}-day streak` : 'streak'} is at risk! Just 5 minutes — finish today's practice and keep your record alive!`,
            `${g}, ${name}! 🔥 No practice yet today. Don't lose your streak — a 10-minute flashcard session is enough. Shall we start now?`,
            `${g}, ${name}! ⏰ The day is ending — don't forget your streak! A small step makes a big difference. Spare 5 minutes now!`,
        ],
        level_up: [
            `${g}, ${name}! 🎉🚀 Congratulations! You've reached a new level — this is the fruit of your hard work! New opportunities await!`,
            `${g}, ${name}! 🏆 LEVEL UP! This isn't just an event — it's proof of your growth. A new world has opened before you!`,
        ],
        long_absence: [
            `${g}, ${name}! 🤗 You're finally back! We missed you so much. Nothing is lost — your knowledge is still there. Let's refresh together!`,
            `${g}, ${name}! 💙 So glad you're back! Even with a break, the goal hasn't changed. Starting fresh today is wonderful — and totally possible!`,
        ],
        milestone: [
            `${g}, ${name}! 🌟🎊 Congratulations! This achievement is the result of great effort. You did amazing work, keep going!`,
        ],
    };

    const pool = language === 'uz'
        ? (fallbacksUz[context] ?? fallbacksUz['user_returned'])
        : (fallbacksEn[context] ?? fallbacksEn['user_returned']);

    // Tasodifiy tanlash — har safar boshqacha
    const randomIndex = Math.floor(Math.random() * pool.length);
    return pool[randomIndex];
}