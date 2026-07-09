/// Labels legíveis em português para códigos `motivo` publicados pelo firmware.
const Map<String, String> rejectionMotivoLabels = {
  'json_invalido': 'Comando JSON inválido',
  'cmd_ausente': 'Comando sem campo cmd',
  'cmd_desconhecido': 'Comando desconhecido',
  'payload_grande': 'Payload do comando muito grande',
  'fila_cheia': 'Fila de comandos cheia',
  'cmd_durante_teste': 'Comando bloqueado durante teste',
  'cmd_durante_ota': 'Comando bloqueado durante atualização OTA',
  'set_batch_durante_teste': 'Não é possível configurar lote durante teste',
  'config_durante_teste': 'Configuração bloqueada durante teste em andamento',
  'set_batch_campos_invalidos': 'Parâmetros do lote inválidos',
  'end_batch_durante_teste': 'Não é possível encerrar lote durante teste',
  'end_batch_durante_calibracao': 'Não é possível encerrar lote durante calibração',
  'end_batch_durante_ensaio': 'Não é possível encerrar lote durante ensaio',
  'end_batch_durante_ota': 'Não é possível encerrar lote durante OTA',
  'calibracao_estado_invalido': 'Calibração não permitida neste estado',
  'calibracao_pzem_falha': 'Falha do PZEM durante calibração',
  'ensaio_ja_ativo': 'Ensaio já em andamento',
  'ensaio_estado_invalido': 'Ensaio não permitido neste estado',
  'ensaio_durante_teste': 'Ensaio bloqueado durante teste',
  'ensaio_campos_invalidos': 'Parâmetros do ensaio inválidos',
  'ensaio_inativo': 'Nenhum ensaio ativo para parar',
  'pzem_ocupado': 'Medidor de potência ocupado',
  'ota_estado_invalido': 'OTA não permitida neste estado',
  'ota_url_invalida': 'URL de firmware inválida',
  'ota_falha_inicio': 'Falha ao iniciar atualização OTA',
  'reset_wifi_durante_teste': 'Reset Wi-Fi bloqueado durante teste',
  'reset_wifi_durante_ota': 'Reset Wi-Fi bloqueado durante OTA',
  'reset_wifi_falha': 'Falha ao resetar Wi-Fi',
  'set_bancada_durante_teste': 'Alteração de bancada bloqueada durante teste',
  'set_bancada_durante_ota': 'Alteração de bancada bloqueada durante OTA',
  'set_bancada_invalida': 'Número de bancada inválido',
  'set_bancada_falha': 'Falha ao alterar bancada',
  'batch_nvs_fault': 'Falha ao gravar lote na memória do dispositivo',
  'lote_cheio': 'Cota do lote atingida — não é possível testar mais',
  'peca_ja_aprovada': 'Aguarde — peça já aprovada',
  'teste_estado_invalido': 'Teste não permitido neste estado — aguarde a bancada',
  'pzem_falha': 'PZEM desconectado — ligue o medidor e aguarde recuperação',
  'lote_inativo': 'Nenhum lote ativo no dispositivo',
  'batch_sem_confirmacao': 'Lote enviado mas sem confirmação do dispositivo',
  'mqtt_desconectado': 'MQTT desconectado',
  'desconhecido': 'Motivo desconhecido',
};

/// Retorna label legível; mantém o código se não houver tradução.
String formatRejectionMotivo(String motivo) {
  return rejectionMotivoLabels[motivo] ?? motivo;
}

/// Cooldown pós-aprovação — aviso integrado no cartão do operador.
bool isCooldownRejection(String? motivo) => motivo == 'peca_ja_aprovada';

/// Rejeições passageiras: não persistem após teste nem geram snackbar inferior.
bool isTransientRejection(String? motivo) =>
    motivo == 'peca_ja_aprovada' || motivo == 'teste_estado_invalido';
