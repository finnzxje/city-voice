-- V12: Seed initial incident categories

INSERT INTO categories (name, slug, icon_key, is_active) VALUES
    ('Ổ gà / Mặt đường hư hỏng', 'pothole',              'road-warning',      TRUE),
    ('Đèn đường hỏng',            'broken-streetlight',   'lamp-off',          TRUE),
    ('Ngập lụt / Thoát nước',     'flooding',             'cloud-rain',        TRUE),
    ('Biển báo hư hỏng',          'damaged-road-sign',    'triangle-alert',    TRUE),
    ('Đổ rác trái phép',          'illegal-dumping',      'trash-x',           TRUE),
    ('Cây xanh nguy hiểm',        'hazardous-tree',       'tree',              TRUE),
    ('Vỉa hè / Lề đường hư hỏng', 'damaged-pavement',    'footprints',        TRUE),
    ('Khác',                       'other',               'circle-help',       TRUE);
