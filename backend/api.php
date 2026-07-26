<?php
// ===== WolFox Activation System - Activation API =====
// POST fields: code, device_id, device_model (اختياري)
require __DIR__ . '/config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    json_out(array('success' => false, 'error' => 'invalid_method'), 405);
}

$code         = isset($_POST['code']) ? strtoupper(trim($_POST['code'])) : '';
$device_id    = isset($_POST['device_id']) ? trim($_POST['device_id']) : '';
$device_model = isset($_POST['device_model']) ? trim($_POST['device_model']) : null;
if ($code === '' || $device_id === '') {
    json_out(array('success' => false, 'error' => 'missing_params'), 400);
}

$pdo = db();
$stmt = $pdo->prepare("SELECT * FROM codes WHERE code = ?");
$stmt->execute(array($code));
$row = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$row) {
    json_out(array('success' => false, 'error' => 'invalid_code'), 404);
}

$now = date('Y-m-d H:i:s');

// تحقق من انتهاء الصلاحية (لو محدد) قبل أي شيء
if (!empty($row['expires_at']) && strtotime($row['expires_at']) < time()) {
    if ($row['status'] !== 'expired') {
        $pdo->prepare("UPDATE codes SET status='expired' WHERE code=?")->execute(array($code));
    }
    json_out(array('success' => false, 'error' => 'code_expired'), 403);
}

if ($row['status'] === 'unused') {
    // أول تفعيل - اربط الكود بالجهاز
    $upd = $pdo->prepare("UPDATE codes SET status='active', device_id=?, device_model=?, activated_at=? WHERE code=?");
    $upd->execute(array($device_id, $device_model, $now, $code));

    $timestamp = time();
    json_out(array(
        'success'   => true,
        'status'    => 'active',
        'code'      => $code,
        'device_id' => $device_id,
        'timestamp' => $timestamp,
    ));
} elseif ($row['status'] === 'active') {
    if ($row['device_id'] === $device_id) {
        // نفس الجهاز - تحقق ناجح (فتح التطبيق مرة ثانية)
        if ($device_model && $device_model !== $row['device_model']) {
            $pdo->prepare("UPDATE codes SET device_model=? WHERE code=?")->execute(array($device_model, $code));
        }
        $timestamp = time();
        json_out(array(
            'success'   => true,
            'status'    => 'active',
            'code'      => $code,
            'device_id' => $device_id,
            'timestamp' => $timestamp,
        ));
    } else {
        json_out(array('success' => false, 'error' => 'used_on_other_device'), 409);
    }
} else {
    // revoked / disabled
    json_out(array('success' => false, 'error' => 'code_revoked'), 403);
}
