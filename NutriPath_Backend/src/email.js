import nodemailer from "nodemailer";

export async function sendOtpEmail({ email, otpCode }) {
  const host = process.env.SMTP_HOST || "smtp.gmail.com";
  const port = Number(process.env.SMTP_PORT || 587);
  const secure = process.env.SMTP_SECURE === "true"; // true for 465, false for other ports
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const from = process.env.SMTP_FROM || `NutriPath <${user}>`;

  const subject = "Mã xác thực OTP kích hoạt tài khoản NutriPath";
  const htmlContent = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
      <h2 style="color: #4CAF50; text-align: center;">Xác thực tài khoản NutriPath</h2>
      <p>Chào bạn,</p>
      <p>Cảm ơn bạn đã đăng ký thành viên của <strong>NutriPath</strong>. Để hoàn tất kích hoạt tài khoản, vui lòng nhập mã xác thực OTP dưới đây vào ứng dụng:</p>
      <div style="background-color: #f9f9f9; padding: 15px; text-align: center; border-radius: 4px; margin: 20px 0;">
        <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #333;">${otpCode}</span>
      </div>
      <p style="color: #666; font-size: 13px;">Mã OTP này có hiệu lực trong vòng <strong>10 phút</strong>. Vui lòng không chia sẻ mã này với bất kỳ ai.</p>
      <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;" />
      <p style="color: #999; font-size: 11px; text-align: center;">Đây là email tự động từ hệ thống NutriPath, vui lòng không trả lời email này.</p>
    </div>
  `;

  if (!user || !pass || user.includes("your_email")) {
    console.log(`\n==============================================`);
    console.log(`[SMTP WARNING] SMTP chưa được cấu hình hoặc sử dụng giá trị mặc định.`);
    console.log(`[EMAIL OTP] Đăng ký thành viên mới: ${email}`);
    console.log(`[EMAIL OTP] Mã xác thực OTP của bạn là: ${otpCode}`);
    console.log(`[SMTP WARNING] Hãy điền SMTP_USER và SMTP_PASS trong file .env để gửi mail thật.`);
    console.log(`==============================================\n`);
    return { success: false, mode: "console" };
  }

  try {
    const transporter = nodemailer.createTransport({
      host,
      port,
      secure,
      auth: {
        user,
        pass,
      },
    });

    const info = await transporter.sendMail({
      from,
      to: email,
      subject,
      html: htmlContent,
    });

    console.log(`[SMTP SUCCESS] Đã gửi email OTP tới ${email}. MessageId: ${info.messageId}`);
    return { success: true, mode: "smtp", messageId: info.messageId };
  } catch (error) {
    console.error(`[SMTP ERROR] Gửi email thất bại:`, error.message);
    // Fallback print to console so app register flow doesn't break!
    console.log(`\n==============================================`);
    console.log(`[EMAIL OTP FALLBACK] Mã xác thực OTP của bạn là: ${otpCode}`);
    console.log(`==============================================\n`);
    return { success: false, mode: "fallback", error: error.message };
  }
}
