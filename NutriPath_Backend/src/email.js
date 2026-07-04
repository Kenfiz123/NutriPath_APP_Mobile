import nodemailer from "nodemailer";

function envTimeoutMs(name, fallback) {
  const value = Number(process.env[name]);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

function printOtpFallback(email, otpCode, label = "EMAIL OTP FALLBACK") {
  console.log(`\n==============================================`);
  if (email) console.log(`[${label}] Dang ky thanh vien moi: ${email}`);
  console.log(`[${label}] Ma xac thuc OTP cua ban la: ${otpCode}`);
  console.log(`==============================================\n`);
}

function extractEmail(value) {
  const raw = String(value || "").trim();
  const match = raw.match(/<([^>]+)>/);
  return (match?.[1] || raw).trim();
}

function extractName(value, fallback) {
  const raw = String(value || "").trim();
  const match = raw.match(/^(.+?)\s*<[^>]+>$/);
  return (match?.[1] || fallback || "NutriPath").replace(/^["']|["']$/g, "").trim();
}

function buildOtpEmail(otpCode) {
  const subject = "Ma xac thuc OTP kich hoat tai khoan NutriPath";
  const htmlContent = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
      <h2 style="color: #4CAF50; text-align: center;">Xac thuc tai khoan NutriPath</h2>
      <p>Chao ban,</p>
      <p>Cam on ban da dang ky thanh vien cua <strong>NutriPath</strong>. De hoan tat kich hoat tai khoan, vui long nhap ma xac thuc OTP duoi day vao ung dung:</p>
      <div style="background-color: #f9f9f9; padding: 15px; text-align: center; border-radius: 4px; margin: 20px 0;">
        <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #333;">${otpCode}</span>
      </div>
      <p style="color: #666; font-size: 13px;">Ma OTP nay co hieu luc trong vong <strong>10 phut</strong>. Vui long khong chia se ma nay voi bat ky ai.</p>
      <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;" />
      <p style="color: #999; font-size: 11px; text-align: center;">Day la email tu dong tu he thong NutriPath, vui long khong tra loi email nay.</p>
    </div>
  `;
  return { subject, htmlContent };
}

async function sendBrevoEmail({ email, subject, htmlContent, otpCode }) {
  const apiKey = String(process.env.BREVO_API_KEY || "").trim();
  const endpoint = String(process.env.BREVO_API_URL || "https://api.brevo.com/v3/smtp/email").trim();
  const fallbackFrom = process.env.SMTP_FROM || process.env.SMTP_USER || "";
  const fromEmail = String(process.env.BREVO_FROM_EMAIL || extractEmail(fallbackFrom)).trim();
  const fromName = String(process.env.BREVO_FROM_NAME || extractName(fallbackFrom, "NutriPath")).trim();
  const sendTimeout = envTimeoutMs("BREVO_SEND_TIMEOUT_MS", 9000);

  if (!apiKey || !fromEmail) {
    console.log("[BREVO WARNING] BREVO_API_KEY hoac BREVO_FROM_EMAIL chua duoc cau hinh.");
    printOtpFallback(email, otpCode, "EMAIL OTP");
    return { success: false, mode: "console" };
  }

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), sendTimeout);
  try {
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        accept: "application/json",
        "api-key": apiKey,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        sender: { email: fromEmail, name: fromName },
        to: [{ email }],
        subject,
        htmlContent,
      }),
      signal: controller.signal,
    });
    const text = await response.text();
    const body = text ? JSON.parse(text) : {};

    if (!response.ok) {
      const message = body.message || body.error || text || response.statusText;
      throw new Error(`Brevo API ${response.status}: ${message}`);
    }

    console.log(`[BREVO SUCCESS] Da gui email OTP toi ${email}. MessageId: ${body.messageId || "n/a"}`);
    return { success: true, mode: "brevo", messageId: body.messageId };
  } catch (error) {
    const message = error.name === "AbortError" ? `Brevo send timed out after ${sendTimeout}ms.` : error.message;
    console.error("[BREVO ERROR] Gui email that bai:", message);
    printOtpFallback(email, otpCode);
    return { success: false, mode: "fallback", error: message };
  } finally {
    clearTimeout(timeoutId);
  }
}

async function sendSmtpEmail({ email, subject, htmlContent, otpCode }) {
  const host = process.env.SMTP_HOST || "smtp.gmail.com";
  const port = Number(process.env.SMTP_PORT || 587);
  const secure = process.env.SMTP_SECURE === "true"; // true for 465, false for other ports
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const from = process.env.SMTP_FROM || `NutriPath <${user}>`;
  const connectionTimeout = envTimeoutMs("SMTP_CONNECTION_TIMEOUT_MS", 5000);
  const greetingTimeout = envTimeoutMs("SMTP_GREETING_TIMEOUT_MS", 5000);
  const socketTimeout = envTimeoutMs("SMTP_SOCKET_TIMEOUT_MS", 8000);
  const sendTimeout = envTimeoutMs("SMTP_SEND_TIMEOUT_MS", 9000);

  if (!user || !pass || user.includes("your_email")) {
    console.log("[SMTP WARNING] SMTP chua duoc cau hinh hoac su dung gia tri mac dinh.");
    console.log("[SMTP WARNING] Hay dien SMTP_USER va SMTP_PASS trong file .env de gui mail that.");
    printOtpFallback(email, otpCode, "EMAIL OTP");
    return { success: false, mode: "console" };
  }

  let transporter;
  let timeoutId;
  try {
    transporter = nodemailer.createTransport({
      host,
      port,
      secure,
      connectionTimeout,
      greetingTimeout,
      socketTimeout,
      auth: {
        user,
        pass,
      },
    });

    const timeout = new Promise((_, reject) => {
      timeoutId = setTimeout(() => {
        reject(Object.assign(new Error(`SMTP send timed out after ${sendTimeout}ms.`), { code: "ESMTP_TIMEOUT" }));
      }, sendTimeout);
    });
    const info = await Promise.race([
      transporter.sendMail({
        from,
        to: email,
        subject,
        html: htmlContent,
      }),
      timeout,
    ]);
    clearTimeout(timeoutId);
    transporter.close?.();

    console.log(`[SMTP SUCCESS] Da gui email OTP toi ${email}. MessageId: ${info.messageId}`);
    return { success: true, mode: "smtp", messageId: info.messageId };
  } catch (error) {
    if (timeoutId) clearTimeout(timeoutId);
    transporter?.close?.();
    console.error("[SMTP ERROR] Gui email that bai:", error.message);
    printOtpFallback(email, otpCode);
    return { success: false, mode: "fallback", error: error.message };
  }
}

export async function sendOtpEmail({ email, otpCode }) {
  const { subject, htmlContent } = buildOtpEmail(otpCode);
  const provider = String(process.env.EMAIL_PROVIDER || "").trim().toLowerCase();
  const hasBrevoConfig = Boolean(String(process.env.BREVO_API_KEY || "").trim());

  if (provider === "brevo" || (!provider && hasBrevoConfig)) {
    return sendBrevoEmail({ email, subject, htmlContent, otpCode });
  }

  return sendSmtpEmail({ email, subject, htmlContent, otpCode });
}
