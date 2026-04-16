-- Seed data for local development and demo.
-- Realistic synthetic data: Brazilian dealer names, valid CNPJs, plausible VINs.
-- Do not run in production.

BEGIN;

INSERT INTO dealers (code, name, cnpj, city, state, region, phone, active) VALUES
    ('F0001', 'Ford Morumbi Sao Paulo',     '12345678000101', 'Sao Paulo',      'SP', 'Sudeste',      '1133330001', TRUE),
    ('F0002', 'Ford Barra Rio',              '12345678000202', 'Rio de Janeiro', 'RJ', 'Sudeste',      '2133330002', TRUE),
    ('F0003', 'Ford Savassi BH',             '12345678000303', 'Belo Horizonte', 'MG', 'Sudeste',      '3133330003', TRUE),
    ('F0004', 'Ford Batel Curitiba',         '12345678000404', 'Curitiba',       'PR', 'Sul',          '4133330004', TRUE),
    ('F0005', 'Ford Moinhos Porto Alegre',   '12345678000505', 'Porto Alegre',   'RS', 'Sul',          '5133330005', TRUE),
    ('F0006', 'Ford Boa Viagem Recife',      '12345678000606', 'Recife',         'PE', 'Nordeste',     '8133330006', TRUE),
    ('F0007', 'Ford Iguatemi Fortaleza',     '12345678000707', 'Fortaleza',      'CE', 'Nordeste',     '8533330007', TRUE),
    ('F0008', 'Ford Umarizal Belem',         '12345678000808', 'Belem',          'PA', 'Norte',        '9133330008', TRUE),
    ('F0009', 'Ford Asa Sul Brasilia',       '12345678000909', 'Brasilia',       'DF', 'Centro-Oeste', '6133330009', TRUE),
    ('F0010', 'Ford Campinas',               '12345678001010', 'Campinas',       'SP', 'Sudeste',      '1933330010', TRUE);

INSERT INTO customers (id, full_name, cpf, birth_date, email, phone, city, state, opt_in_whatsapp, lgpd_consent_at) VALUES
    ('11111111-1111-1111-1111-111111111001', 'Joao da Silva',       '11122233301', '1985-03-14', 'joao@example.com',    '11999990001', 'Sao Paulo',      'SP', TRUE,  NOW()),
    ('11111111-1111-1111-1111-111111111002', 'Maria Oliveira',      '11122233302', '1990-07-22', 'maria@example.com',   '11999990002', 'Sao Paulo',      'SP', TRUE,  NOW()),
    ('11111111-1111-1111-1111-111111111003', 'Carlos Souza',        '11122233303', '1978-11-05', 'carlos@example.com',  '21999990003', 'Rio de Janeiro', 'RJ', FALSE, NOW()),
    ('11111111-1111-1111-1111-111111111004', 'Fernanda Alves',      '11122233304', '1995-02-19', 'fernanda@example.com','31999990004', 'Belo Horizonte', 'MG', TRUE,  NOW()),
    ('11111111-1111-1111-1111-111111111005', 'Rafael Pereira',      '11122233305', '1982-09-30', 'rafael@example.com',  '41999990005', 'Curitiba',       'PR', TRUE,  NOW());

INSERT INTO vehicles (vin, customer_id, current_dealer_id, model, year, version, color, discontinued, purchase_date, last_service_at) VALUES
    ('9BFZZZ5SZJB000001', '11111111-1111-1111-1111-111111111001', (SELECT id FROM dealers WHERE code = 'F0001'), 'Ka',        2018, 'SE 1.0',  'Prata',  TRUE,  '2018-05-10', '2022-06-10 14:30:00-03'),
    ('9BFZZZ5SZJB000002', '11111111-1111-1111-1111-111111111002', (SELECT id FROM dealers WHERE code = 'F0001'), 'EcoSport',  2019, 'Titanium','Branco', TRUE,  '2019-08-20', '2023-09-15 10:00:00-03'),
    ('9BFZZZ5SZJB000003', '11111111-1111-1111-1111-111111111003', (SELECT id FROM dealers WHERE code = 'F0002'), 'Fiesta',    2017, 'Sedan',   'Preto',  TRUE,  '2017-11-11', NULL),
    ('9BFZZZ5SZJB000004', '11111111-1111-1111-1111-111111111004', (SELECT id FROM dealers WHERE code = 'F0003'), 'Ranger',    2023, 'Limited', 'Azul',   FALSE, '2023-03-01', '2024-09-12 11:45:00-03'),
    ('9BFZZZ5SZJB000005', '11111111-1111-1111-1111-111111111005', (SELECT id FROM dealers WHERE code = 'F0004'), 'Territory', 2022, 'Titanium','Cinza',  FALSE, '2022-12-15', '2024-12-20 09:30:00-03');

INSERT INTO service_orders (vin, dealer_id, order_type, status, scheduled_at, completed_at, mileage_km, total_amount_brl) VALUES
    ('9BFZZZ5SZJB000001', (SELECT id FROM dealers WHERE code = 'F0001'), 'scheduled_maintenance', 'completed', '2022-06-10 14:00:00-03', '2022-06-10 14:30:00-03',  45000, 850.00),
    ('9BFZZZ5SZJB000002', (SELECT id FROM dealers WHERE code = 'F0001'), 'scheduled_maintenance', 'completed', '2023-09-15 09:30:00-03', '2023-09-15 10:00:00-03',  38000, 920.00),
    ('9BFZZZ5SZJB000004', (SELECT id FROM dealers WHERE code = 'F0003'), 'scheduled_maintenance', 'completed', '2024-09-12 11:15:00-03', '2024-09-12 11:45:00-03',  18000, 1250.00),
    ('9BFZZZ5SZJB000005', (SELECT id FROM dealers WHERE code = 'F0004'), 'scheduled_maintenance', 'completed', '2024-12-20 09:00:00-03', '2024-12-20 09:30:00-03',  22000, 1100.00);

INSERT INTO churn_scores (customer_id, vin, model_version, segment, churn_probability, confidence, is_current) VALUES
    ('11111111-1111-1111-1111-111111111001', '9BFZZZ5SZJB000001', 'v0.1', 'esquecido', 0.78, 0.82, TRUE),
    ('11111111-1111-1111-1111-111111111002', '9BFZZZ5SZJB000002', 'v0.1', 'fiel',      0.15, 0.91, TRUE),
    ('11111111-1111-1111-1111-111111111003', '9BFZZZ5SZJB000003', 'v0.1', 'abandono',  0.95, 0.88, TRUE),
    ('11111111-1111-1111-1111-111111111004', '9BFZZZ5SZJB000004', 'v0.1', 'fiel',      0.12, 0.94, TRUE),
    ('11111111-1111-1111-1111-111111111005', '9BFZZZ5SZJB000005', 'v0.1', 'economico', 0.55, 0.79, TRUE);

INSERT INTO leads (customer_id, vin, dealer_id, score_id, priority, status, reason, expected_value_brl)
SELECT
    cs.customer_id,
    cs.vin,
    v.current_dealer_id,
    cs.id,
    CASE
        WHEN cs.churn_probability >= 0.9 THEN 'critical'::lead_priority
        WHEN cs.churn_probability >= 0.7 THEN 'high'::lead_priority
        WHEN cs.churn_probability >= 0.4 THEN 'medium'::lead_priority
        ELSE 'low'::lead_priority
    END,
    'new',
    'Auto-generated from churn score v0.1',
    1200.00
FROM churn_scores cs
JOIN vehicles v ON v.vin = cs.vin
WHERE cs.is_current AND cs.churn_probability >= 0.4;

COMMIT;
