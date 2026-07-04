# NutriPath Backend

Backend REST cho FE NutriPath, dùng HAL-style HATEOAS. Mỗi response chính đều có `_links`; collection dùng `_embedded`.

## Chạy local

```bash
npm run start
```

Mặc định API chạy ở:

```text
http://127.0.0.1:8080
http://10.0.2.2:8080   # Android emulator
```

Local mobile note: `.env` in this backend uses `HOST=0.0.0.0`, `PORT=8080`, and JSON data so the Android emulator can reach the API at `http://10.0.2.2:8080`.

Local và production đều bind `0.0.0.0` theo mặc định để chạy được với Android emulator và các môi trường deploy; có thể override bằng `HOST`.

Chạy `npm install` trước khi dùng Supabase PostgreSQL hoặc deploy production vì backend cần package `pg`. Local JSON mode vẫn có thể chạy nhanh bằng file `data/db.json`.

## Chạy với dữ liệu SQL Server

Nếu đã import `NutriPath_Database.sql`, chạy backend bằng SQL Server source:

```powershell
$env:NUTRIPATH_DATA_SOURCE="sqlserver"
$env:NUTRIPATH_SQL_SERVER="localhost"
$env:NUTRIPATH_SQL_DATABASE="NutriPath"
node src/server.js
```

Khi đó FE vẫn gọi các API cũ, nhưng dữ liệu được load từ SQL Server lúc backend khởi động.

## Chạy với Supabase PostgreSQL

NutriPath dùng Supabase PostgreSQL theo schema normalized cho production. Backend vẫn giữ nguyên API hiện tại cho frontend, nhưng dữ liệu được lưu thành nhiều bảng thật như `nutripath_members`, `nutripath_foods`, `nutripath_meal_logs`, `nutripath_recipes`, `nutripath_payments`, `nutripath_chat_messages`, `nutripath_ai_safety_logs`.

Nếu project cũ đang có bảng legacy `public.nutripath_app_state`, lần chạy đầu với normalized storage sẽ đọc row `default` rồi seed dữ liệu sang các bảng mới khi chúng còn trống.

1. Tạo project Supabase.
2. Mở SQL Editor và chạy file `sql/nutripath_supabase_normalized.sql`.
3. Lấy connection string ở Supabase Database Settings, ưu tiên pooler URI cho server deploy.
4. Cấu hình backend:

```powershell
$env:NUTRIPATH_DATA_SOURCE="supabase"
$env:NUTRIPATH_SUPABASE_STORAGE="normalized"
$env:NUTRIPATH_SUPABASE_SCHEMA="public"
$env:SUPABASE_DATABASE_URL="postgresql://postgres.xxxxxx:[PASSWORD]@aws-0-xxx.pooler.supabase.com:6543/postgres"
node src/server.js
```

Trên Render/Railway, đặt các biến môi trường tương tự trong dashboard. Không commit connection string hoặc database password.

Muốn tạm chạy adapter cũ một dòng JSONB thì đặt `NUTRIPATH_SUPABASE_STORAGE=app_state` và dùng file `sql/nutripath_supabase_app_state.sql`. Không dùng mode này cho dữ liệu production dài hạn.

## OTP email on Render Free

Render Free blocks outbound SMTP ports such as `25`, `465`, and `587`, so Gmail SMTP and Brevo SMTP can time out in production. Use Brevo's HTTPS API instead:

```powershell
$env:EMAIL_PROVIDER="brevo"
$env:BREVO_API_KEY="xkeysib-..."
$env:BREVO_FROM_EMAIL="nam27200310@gmail.com"
$env:BREVO_FROM_NAME="NutriPath"
node src/server.js
```

`BREVO_FROM_EMAIL` must be a verified Brevo sender. Keep `SMTP_*` variables only for local development or paid hosts that allow SMTP.

## HATEOAS

Ví dụ `GET /api` trả về các link entrypoint:

```json
{
  "name": "NutriPath API",
  "_links": {
    "members": { "href": "http://127.0.0.1:8080/api/members", "method": "GET" },
    "recipes": { "href": "http://127.0.0.1:8080/api/recipes", "method": "GET" },
    "calorieCalculator": { "href": "http://127.0.0.1:8080/api/calculations/calorie", "method": "POST" }
  }
}
```

## API chính theo FE

