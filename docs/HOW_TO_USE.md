# HDIMSS — How to Use

## Prerequisites

| Tool | Minimum Version |
|---|---|
| Flutter SDK | 3.4.4 |
| Dart SDK | 3.4.4 |
| Android Studio / Xcode | Latest stable |
| Firebase CLI | Latest |
| A Firebase project | With Firestore, Firebase Auth enabled |

---

## 1. Clone & Install Dependencies

```bash
git clone <repo-url>
cd hdimss
flutter pub get
```

---

## 2. Firebase Setup

### a. Create a Firebase project
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project (or use an existing one)
3. Enable **Firebase Authentication** → Email/Password provider
4. Enable **Cloud Firestore** → Start in production or test mode

### b. Add the Android app
1. In Firebase console → Project Settings → Add app → Android
2. Package name: `com.example.flutterapp`
3. Download `google-services.json` → place at `android/app/google-services.json`

### c. Add the iOS app (optional)
1. In Firebase console → Add app → iOS
2. Bundle ID: `com.example.flutterapp`
3. Download `GoogleService-Info.plist` → place at `ios/Runner/GoogleService-Info.plist`

### d. Update `lib/firebase_options.dart`
Run:
```bash
flutterfire configure
```
This regenerates `firebase_options.dart` with your project's credentials.

---

## 3. Configure Gemini AI Key

Open `lib/const/secrets.dart` and replace the placeholder:

```dart
const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
```

Get a key from [Google AI Studio](https://aistudio.google.com/app/apikey).

> **Security note:** For production, move this key to a Cloud Function and call it from the app instead of embedding it in the APK.

---

## 4. Run the App

```bash
# Android
flutter run

# iOS
flutter run -d <ios-device-id>

# Release build (Android)
flutter build apk --release
```

---

## 5. First-Time App Setup

### Creating a Doctor Account
1. Launch the app → tap **Sign Up**
2. Enter name, email, and password
3. Select **Hospital / Doctor** as user type
4. Read and scroll through the Privacy Policy — check the consent box → tap **Confirm & Continue**
5. Tap **Create Account**
6. You are taken to the Doctor Dashboard

### Creating a Patient Account
1. Launch the app → tap **Sign Up**
2. Enter name, email, and password
3. Select **Patient** as user type
4. Accept the Privacy Policy (same flow as above)
5. Tap **Create Account**
6. You are taken to the Patient Dashboard

> **Linking tip:** If a doctor has already added a patient record with the same email address, the patient account automatically links to that record. The patient's "Personal Details" tab will show doctor-entered data.

---

## 6. Doctor Workflow

### Add a Patient
1. Dashboard → **Add Patient**
2. Fill in all demographic and medical fields
3. Tap **Add Patient** — saved to Firestore under `patients/`

### View / Search Patients
1. Dashboard → **View Patients**
2. Use the search bar to filter by name, email, or phone
3. Tap a patient card to see full details

### Edit a Patient
1. Dashboard → **Update Patient**
2. Search and select the patient
3. Modify fields → tap **Update Patient**

### Delete a Patient
1. Dashboard → **Delete Patient**
2. Tap the delete icon on the patient card → confirm

### Requesting Access to Encrypted Records
1. View a patient whose dialog shows a **Privacy Mode Active** banner
2. Tap **Request Access**
3. Wait for the patient to approve from their device (you will see the data once they do)

---

## 7. Patient Workflow

### Navigating the Dashboard
The bottom navigation bar has six tabs:

| Tab | Content |
|---|---|
| Home | Welcome overview |
| Details | Personal info linked from doctor records |
| Medicines | Current medications + allergies |
| History | Checkup / medical visit log |
| Appointments | Booked appointments |
| Routine | Daily health routine |

Use the hamburger menu (top-left) for Profile Settings, AI Assistant, Help, and Sign Out.

### Adding a Medication
1. Medicines tab → **Add Medication** (green button)
2. Enter name, dosage, frequency, purpose, start date → **Save**

### Adding an Allergy
1. Medicines tab → **Add Allergy** (red button)
2. Enter allergen, description, severity → **Save**

### Logging a Checkup
1. History tab → **+ Add Record**
2. Fill in date, diagnosis, treatment, vitals → **Save**

### Booking an Appointment
1. Appointments tab → **Book** (FAB)
2. Enter doctor, hospital, date, time, type, notes → set status to **Upcoming** → **Save**

---

## 8. Enabling Privacy Mode

1. Open the drawer → **Profile Settings**
2. Scroll to the **Privacy Mode** card → toggle the switch ON
3. Enter a 6-digit PIN and confirm it → tap **Enable Privacy Mode**
4. All existing records are encrypted; new records are encrypted before upload

> **Important:** If you forget your PIN, encrypted records cannot be recovered. You will need to reset Privacy Mode, which deletes all encrypted records.

### Disabling Privacy Mode
1. Profile Settings → Privacy Mode switch → toggle OFF
2. Confirm the dialog — all records are decrypted back to plaintext

### Approving a Doctor Access Request
1. A banner appears at the top of the dashboard: *"Dr. [Name] is requesting access to your health records."*
2. Tap **Approve** — a 4-hour decrypted session is created for the doctor
3. Tap **Deny** — the request is rejected immediately

---

## 9. Using the AI Health Assistant

1. Drawer → **Ask AI**
2. Type a question about diet, nutrition, or general health
3. The assistant responds using Google Gemini
4. Do not include personal identifiers (full name, national ID) in your messages

---

## 10. Signing Out

- Tap the **⋮** menu (top-right of any dashboard) → **Logout**
- Or use the drawer → **Sign Out**
- Confirm the dialog
