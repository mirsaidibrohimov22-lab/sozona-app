// SOZONA — Promo kod yaratish scripti
// Ishlatish:
//   1. Bu faylni functions/ papkasiga qo'ying
//   2. service-account.json ni Firebase Console dan yuklab oling
//      (Project Settings → Service Accounts → Generate new private key)
//   3. Terminal: cd functions
//   4. Terminal: node create_promo_codes.js

const admin = require('firebase-admin');
const fs = require('fs');
const crypto = require('crypto');

// ── SOZLAMALAR ────────────────────────────────────────────────
const CONFIG = {
    // Nechta kod yaratish
    count: 20,

    // Har bir kod necha kishi uchun
    // 2 = bir kodni 2 ta odam ishlatishi mumkin (har biri 1 marta)
    maxUses: 2,

    // Necha oylik premium
    durationMonths: 1,

    // Kodning o'zi qachon tugaydi (null = cheksiz)
    expiresAt: null, // yoki: new Date('2025-12-31')

    // Kod prefiksi
    prefix: 'SOZONA',
};
// ─────────────────────────────────────────────────────────────

const serviceAccount = require('./service-account.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// Tasodifiy kod yaratish — o'xshash harflar yo'q (0,O,I,1,L)
function generateCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
        const byte = crypto.randomBytes(1)[0];
        code += chars[byte % chars.length];
    }
    return `${CONFIG.prefix}-${code.slice(0, 3)}-${code.slice(3)}`;
}

async function createPromoCodes() {
    console.log(`\n🚀 ${CONFIG.count} ta promo kod yaratilmoqda...`);
    console.log(`   Har bir kod: ${CONFIG.durationMonths} oylik premium`);
    console.log(`   Max foydalanuvchi: ${CONFIG.maxUses} ta kishi\n`);

    const codes = [];
    const batch = db.batch();

    for (let i = 0; i < CONFIG.count; i++) {
        let code;
        do { code = generateCode(); } while (codes.includes(code));
        codes.push(code);

        const data = {
            maxUses: CONFIG.maxUses,
            usedCount: 0,
            durationMonths: CONFIG.durationMonths,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            note: `Batch #${new Date().toISOString().slice(0, 10)}`,
        };

        if (CONFIG.expiresAt) {
            data.expiresAt = admin.firestore.Timestamp.fromDate(CONFIG.expiresAt);
        }

        batch.set(db.collection('promoCodes').doc(code), data);
    }

    await batch.commit();

    // Faylga saqlash
    const timestamp = new Date().toISOString().slice(0, 16).replace('T', '_').replace(':', '-');
    const filename = `promo_codes_${timestamp}.txt`;
    const content = [
        `SOZONA PROMO KODLAR`,
        `Yaratilgan: ${new Date().toLocaleString('uz-UZ')}`,
        `Har biri: ${CONFIG.durationMonths} oylik premium | ${CONFIG.maxUses} ta kishi`,
        `${'─'.repeat(38)}`,
        ...codes.map((c, i) => `${String(i + 1).padStart(2, '0')}. ${c}`),
        `${'─'.repeat(38)}`,
        `Jami: ${codes.length} ta kod`,
    ].join('\n');

    fs.writeFileSync(filename, content, 'utf8');

    console.log('✅ Firestore ga saqlandi!\n');
    console.log(`📄 Fayl: ${filename}\n`);
    console.log('📋 Kodlar:');
    codes.forEach((c, i) => console.log(`  ${String(i + 1).padStart(2, '0')}. ${c}`));
    console.log(`\n✅ Jami: ${codes.length} ta kod tayyor!\n`);

    process.exit(0);
}

createPromoCodes().catch((err) => {
    console.error('❌ Xatolik:', err.message);
    process.exit(1);
});