- `GET /api/members/mem-001/dashboard?date=2026-03-13`: dashboard, macro, nước, activity, weekly chart.
- `POST /api/calculations/calorie`: tính BMR, TDEE, BMI, macro và calo đốt khi tập.
- `GET /api/foods?search=phở`: food database cho meal tracker.
- `GET /api/members/mem-001/meal-logs/2026-03-13`: nhật ký bữa ăn.
- `POST /api/members/mem-001/meal-logs/2026-03-13/meals/breakfast/items`: thêm món vào bữa ăn.
- `PATCH /api/members/mem-001/meal-logs/2026-03-13/water`: cập nhật lượng nước.
- `GET /api/recipes?tag=Low-cal&search=canh`: kho công thức.
- `GET /api/plans?billing=annual`: gói Free/VIP/SVIP kèm price preview.
- `POST /api/checkout/quote`: tính đơn hàng, VAT, mã `NUTRIPATH10`.
- `POST /api/payments`: checkout demo, nâng cấp member, không lưu dữ liệu thẻ.
- `POST /api/chat/messages`: NutriBot response.
- `GET /api/admin/overview`: dashboard admin.
- `GET /api/admin/users`: quản lý người dùng.
- `GET /api/admin/content`: content admin.
- `GET /api/admin/analytics`: chart admin.
- `GET/PATCH /api/admin/settings/ai`: cài đặt AI.
- `GET/PATCH /api/admin/security`: cài đặt bảo mật.

## Ví dụ request

```bash
curl -X POST http://127.0.0.1:8080/api/calculations/calorie \
  -H "Content-Type: application/json" \
  -d "{\"age\":25,\"weightKg\":65,\"heightCm\":168,\"gender\":\"female\",\"activityLevel\":\"light\",\"goal\":\"lose\",\"exerciseType\":\"walking\",\"durationMinutes\":30}"
```

```bash
curl -X POST http://127.0.0.1:8080/api/payments \
  -H "Content-Type: application/json" \
  -d "{\"memberId\":\"mem-001\",\"planId\":\"vip\",\"billing\":\"monthly\",\"paymentMethod\":\"card\",\"discountCode\":\"NUTRIPATH10\"}"
```

## Stripe Payments

Mobile apps use Stripe PaymentSheet through PaymentIntents so the card form stays inside the app. Hosted Checkout Sessions are still available as a web/desktop fallback. Set these backend environment variables before using the Stripe path:

```powershell
$env:STRIPE_SECRET_KEY="sk_test_..."
$env:STRIPE_PUBLISHABLE_KEY="pk_test_..."      # required by mobile PaymentSheet
$env:STRIPE_WEBHOOK_SECRET="whsec_..."         # required for /api/stripe/webhook
$env:STRIPE_CHECKOUT_SUCCESS_URL="https://your-api.example.com/api/stripe/checkout/success?session_id={CHECKOUT_SESSION_ID}"
$env:STRIPE_CHECKOUT_CANCEL_URL="https://your-api.example.com/api/stripe/checkout/cancel"
node src/server.js
```

New endpoints:

- `POST /api/stripe/payment-intents`: create a Stripe PaymentIntent for native mobile PaymentSheet.
- `GET /api/stripe/payment-intents/:id`: verify a successful PaymentIntent and activate the member plan.
- `POST /api/stripe/checkout-sessions`: create a Stripe hosted Checkout Session.
- `GET /api/stripe/checkout-sessions/:id`: verify a paid session and activate the member plan.
- `POST /api/stripe/webhook`: fulfil `payment_intent.succeeded`, `checkout.session.completed`, and async succeeded events with signature verification.

The legacy `POST /api/payments` demo flow still exists for local demos without Stripe keys.

## Data store

Backend có 3 mode dữ liệu:

- `NUTRIPATH_DATA_SOURCE=json`: dev local, lần chạy đầu tạo `data/db.json` từ `src/data/seed.js`. File này được ignore để dữ liệu local không làm bẩn git.
- `NUTRIPATH_DATA_SOURCE=sqlserver`: load dữ liệu từ SQL Server qua `src/sqlserver-import.js`.
- `NUTRIPATH_DATA_SOURCE=supabase`: production Supabase PostgreSQL. Mặc định `NUTRIPATH_SUPABASE_STORAGE=normalized`, dữ liệu được ghi vào nhiều bảng riêng thay vì một JSON blob.

Reset seed:

```bash
curl -X POST http://127.0.0.1:8080/api/dev/reset
```
