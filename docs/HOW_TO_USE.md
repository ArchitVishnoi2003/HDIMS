# HDIMS — How to Use

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
3. Tap a patient card to see full details (enriched with patient's own data from `users` collection when linked)

### View Decrypted Health Records
1. In the patient details dialog, if the patient has approved your access request, a green **"View Records"** button appears
2. Tap it to see a tabbed dialog with the patient's decrypted medications, allergies, checkups, and appointments
3. The session expires automatically after 4 hours

### Edit a Patient
1. Dashboard → **Update Patient**
2. Search and select the patient
3. If the patient has Privacy Mode enabled, you must have an approved access session to proceed
4. Modify fields → tap **Update Patient** — changes sync to both `patients` and `users` collections

### Delete a Patient
1. Dashboard → **Delete Patient**
2. Tap the delete icon on the patient card → confirm

### Requesting Access to Encrypted Records
1. View a patient whose dialog shows a **Privacy Mode Active** banner
2. Tap **Request Access**
3. Wait for the patient to approve from their device
4. Once approved, the **"View Records"** button appears and the **Update Patient** flow is unblocked

### Linking an Existing Patient
1. Dashboard → **Link Patient** (grid card or drawer)
2. Enter the patient's registered email address → tap **Send Request**
3. The patient receives a banner on their dashboard
4. Once the patient taps **Accept**, the link is established and the patient appears in your patient list

### Managing a Patient's Routine
1. Dashboard → **View Patients** → tap a patient
2. In the details dialog, tap **Manage Routine** (visible when the patient has a linked account and no unresolved privacy barrier)
3. Use the three tabs (Daily, Exercise, Diet) to add, edit, or delete routine entries
4. Changes appear in real-time on the patient's Routine tab

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

Use the hamburger menu (top-left) for Privacy & Security, Profile Settings, AI Assistant, Help, and Sign Out.

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

## 8. Privacy & Security

### Accessing the Privacy & Security Page
- Tap the **shield icon** (🛡) in the top-right of the AppBar, or
- Open the drawer → tap **Privacy & Security**

### Enabling Privacy Mode
1. On the Privacy & Security page, toggle the **Privacy Mode** switch ON
2. Enter a 6-digit PIN and confirm it → tap **Enable Privacy Mode**
3. All existing records are encrypted; new records are encrypted before upload

> **Important:** If you forget your PIN, encrypted records cannot be recovered. You will need to reset Privacy Mode, which deletes all encrypted records.

### Disabling Privacy Mode
1. Privacy & Security page → Privacy Mode switch → toggle OFF
2. Confirm the dialog — all records are decrypted back to plaintext

### Approving a Doctor Access Request
Requests appear in two places:
1. **Dashboard banner** — at the top of any tab: *"Dr. [Name] is requesting access to your health records."*
2. **Privacy & Security page** — "Pending Access Requests" card

Tap **Approve** — a 4-hour decrypted session is created for the doctor.
Tap **Deny** — the request is rejected immediately.

### Revoking Doctor Access
1. Open the Privacy & Security page
2. Under **Active Doctor Sessions**, find the doctor's session
3. Tap **Revoke** — access is terminated immediately, the session snapshot is deleted

---

## 9. Using the AI Health Assistant

1. Drawer → **Ask AI**
2. Type a question about diet, nutrition, or general health
3. The assistant responds using Google Gemini
4. Do not include personal identifiers (full name, national ID) in your messages

### Generating a Personalised AI Routine
1. Patient Dashboard → **Routine** tab (tab 5)
2. Tap the **sparkle icon** (✨) in the header
3. Set your preferences: diet type, fitness level, strength training comfort, goals
4. Tap **Generate** — the app sends your health profile + preferences to Gemini
5. AI-generated daily routine, exercises, and diet plan replace existing entries
6. Preferences are saved and pre-populated next time

### Accepting a Doctor Link Request
1. When a doctor sends a link request, a banner appears at the top of your dashboard
2. Tap **Accept** to link with the doctor, or **Deny** to reject

---

## 10. Signing Out

- Tap the **⋮** menu (top-right of any dashboard) → **Logout**
- Or use the drawer → **Sign Out**
- Confirm the dialog
