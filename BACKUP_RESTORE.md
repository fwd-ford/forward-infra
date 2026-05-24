# Backup and restore — ForwardService data layer

Estratégia de backup, restore e verificação para o banco Postgres do
ForwardService (Supabase, projeto `ysewoopjgdpvnkfhffgy`). Suplementa o
[SECURITY.md](SECURITY.md) — esta é a contrapartida operacional dos riscos
identificados na seção STRIDE.

## 1. Resumo executivo

| Item | Valor | Fonte |
| ---- | ----- | ----- |
| Backup automático | Diário, completo | Supabase managed (Pro plan) |
| Point-in-Time Recovery (PITR) | 7 dias (free) / 30 dias (Pro) | Supabase |
| Backup manual (pré-deploy) | `pg_dump` para storage Supabase | Operador |
| RPO (Recovery Point Objective) | ≤ 24h em desastre completo | Estratégia diária |
| RTO (Recovery Time Objective) | ≤ 2h para restauração full | Supabase dashboard |
| Frequência de teste de restore | Mensal, em projeto staging | Runbook abaixo |

## 2. O que está protegido

| Camada | Mecanismo | Quem opera |
| ------ | --------- | ---------- |
| Schema + dados | Supabase managed daily backup | Supabase (automático) |
| Migrations SQL | Git (`supabase/migrations/`) | Time, via PR |
| Seed data | Git (`supabase/seed/`) | Time, via PR |
| Edge Functions | Git (`supabase/functions/`) + deploy log | Time |
| Secrets | Fly.io secrets + GitHub Actions secrets | Operadores nomeados |
| Audit log | Replicado junto com backup do DB | Supabase |

O que **não** está protegido por esta estratégia (intencionalmente):

- Dados em `.env` local (são placeholders, source-of-truth está nos secrets).
- Logs de aplicação (efêmeros; Fly.io retém 7 dias por padrão).
- Métricas de instrumentação (não há ainda; ver risco R-05 em SECURITY.md).

## 3. Backup automático (Supabase)

Configurado por padrão pela Supabase para projetos Pro:

- Backup full diário entre 02:00–04:00 UTC.
- Retenção: 7 dias (plano free) ou 30 dias (Pro).
- Localização: AWS S3 em `sa-east-1` (mesma região do DB).
- Encryption: AES-256 at rest, TLS em trânsito.

Verificar status:

```text
Supabase Dashboard > Database > Backups
```

A página lista os backups disponíveis, timestamp e tamanho. Falhas geram
e-mail automático ao billing owner do projeto.

## 4. Backup manual (pré-deploy de risco)

Use antes de aplicar migrations destrutivas ou para snapshot de demo:

```bash
# Pré-requisitos: psql 16 + supabase CLI logado
export PGPASSWORD="$(supabase secrets get DB_PASSWORD --project-ref ysewoopjgdpvnkfhffgy)"

pg_dump \
    --host=db.ysewoopjgdpvnkfhffgy.supabase.co \
    --port=5432 \
    --username=postgres \
    --format=custom \
    --no-owner --no-privileges \
    --file="backup-$(date +%Y%m%d-%H%M%S).dump" \
    postgres

# Move para storage seguro (NUNCA commitar):
mv backup-*.dump ~/Documents/Ford/backups/
```

Verificar conteúdo do dump sem restaurar:

```bash
pg_restore --list backup-20260524-220000.dump | head -40
```

## 5. Restore — PITR (recomendado para incidentes recentes)

Para reverter para um ponto específico nos últimos 7/30 dias:

```text
Supabase Dashboard > Database > Backups > Point-in-Time Recovery
  1. Selecione o timestamp alvo (UTC).
  2. Confirme criação de um NOVO projeto (não sobrescreve o atual).
  3. Aguarde ~30–60 min (depende do tamanho do DB).
  4. Quando ready, validar dados no projeto restaurado.
  5. Migrar tráfego: atualizar SUPABASE_URL nos secrets do Fly + mobile.
```

Importante: PITR **cria um novo projeto** com novas chaves. Plano de troca de
endpoints deve ser comunicado a todos os clientes (mobile via OTA update,
N8N via dashboard). Estimar RTO total: 2h.

## 6. Restore — dump manual (incidentes antigos ou cross-environment)

Para restaurar um `.dump` em projeto vazio (ex: staging ou novo prod):

```bash
# 1) Crie um projeto Supabase novo, anote a connection string.
# 2) Aplique extensions e roles base (Supabase já faz no provisioning).
# 3) Restore:

pg_restore \
    --host=db.<NEW_PROJECT>.supabase.co \
    --port=5432 \
    --username=postgres \
    --dbname=postgres \
    --no-owner --no-privileges \
    --verbose \
    backup-20260524-220000.dump

# 4) Re-apply RLS policies (migration 010) se vieram desabilitadas:
supabase db push --linked --project-ref <NEW_PROJECT>

# 5) Re-schedule pg_cron jobs (migration 013 + scripts/lgpd-retention-cron.sql).

# 6) Sanity-check:
psql ... -c "SELECT COUNT(*) FROM customers WHERE full_name = '[ANONYMIZED]';"
psql ... -c "SELECT MAX(created_at) FROM audit_log;"
```

## 7. Teste mensal de restore (runbook)

Executar primeiro sábado de cada mês, registrado em `audit_log`:

1. Criar projeto Supabase descartável (`ford-restore-test-YYYYMM`).
2. Aplicar último dump manual.
3. Rodar suite de smoke tests (ver `scripts/smoke.sh`, planejado Sprint 2).
4. Comparar `COUNT(*)` por tabela vs prod; aceitável diff ≤ 24h (drift do dia).
5. Apagar projeto de teste (custo: ~$0 se executado em < 4h).
6. Registrar resultado em `forward-docs/runbooks/restore-tests/YYYY-MM.md`.

## 8. Plano de comunicação em incidentes

Se restore for necessário em prod:

| Severidade | SLA de notificação | Canal |
| ---------- | ------------------ | ----- |
| Catastrófico (dados corrompidos) | 15 min | Grupo WhatsApp + e-mail Ford |
| Alto (restore parcial) | 1 h | E-mail Ford + status page |
| Médio (rollback de migration) | 4 h | E-mail interno |

## 9. Limitações conhecidas (Sprint 1)

- **Sem teste automatizado de restore** (R-04 ampliado): runbook é manual. Sprint 2
  deve adicionar workflow `.github/workflows/monthly-restore-test.yml`.
- **Sem replicação cross-region**: Supabase free/Pro não oferece. Em
  catastrofe regional AWS São Paulo, indisponibilidade > 6h é aceita.
- **PITR não cobre Edge Functions deployadas**: estas dependem de re-deploy
  a partir do git (forward-infra/supabase/functions/).
- **Tamanho atual do DB**: ~50 MB. Estratégias acima são overkill para o
  tamanho atual, mas escalam para o estimado pós-Sprint 3 (≥ 5 GB).

## 10. Referências

- Supabase backups: <https://supabase.com/docs/guides/platform/backups>
- pg_dump reference: <https://www.postgresql.org/docs/16/app-pgdump.html>
- pg_cron: <https://github.com/citusdata/pg_cron>
- Continuity planning (ANPD/LGPD art. 50): boas práticas de segurança e governança.
