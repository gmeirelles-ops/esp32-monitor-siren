/// Mensagens Firebase Auth em português para o operador de bancada.
String firebaseAuthErrorPt(String code) {
  switch (code) {
    case 'invalid-email':
      return 'E-mail inválido.';
    case 'user-disabled':
      return 'Conta desativada. Contacte o administrador.';
    case 'user-not-found':
      return 'Usuário não encontrado.';
    case 'wrong-password':
      return 'Senha incorreta.';
    case 'invalid-credential':
      return 'E-mail ou senha incorretos.';
    case 'too-many-requests':
      return 'Muitas tentativas. Aguarde alguns minutos.';
    case 'network-request-failed':
      return 'Sem conexão com a internet.';
    case 'operation-not-allowed':
      return 'Login por e-mail não está habilitado no Firebase.';
    default:
      return 'Falha ao entrar ($code).';
  }
}
