<?php
// ===== WolFox Activation System - Config =====
// ضع القيم الحساسة في بيئة الاستضافة فقط، ولا تحفظها في Git.
error_reporting(E_ALL & ~E_DEPRECATED & ~E_NOTICE);

define('DB_PATH', __DIR__ . '/database.sqlite');
define('ADMIN_PASSWORD', getenv('WOLFOX_ADMIN_PASSWORD') ?: '');
define('OPENAI_API_KEY', getenv('OPENAI_API_KEY') ?: '');
define('OPENAI_MODEL', getenv('OPENAI_MODEL') ?: 'gpt-5.6-sol');

define('CODE_LENGTH', 8);
define('CODE_CHARS', 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789');

function db() {
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO('sqlite:' . DB_PATH);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->exec("CREATE TABLE IF NOT EXISTS codes (
            code TEXT PRIMARY KEY,
            status TEXT NOT NULL DEFAULT 'unused',
            device_id TEXT DEFAULT NULL,
            device_model TEXT DEFAULT NULL,
            note TEXT DEFAULT NULL,
            created_at TEXT NOT NULL,
            activated_at TEXT DEFAULT NULL,
            expires_at TEXT DEFAULT NULL
        )");
        $existing = array();
        foreach ($pdo->query("PRAGMA table_info(codes)") as $col) { $existing[] = $col['name']; }
        if (!in_array('device_model', $existing)) { $pdo->exec("ALTER TABLE codes ADD COLUMN device_model TEXT DEFAULT NULL"); }
        if (!in_array('expires_at', $existing)) { $pdo->exec("ALTER TABLE codes ADD COLUMN expires_at TEXT DEFAULT NULL"); }
        $pdo->exec("CREATE TABLE IF NOT EXISTS admin_sessions (
            token TEXT PRIMARY KEY,
            created_at TEXT NOT NULL
        )");
    }
    return $pdo;
}

function generate_code() {
    $chars = CODE_CHARS;
    $code = '';
    for ($i = 0; $i < CODE_LENGTH; $i++) {
        $code .= $chars[random_int(0, strlen($chars) - 1)];
    }
    return $code;
}

function json_out($data, $http_code = 200) {
    http_response_code($http_code);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}
