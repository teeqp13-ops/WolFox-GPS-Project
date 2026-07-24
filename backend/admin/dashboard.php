<?php
session_start();
require __DIR__ . '/../config.php';
if (empty($_SESSION['wf_admin'])) { header('Location: index.php'); exit; }

$pdo = db();
$msg = '';

// ---- إجراءات ----
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = isset($_POST['action']) ? $_POST['action'] : '';

    if ($action === 'generate') {
        $count = max(1, min(100, intval($_POST['count'])));
        $note = trim($_POST['note']);
        $expiry_days = isset($_POST['expiry_days']) ? intval($_POST['expiry_days']) : 0;
        $now = date('Y-m-d H:i:s');
        $expires_at = $expiry_days > 0 ? date('Y-m-d H:i:s', strtotime("+$expiry_days days")) : null;
        $ins = $pdo->prepare("INSERT INTO codes (code, status, note, created_at, expires_at) VALUES (?, 'unused', ?, ?, ?)");
        $made = 0;
        while ($made < $count) {
            $c = generate_code();
            $chk = $pdo->prepare("SELECT 1 FROM codes WHERE code=?");
            $chk->execute(array($c));
            if ($chk->fetch()) continue;
            $ins->execute(array($c, $note !== '' ? $note : null, $now, $expires_at));
            $made++;
        }
        $msg = "تم توليد $made كود بنجاح";
    } elseif ($action === 'revoke') {
        $pdo->prepare("UPDATE codes SET status='revoked' WHERE code=?")->execute(array($_POST['code']));
        $msg = "تم إيقاف الكود";
    } elseif ($action === 'reset_device') {
        $pdo->prepare("UPDATE codes SET status='unused', device_id=NULL, activated_at=NULL WHERE code=?")->execute(array($_POST['code']));
        $msg = "تم فك ربط الجهاز - الكود جاهز للاستخدام من جديد";
    } elseif ($action === 'delete') {
        $pdo->prepare("DELETE FROM codes WHERE code=?")->execute(array($_POST['code']));
        $msg = "تم حذف الكود";
    } elseif ($action === 'logout') {
        session_destroy();
        header('Location: index.php');
        exit;
    }
}

// ---- تحديث تلقائي لحالة الأكواد المنتهية ----
$pdo->exec("UPDATE codes SET status='expired' WHERE expires_at IS NOT NULL AND expires_at < datetime('now','localtime') AND status IN ('unused','active')");

// ---- فلترة ----
$filter = isset($_GET['f']) ? $_GET['f'] : 'all';
$sql = "SELECT * FROM codes";
if ($filter === 'unused') $sql .= " WHERE status='unused'";
elseif ($filter === 'active') $sql .= " WHERE status='active'";
elseif ($filter === 'revoked') $sql .= " WHERE status='revoked'";
elseif ($filter === 'expired') $sql .= " WHERE status='expired'";
$sql .= " ORDER BY created_at DESC";
$codes = $pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC);

