// functions/src/prompts/cefr_level_guide.ts
// ✅ YANGI: Barcha prompt fayllar uchun markaziy CEFR darajasi ko'rsatmalari
// Bu fayl quiz, listening, flashcard, speaking generate da import qilinadi

export type CEFRLevel = 'A1' | 'A2' | 'B1' | 'B2' | 'C1';

export interface LevelGuide {
    description: string;
    vocabulary: string;
    grammar: string;
    sentenceLength: string;
    questionComplexity: string;
    forbiddenWords: string;
    textLength: string;
    examples: string;
}

export const CEFR_LEVEL_GUIDE: Record<CEFRLevel, LevelGuide> = {
    A1: {
        description: 'Complete beginner — knows only the most basic words and phrases',
        vocabulary: 'ONLY these topic areas: greetings, numbers 1-100, colors, days/months, family members (mother, father, sister, brother), body parts, common foods (bread, milk, water, apple), animals (cat, dog, bird), rooms (kitchen, bedroom), basic verbs (go, eat, drink, sleep, run, play, have, like, want)',
        grammar: 'ONLY: present simple tense (I play, she eats), "to be" (I am, you are), "have/has", basic questions (What? Where? Who?), simple negation (I don\'t like), articles (a, the), singular/plural',
        sentenceLength: 'MAX 6 words per sentence. NO complex clauses. NO "because", "although", "however".',
        questionComplexity: 'Questions must be answerable with 1-2 words or True/False. Example good: "Do you like football?" Example bad: "What is a popular sport where you kick a ball into a net?"',
        forbiddenWords: 'FORBIDDEN words for A1: "relaxing", "exercise", "popular", "prefer", "sometimes", "together", "wonderful", "fantastic", "experience", "activity" — these are B1+ level',
        textLength: 'Max 60 words for any text or dialogue',
        examples: `GOOD A1 question: "What sport is this? Football / Basketball / Tennis / Swimming"
GOOD A1 question: "Tom plays football. True or False?"
BAD A1 question: "What is a popular sport where you kick a ball into a net?"`,
    },
    A2: {
        description: 'Elementary — can handle simple, familiar topics',
        vocabulary: 'Common everyday words: shopping, transport (bus, train, car), weather, simple jobs (teacher, doctor, student), hobbies, food and restaurants, simple directions, feelings (happy, tired, hungry). Max ~1500 word families.',
        grammar: 'Present simple, present continuous (I am going), simple past (went, ate, played), future with "going to", comparatives (bigger, more expensive), basic prepositions of time/place, "can/can\'t", "want to/would like"',
        sentenceLength: 'Max 10 words per sentence. One subordinate clause allowed (because, when). No passive voice.',
        questionComplexity: 'Questions require short answers (1-5 words). Reading/listening texts: max 80 words.',
        forbiddenWords: 'AVOID: passive voice, subjunctive, complex conditional (would have been), formal register, academic vocabulary',
        textLength: 'Max 100 words for any text or dialogue',
        examples: `GOOD A2: "What did Maria do last weekend? She went shopping / She watched TV / She played tennis / She cooked dinner"
GOOD A2: "Where does Tom work? In a school / In a hospital / In a shop / At home"`,
    },
    B1: {
        description: 'Intermediate — can handle most everyday situations',
        vocabulary: 'Work and career, travel and tourism, health and lifestyle, environment basics, culture and media, relationships. Phrasal verbs (give up, take off, look forward to). ~3000 word families.',
        grammar: 'All basic tenses + present perfect (I have done), past continuous, conditionals 1 & 2 (If I go / If I went), passive voice (is made, was built), modal verbs (should, must, might), reported speech basics',
        sentenceLength: 'Up to 20 words per sentence. Multiple clauses allowed.',
        questionComplexity: 'Can include inference questions ("Why did she feel...?"), main idea questions. Texts: 120-180 words.',
        forbiddenWords: 'AVOID: C1+ idioms, highly formal register, rare vocabulary, complex academic terms',
        textLength: 'Max 200 words for texts, 150 for dialogues',
        examples: `GOOD B1: "What does the article suggest about healthy eating habits?"
GOOD B1: "According to the conversation, why did Mark change his job?"`,
    },
    B2: {
        description: 'Upper intermediate — can understand complex texts on concrete and abstract topics',
        vocabulary: 'Abstract concepts, current affairs, professional topics, literature references, idioms and fixed expressions, academic vocabulary (OALD 5000+), ~5000 word families',
        grammar: 'All tenses including perfect continuous, all conditionals (0-3 and mixed), passive constructions, relative clauses, subjunctive in formal contexts, advanced modal meanings, complex noun phrases',
        sentenceLength: 'Natural length — up to 30 words. Complex multi-clause sentences.',
        questionComplexity: 'Inference, attitude/opinion questions, implicit meaning, purpose questions. Texts: 200-280 words.',
        forbiddenWords: 'Avoid only C2-level arcane vocabulary and highly technical jargon',
        textLength: 'Max 300 words',
        examples: `GOOD B2: "What is the author\'s attitude towards technological progress in the article?"
GOOD B2: "How does the speaker\'s tone change throughout the conversation?"`,
    },
    C1: {
        description: 'Advanced — can express fluently, spontaneously and flexibly',
        vocabulary: 'Wide range including formal, academic, literary, idiomatic, technical (context-appropriate). Nuanced word choice. ~8000+ word families',
        grammar: 'Full grammatical range with emphasis on stylistic choice, inversion for emphasis, cleft sentences, complex nominalization, advanced discourse markers',
        sentenceLength: 'Unrestricted — natural academic/professional register',
        questionComplexity: 'Critical analysis, evaluation, nuance and implicit meaning. Texts: 300-400 words.',
        forbiddenWords: 'None — full vocabulary range',
        textLength: 'Up to 400 words',
        examples: `GOOD C1: "Evaluate the extent to which the speaker\'s argument is logically coherent."
GOOD C1: "What implicit criticism does the author make about current economic policies?"`,
    },
};

/** Prompt ichida ishlatiladigan qisqacha CEFR bloki */
export function buildLevelBlock(level: CEFRLevel, language: 'en' | 'de'): string {
    const g = CEFR_LEVEL_GUIDE[level];
    const langNote = language === 'de'
        ? '\nGerman-specific: For A1/A2 avoid complex German compound nouns and subjunctive II. For B1+ Konjunktiv II and Passiv are allowed.'
        : '';

    return `
=== CEFR LEVEL REQUIREMENTS: ${level} ===
Description: ${g.description}
Allowed vocabulary: ${g.vocabulary}
Allowed grammar: ${g.grammar}
Sentence length: ${g.sentenceLength}
Question complexity: ${g.questionComplexity}
${g.forbiddenWords}
Text/dialogue length: ${g.textLength}
Examples:
${g.examples}${langNote}
=== END LEVEL REQUIREMENTS ===
`.trim();
}