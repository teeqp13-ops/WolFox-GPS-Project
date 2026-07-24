<?php
// ===== WolFox Activation System - Config =====
error_reporting(E_ALL & ~E_DEPRECATED & ~E_NOTICE);

define('DB_PATH', __DIR__ . '/database.sqlite');
define('ADMIN_PASSWORD', 'Khalid1010');
define('HMAC_SECRET', 'wolfox_act_9f3k2m8x_change_me'); // غيّرها بمفتاح خاص بك

define('CODE_LENGTH', 8);
define('CODE_CHARS', 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'); // بدون أحرف/أرقام متشابهة

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
        // ترقية القاعدة القديمة (لو الجدول كان موجود قبل إضافة الأعمدة)
        $existing = array();
        foreach ($pdo->query("PRAGMA table_info(codes)") as $col) { $existing[] = $col['name']; }
        if (!in_array('device_model', $existing)) { $pdo->exec("ALTER TABLE codes ADD COLUMN device_model TEXT DEFAULT NULL"); }
        if (!in_array('expires_at', $existing))   { $pdo->exec("ALTER TABLE codes ADD COLUMN expires_at TEXT DEFAULT NULL"); }
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

function make_signature($code, $device_id, $timestamp, $status) {
    return hash_hmac('sha256', $code . '|' . $device_id . '|' . $timestamp . '|' . $status, HMAC_SECRET);
}
