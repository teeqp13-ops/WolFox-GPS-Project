<?php
session_start();
require __DIR__ . '/../config.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $pass = isset($_POST['password']) && is_string($_POST['password']) ? $_POST['password'] : '';
    if (ADMIN_PASSWORD !== '' && is_string($pass) && hash_equals(ADMIN_PASSWORD, $pass)) {
        $_SESSION['wf_admin'] = true;
        header('Location: dashboard.php');
        exit;
    } else {
        $error = 'كلمة المرور غير صحيحة';
    }
}
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>WolFox Activation - تسجيل الدخول</title>
<link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<style>
  * { box-sizing: border-box; margin:0; padding:0; font-family:'Cairo',sans-serif; }
  body {
    background: #070b18;
    min-height: 100vh;
    display:flex; align-items:center; justify-content:center;
    background-image: radial-gradient(circle at 50% 0%, rgba(201,162,39,0.08), transparent 60%);
  }
  .card {
    background: #0e142b;
    border: 1px solid rgba(201,162,39,0.25);
    border-radius: 16px;
    padding: 40px 32px;
    width: 100%;
    max-width: 360px;
    box-shadow: 0 20px 50px rgba(0,0,0,0.5);
  }
  .logo { text-align:center; margin-bottom: 24px; }
  .logo i { font-size: 42px; color:#c9a227; }
  .logo h1 { color:#fff; font-size:20px; margin-top:10px; font-weight:800; }
  .logo span { color:#c9a227; }
  label { color:#9aa3b8; font-size:13px; display:block; margin-bottom:6px; }
  input {
    width:100%; padding:12px 14px; border-radius:10px; border:1px solid rgba(255,255,255,0.1);
    background:#070b18; color:#fff; font-family:'Cairo'; margin-bottom:16px; outline:none;
  }
  input:focus { border-color:#c9a227; }
  button {
    width:100%; padding:13px; border:none; border-radius:10px; cursor:pointer;
    background: linear-gradient(135deg,#c9a227,#e0bc4a); color:#070b18; font-weight:800; font-size:15px;
    transition:.2s;
  }
  button:hover { opacity:.9; }
  .error { background:rgba(220,53,69,.15); color:#ff6b7d; padding:10px; border-radius:8px; font-size:13px; margin-bottom:16px; text-align:center; }
</style>
</head>
<body>
  <div class="card">
    <div class="logo">
      <i class="fa-solid fa-shield-halved"></i>
      <h1>Wol<span>Fox</span> Activation</h1>
    </div>
    <?php if (!empty($error)): ?><div class="error"><?php echo htmlspecialchars($error); ?></div><?php endif; ?>
    <form method="POST">
      <label>كلمة المرور</label>
      <input type="password" name="password" required autofocus>
      <button type="submit"><i class="fa-solid fa-right-to-bracket"></i> دخول</button>
    </form>
  </div>
</body>
</html>
