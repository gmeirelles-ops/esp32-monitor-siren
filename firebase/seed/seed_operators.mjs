import { initializeApp } from 'firebase/app';
import {
  createUserWithEmailAndPassword,
  getAuth,
  signInWithEmailAndPassword,
} from 'firebase/auth';
import { doc, getDocs, getFirestore, collection, setDoc } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyDPty7URXLaLyyvqQUSYZOXmreq-Ql__bg',
  appId: '1:539202171240:web:6d1d00134b0e2e777f66dd',
  messagingSenderId: '539202171240',
  projectId: 'monitor-sirenv2-6d201',
  authDomain: 'monitor-sirenv2-6d201.firebaseapp.com',
  storageBucket: 'monitor-sirenv2-6d201.firebasestorage.app',
};

const email = process.env.FIREBASE_EMAIL ?? 'operador.teste@diponto.com.br';
const password = process.env.FIREBASE_PASSWORD ?? 'SireneTeste2026!';

const operators = [
  { codigo: '1001', nome: 'Sheila', is_gestor: false },
  { codigo: '1002', nome: 'Cleiton', is_gestor: false },
  { codigo: '1003', nome: 'Andre', is_gestor: true },
];

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

async function ensureAuth() {
  try {
    await signInWithEmailAndPassword(auth, email, password);
  } catch (err) {
    const code = err?.code ?? '';
    if (code === 'auth/user-not-found' || code === 'auth/invalid-credential') {
      await createUserWithEmailAndPassword(auth, email, password);
      return;
    }
    throw err;
  }
}

async function main() {
  await ensureAuth();
  const now = new Date();

  for (const op of operators) {
    await setDoc(doc(db, 'operators', op.codigo), {
      codigo: op.codigo,
      nome: op.nome,
      ativo: true,
      is_gestor: op.is_gestor,
      updated_at: now,
    });
    console.log(`OK: PIN ${op.codigo} — ${op.nome}${op.is_gestor ? ' (gestor)' : ''}`);
  }

  const snapshot = await getDocs(collection(db, 'operators'));
  console.log(`\nOperadores na nuvem (${snapshot.size}):`);
  for (const item of snapshot.docs) {
    const data = item.data();
    console.log(`  ${data.codigo} — ${data.nome} (gestor=${data.is_gestor})`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
