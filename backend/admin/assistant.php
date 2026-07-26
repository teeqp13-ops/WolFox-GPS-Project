<?php
session_start();
require __DIR__ . '/../config.php';

if (empty($_SESSION['wf_admin'])) {
    header('Location: index.php');
    exit;
}

function wf_response_text(array $response) {
    if (!empty($response['output_text']) && is_string($response['output_text'])) {
        return $response['output_text'];
    }
    $parts = array();
    foreach (($response['output'] ?? array()) as $item) {
        foreach (($item['content'] ?? array()) as $content) {
            if (($content['type'] ?? '') === 'output_text' && isset($content['text'])) {
                $parts[] = $content['text'];
            }
        }
    }
    return trim(implode("\n", $parts));
}

$result = '';
$error = '';
$input = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = trim(isset($_POST['input']) ? $_POST['input'] : '');

    if (OPENAI_API_KEY === '') {
        $error = 'لم يتم ضبط OPENAI_API_KEY في بيئة الخادم.';
    } elseif ($input === '') {
        $error = 'أدخل نصًا للتحليل.';
    } elseif (strlen($input) > 12000) {
        $error = 'النص طويل جدًا؛ الحد الأقصى 12000 بايت.';
    } elseif (!function_exists('curl_init')) {
        $error = 'امتداد cURL غير متاح على الخادم.';
    } else {
        $instructions = 'أنت مساعد مراجعة لمشروع WolFox GPS. حلّل النصوص البرمجية والسجلات فقط. '
            . 'لا تطلب أو تعرض مفاتيح أو كلمات مرور أو بيانات شخصية. '
            . 'اذكر التعارضات والمخاطر وخطوات تحقق قابلة للتنفيذ بإيجاز وبالعربية. '
            . 'لا تقترح تجاوز حماية خدمات أو تلاعبًا بأنظمة خارجية.';

        $payload = array(
            'model' => OPENAI_MODEL,
            'instructions' => $instructions,
            'input' => array(array(
                'role' => 'user',
                'content' => array(array('type' => 'input_text', 'text' => $input))
            ))
        );

        $ch = curl_init('https://api.openai.com/v1/responses');
        curl_setopt_array($ch, array(
            CURLOPT_POST => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 30,
            CURLOPT_HTTPHEADER => array(
                'Authorization: Bearer ' . OPENAI_API_KEY,
                'Content-Type: application/json'
            ),
            CURLOPT_POSTFIELDS => json_encode($payload, JSON_UNESCAPED_UNICODE)
        ));

        $raw = curl_exec($ch);
        $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlError = curl_error($ch);
        curl_close($ch);

        $decoded = is_string($raw) ? json_decode($raw, true) : null;
        if ($raw === false || $curlError !== '') {
            $error = 'تعذر الاتصال بخدمة المساعد.';
        } elseif ($status < 200 || $status >= 300) {
            $error = 'فشل طلب المساعد (' . $status . ').';
        } elseif (!is_array($decoded)) {
            $error = 'استجابة غير صالحة من المساعد.';
        } else {
            $result = wf_response_text($decoded);
            if ($result === '') {
                $error = 'لم يُرجع المساعد نصًا قابلًا للعرض.';
            }
        }
    }
}
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>WolFox — مساعد المشروع</title>
<style>
body{margin:0;background:#070b18;color:#fff;font-family:Arial,sans-serif}
main{max-width:840px;margin:0 auto;padding:28px 18px}.bar{display:flex;justify-content:space-between;align-items:center}
a{color:#e0bc4a;text-decoration:none}.card{background:#0e142b;border:1px solid rgba(201,162,39,.2);border-radius:14px;padding:20px;margin-top:18px}
textarea{width:100%;min-height:220px;background:#070b18;color:#fff;border:1px solid #26314d;border-radius:10px;padding:12px;box-sizing:border-box;line-height:1.6}
button{margin-top:12px;background:#c9a227;color:#070b18;border:0;border-radius:9px;padding:11px 18px;font-weight:bold;cursor:pointer}
.notice{color:#9aa3b8;font-size:13px;line-height:1.7}.error{color:#ff8796}.result{white-space:pre-wrap;line-height:1.8}
</style>
</head>
<body><main>
<div class="bar"><h1>مساعد مراجعة المشروع</h1><a href="dashboard.php">العودة للوحة التحكم</a></div>
<div class="card"><p class="notice">أرسل نصوص الكود أو سجل البناء فقط. لا تضع مفاتيح، كلمات مرور، أو ملفات ثنائية. لا يُخزّن النص في قاعدة البيانات.</p>
<form method="post"><textarea name="input" placeholder="ألصق سجل البناء أو مقطع الكود هنا…"><?php echo htmlspecialchars($input, ENT_QUOTES, 'UTF-8'); ?></textarea><button type="submit">تحليل النص</button></form>
<?php if ($error): ?><p class="error"><?php echo htmlspecialchars($error, ENT_QUOTES, 'UTF-8'); ?></p><?php endif; ?>
<?php if ($result): ?><div class="card result"><?php echo htmlspecialchars($result, ENT_QUOTES, 'UTF-8'); ?></div><?php endif; ?>
</div></main></body></html>
