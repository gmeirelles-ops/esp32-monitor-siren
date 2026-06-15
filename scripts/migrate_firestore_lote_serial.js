/**
 * Migra documentos flat legados para hierarquia lote/seriais/reprovadas.
 *
 * Uso (requer firebase-admin e credenciais):
 *   npm install firebase-admin
 *   GOOGLE_APPLICATION_CREDENTIALS=... node scripts/migrate_firestore_lote_serial.js [--dry-run]
 */
const admin = require('firebase-admin');

const dryRun = process.argv.includes('--dry-run');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

function parseFlatId(id) {
  const idx = id.lastIndexOf('_');
  if (idx <= 0) return null;
  const numeroOp = id.slice(0, idx);
  const sequencial = id.slice(idx + 1);
  if (!/^\d+$/.test(sequencial)) return null;
  return { numeroOp, sequencial };
}

async function migrate() {
  const snap = await db.collection('test_results').get();
  let migrated = 0;
  let skipped = 0;

  for (const doc of snap.docs) {
    const parsed = parseFlatId(doc.id);
    if (!parsed) {
      skipped++;
      continue;
    }

    const data = doc.data();
    const { numeroOp, sequencial } = parsed;
    const loteRef = db.collection('test_results').doc(numeroOp);
    const veredito = (data.veredito || '').toUpperCase();
    const serial = data.serial;

    const batch = db.batch();

    batch.set(
      loteRef,
      {
        numero_op: numeroOp,
        id_produto: data.id_produto ?? null,
        ano: data.ano ?? null,
        station_id: data.station_id ?? 'migrated',
        migrated_from: doc.id,
      },
      { merge: true },
    );

    if (veredito === 'APROVADO' && serial) {
      batch.set(loteRef.collection('seriais').doc(String(serial)), {
        ...data,
        sequencial: Number(sequencial),
        migrated_from: doc.id,
      });
    } else if (veredito === 'REPROVADO') {
      batch.set(loteRef.collection('reprovadas').doc(sequencial), {
        ...data,
        sequencial: Number(sequencial),
        migrated_from: doc.id,
      });
    }

    if (dryRun) {
      console.log(`[dry-run] ${doc.id} -> test_results/${numeroOp}/...`);
    } else {
      await batch.commit();
    }
    migrated++;
  }

  console.log(`Done. migrated=${migrated} skipped=${skipped} dryRun=${dryRun}`);
}

migrate().catch((err) => {
  console.error(err);
  process.exit(1);
});
