# NutriPath Mobile

Flutter mobile app for the NutriPath backend in `NutriPath_Backend`.

## Run The Backend

```powershell
cd .\NutriPath_Backend
npm ci
npm run dev
```

The backend runs at `http://127.0.0.1:8080` on Windows.

## Run The Flutter App

Open this folder in Android Studio, select an Android emulator, then run:

```powershell
flutter pub get
flutter run
```

By default the app uses:

- Android emulator: `http://10.0.2.2:8080`
- Desktop/web: `http://127.0.0.1:8080`

To use a deployed backend or a physical Android device, pass a URL explicitly:

```powershell
flutter run --dart-define=API_BASE_URL=https://your-backend.example.com
```

For a physical Android phone on the same Wi-Fi, use your computer LAN IP:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

## Main Features

- Auth: login, register, session restore, logout.
- Dashboard: daily calories, macros, water, weekly progress, AI coach preview.
- Tracker: meals, food library, camera food estimate, custom foods, water, workouts.
- Recipes: search, tag filtering, saved personalized recipes, AI recipe generation.
- Reports: nutrition range, charts, top foods, CSV share/export.
- Membership: Free/VIP/SVIP plans, quote, discount, trial, demo checkout.
- Profile: member profile, plan benefits, notifications, payment history.
- Admin: overview, users, content, analytics, AI settings, security, system status.