$total = $pdo->query("SELECT COUNT(*) c FROM codes")->fetch()['c'];
$unused = $pdo->query("SELECT COUNT(*) c FROM codes WHERE status='unused'")->fetch()['c'];
$active = $pdo->query("SELECT COUNT(*) c FROM codes WHERE status='active'")->fetch()['c'];
$revoked = $pdo->query("SELECT COUNT(*) c FROM codes WHERE status='revoked'")->fetch()['c'];
$expired = $pdo->query("SELECT COUNT(*) c FROM codes WHERE status='expired'")->fetch()['c'];
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>WolFox Activation - لوحة التحكم</title>
<link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<style>
  * { box-sizing:border-box; margin:0; padding:0; font-family:'Cairo',sans-serif; }
  body { background:#070b18; color:#fff; min-height:100vh; }
  .topbar {
    display:flex; align-items:center; justify-content:space-between;
    padding:18px 28px; border-bottom:1px solid rgba(201,162,39,0.2); background:#0e142b;
  }
  .brand { display:flex; align-items:center; gap:10px; font-weight:800; font-size:18px; }
  .brand i { color:#c9a227; }
  .brand span { color:#c9a227; }
  .logout-btn { background:transparent; border:1px solid rgba(255,255,255,.15); color:#9aa3b8; padding:8px 14px; border-radius:8px; cursor:pointer; font-family:'Cairo'; }
  .logout-btn:hover { border-color:#c9a227; color:#c9a227; }
  .container { max-width:1100px; margin:0 auto; padding:28px 20px; }
  .stats { display:grid; grid-template-columns:repeat(5,1fr); gap:14px; margin-bottom:24px; }
  .stat { background:#0e142b; border:1px solid rgba(201,162,39,0.15); border-radius:12px; padding:16px; text-align:center; }
  .stat .num { font-size:26px; font-weight:800; color:#c9a227; }
  .stat .lbl { font-size:12px; color:#9aa3b8; margin-top:4px; }
  .panel { background:#0e142b; border:1px solid rgba(201,162,39,0.15); border-radius:14px; padding:22px; margin-bottom:20px; }
  .panel h3 { margin-bottom:14px; font-size:15px; color:#e0bc4a; display:flex; align-items:center; gap:8px; }
  .gen-form { display:flex; gap:10px; flex-wrap:wrap; align-items:end; }
  .gen-form .field { display:flex; flex-direction:column; gap:6px; }
  .gen-form label { font-size:12px; color:#9aa3b8; }
  .gen-form input { padding:10px 12px; border-radius:8px; border:1px solid rgba(255,255,255,0.12); background:#070b18; color:#fff; font-family:'Cairo'; }
  .btn { padding:10px 18px; border:none; border-radius:8px; cursor:pointer; font-weight:700; font-family:'Cairo'; background:linear-gradient(135deg,#c9a227,#e0bc4a); color:#070b18; }
  .btn:hover { opacity:.9; }
  .msg { background:rgba(40,167,69,.15); color:#5be08a; padding:10px 14px; border-radius:8px; margin-bottom:16px; font-size:14px; }
  .tabs { display:flex; gap:8px; margin-bottom:16px; }
  .tabs a { padding:8px 14px; border-radius:8px; text-decoration:none; color:#9aa3b8; font-size:13px; border:1px solid rgba(255,255,255,.08); }
  .tabs a.active { background:rgba(201,162,39,.15); color:#c9a227; border-color:#c9a227; }
  table { width:100%; border-collapse:collapse; }
  th, td { padding:10px 12px; text-align:right; font-size:13px; border-bottom:1px solid rgba(255,255,255,.06); }
  th { color:#9aa3b8; font-weight:600; }
  .code-cell { font-family:monospace; letter-spacing:1px; color:#e0bc4a; font-weight:700; }
  .badge { padding:3px 10px; border-radius:20px; font-size:11px; font-weight:700; }
  .badge.unused { background:rgba(154,163,184,.15); color:#9aa3b8; }
  .badge.active { background:rgba(40,167,69,.15); color:#5be08a; }
  .badge.revoked { background:rgba(220,53,69,.15); color:#ff6b7d; }
  .badge.expired { background:rgba(154,163,184,.12); color:#6b7488; }
  .actions { display:flex; gap:6px; }
  .actions button { background:transparent; border:1px solid rgba(255,255,255,.12); color:#9aa3b8; padding:5px 9px; border-radius:6px; cursor:pointer; font-size:12px; }
  .actions button:hover { color:#c9a227; border-color:#c9a227; }
  .actions button.danger:hover { color:#ff6b7d; border-color:#ff6b7d; }
  .device { font-size:11px; color:#6b7488; word-break:break-all; }

  /* ===== نافذة معلومات الكود ===== */
  .modal-overlay {
    display:none; position:fixed; inset:0; background:rgba(0,0,0,.6);
    align-items:center; justify-content:center; z-index:100; padding:20px;
  }
  .modal-overlay.show { display:flex; }
  .modal-box {
    background:#0e142b; border:1px solid rgba(201,162,39,.25); border-radius:16px;
    padding:26px; width:100%; max-width:380px; box-shadow:0 30px 60px rgba(0,0,0,.5);
  }
  .modal-box h3 { color:#e0bc4a; font-size:16px; margin-bottom:18px; display:flex; align-items:center; gap:8px; }
  .info-row { display:flex; justify-content:space-between; align-items:center; padding:10px 0; border-bottom:1px solid rgba(255,255,255,.06); font-size:13px; gap:12px; }
  .info-row:last-of-type { border-bottom:none; }
  .info-row .lbl2 { color:#9aa3b8; white-space:nowrap; }
  .info-row .val { color:#fff; font-weight:700; text-align:left; word-break:break-all; direction:ltr; }
  .info-row .val.code-val { font-family:monospace; color:#e0bc4a; letter-spacing:1px; }
  .modal-close { width:100%; margin-top:18px; padding:11px; border:1px solid rgba(255,255,255,.12); background:transparent; color:#9aa3b8; border-radius:9px; cursor:pointer; font-family:'Cairo'; }
  .modal-close:hover { border-color:#c9a227; color:#c9a227; }
</style>
</head>
<body>
<div class="topbar">
  <div class="brand"><i class="fa-solid fa-shield-halved"></i> Wol<span>Fox</span> Activation</div>
  <form method="POST"><input type="hidden" name="action" value="logout">
    <button class="logout-btn" type="submit"><i class="fa-solid fa-right-from-bracket"></i> خروج</button>
  </form>
</div>

<div class="container">
  <?php if ($msg): ?><div class="msg"><i class="fa-solid fa-circle-check"></i> <?php echo htmlspecialchars($msg); ?></div><?php endif; ?>

  <div class="stats">
    <div class="stat"><div class="num"><?php echo $total; ?></div><div class="lbl">إجمالي الأكواد</div></div>
    <div class="stat"><div class="num"><?php echo $unused; ?></div><div class="lbl">غير مستخدمة</div></div>
    <div class="stat"><div class="num"><?php echo $active; ?></div><div class="lbl">مفعّلة</div></div>
    <div class="stat"><div class="num"><?php echo $revoked; ?></div><div class="lbl">موقوفة</div></div>
    <div class="stat"><div class="num"><?php echo $expired; ?></div><div class="lbl">منتهية</div></div>
  </div>

  <div class="panel">
    <h3><i class="fa-solid fa-plus"></i> توليد أكواد جديدة</h3>
    <form class="gen-form" method="POST">
      <input type="hidden" name="action" value="generate">
      <div class="field"><label>العدد</label><input type="number" name="count" value="10" min="1" max="100"></div>
      <div class="field"><label>ملاحظة (اختياري)</label><input type="text" name="note" placeholder="مثال: دفعة يوليو"></div>
      <div class="field"><label>مدة الصلاحية (أيام، 0 = بدون انتهاء)</label><input type="number" name="expiry_days" value="0" min="0"></div>
      <button class="btn" type="submit"><i class="fa-solid fa-key"></i> توليد</button>
    </form>
  </div>

  <div class="panel">
    <h3><i class="fa-solid fa-list"></i> الأكواد</h3>
    <div class="tabs">
      <a href="?f=all" class="<?php echo $filter==='all'?'active':''; ?>">الكل</a>
      <a href="?f=unused" class="<?php echo $filter==='unused'?'active':''; ?>">غير مستخدمة</a>
      <a href="?f=active" class="<?php echo $filter==='active'?'active':''; ?>">مفعّلة</a>
      <a href="?f=revoked" class="<?php echo $filter==='revoked'?'active':''; ?>">موقوفة</a>
      <a href="?f=expired" class="<?php echo $filter==='expired'?'active':''; ?>">منتهية</a>
    </div>
    <table>
      <thead><tr><th>الكود</th><th>الحالة</th><th>الجهاز</th><th>تاريخ الإنشاء</th><th>تاريخ التفعيل</th><th>إجراءات</th></tr></thead>
      <tbody>
      <?php foreach ($codes as $c): ?>
        <tr>
          <td class="code-cell"><?php echo htmlspecialchars($c['code']); ?></td>
          <td><span class="badge <?php echo $c['status']; ?>"><?php
            $labels = array('unused'=>'غير مستخدم','active'=>'مفعّل','revoked'=>'موقوف','expired'=>'منتهي');
            echo isset($labels[$c['status']]) ? $labels[$c['status']] : $c['status'];
          ?></span></td>
          <td class="device"><?php echo $c['device_id'] ? htmlspecialchars(substr($c['device_id'],0,18)).'…' : '—'; ?></td>
          <td><?php echo htmlspecialchars($c['created_at']); ?></td>
          <td><?php echo $c['activated_at'] ? htmlspecialchars($c['activated_at']) : '—'; ?></td>
          <td class="actions">
            <button type="button" title="عرض المعلومات" onclick='wfShowInfo(<?php echo json_encode(array(
                "code" => $c["code"],
                "device_id" => $c["device_id"],
                "device_model" => $c["device_model"],
                "activated_at" => $c["activated_at"],
                "expires_at" => $c["expires_at"],
                "status" => $c["status"]
              ), JSON_UNESCAPED_UNICODE); ?>)'><i class="fa-solid fa-circle-info"></i></button>
            <?php if ($c['status'] === 'active'): ?>
              <form method="POST" style="display:inline"><input type="hidden" name="action" value="reset_device"><input type="hidden" name="code" value="<?php echo htmlspecialchars($c['code']); ?>">
                <button type="submit" title="فك ربط الجهاز"><i class="fa-solid fa-unlink"></i></button></form>
            <?php endif; ?>
            <?php if ($c['status'] !== 'revoked'): ?>
              <form method="POST" style="display:inline"><input type="hidden" name="action" value="revoke"><input type="hidden" name="code" value="<?php echo htmlspecialchars($c['code']); ?>">
                <button type="submit" title="إيقاف الكود"><i class="fa-solid fa-ban"></i></button></form>
            <?php endif; ?>
            <form method="POST" style="display:inline" onsubmit="return confirm('حذف الكود نهائياً؟');"><input type="hidden" name="action" value="delete"><input type="hidden" name="code" value="<?php echo htmlspecialchars($c['code']); ?>">
              <button type="submit" class="danger" title="حذف"><i class="fa-solid fa-trash"></i></button></form>
          </td>
        </tr>
      <?php endforeach; ?>
      <?php if (empty($codes)): ?>
        <tr><td colspan="6" style="text-align:center; color:#6b7488; padding:24px;">لا توجد أكواد</td></tr>
      <?php endif; ?>
      </tbody>
    </table>
  </div>
</div>

<!-- نافذة عرض معلومات الكود -->
<div class="modal-overlay" id="infoModal">
  <div class="modal-box">
    <h3><i class="fa-solid fa-circle-info"></i> معلومات الكود</h3>
    <div class="info-row"><span class="lbl2">الكود</span><span class="val code-val" id="infoCode">—</span></div>
    <div class="info-row"><span class="lbl2">معلومات الجهاز</span><span class="val" id="infoDeviceModel">—</span></div>
    <div class="info-row"><span class="lbl2">UUID</span><span class="val" id="infoUUID">—</span></div>
    <div class="info-row"><span class="lbl2">تاريخ الاستخدام</span><span class="val" id="infoActivated">—</span></div>
    <div class="info-row"><span class="lbl2">تاريخ الانتهاء</span><span class="val" id="infoExpires">—</span></div>
    <button class="modal-close" onclick="wfCloseInfo()">إغلاق</button>
  </div>
</div>

<script>
function wfShowInfo(data) {
  document.getElementById('infoCode').textContent = data.code || '—';
  document.getElementById('infoDeviceModel').textContent = data.device_model || '—';
  document.getElementById('infoUUID').textContent = data.device_id || '—';
  document.getElementById('infoActivated').textContent = data.activated_at || '—';
  document.getElementById('infoExpires').textContent = data.expires_at ? data.expires_at : 'بدون انتهاء';
  document.getElementById('infoModal').classList.add('show');
}
function wfCloseInfo() {
  document.getElementById('infoModal').classList.remove('show');
}
document.getElementById('infoModal').addEventListener('click', function(e){
  if (e.target === this) wfCloseInfo();
});
</script>
</body>
</html>
