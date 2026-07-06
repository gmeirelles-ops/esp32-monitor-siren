# Atribuir claim `manager` a um usuário Firebase Auth
#
# Uso:
#   $env:GOOGLE_APPLICATION_CREDENTIALS="caminho\serviceAccount.json"
#   node scripts/set_manager_claim.js usuario@empresa.com.br

const admin = require('firebase-admin');

const email = process.argv[2];
if (!email) {
  console.error('Uso: node scripts/set_manager_claim.js <email>');
  process.exit(1);
}

admin.initializeApp();
admin
  .auth()
  .getUserByEmail(email)
  .then((user) => admin.auth().setCustomUserClaims(user.uid, { manager: true }))
  .then(() => console.log(`Claim manager=true em ${email}`))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
