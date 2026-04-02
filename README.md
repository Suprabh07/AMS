# BMSCE Attendance Management System (AMS)

A modern, high-performance Attendance Management System designed specifically for **BMS College of Engineering**. This cross-platform mobile application helps students and teachers track attendance, courses, and marks seamlessly using a cloud-integrated solution.

## 🚀 Features

### For Students
*   **Personalized Dashboard:** A clean Home screen with a custom BMSCE header, profile overview, and real-time notifications.
*   **Course Management:** Automatically fetches courses based on the student's current Department and Semester (including Credits info).
*   **Smart Attendance Tracking:** 
    *   Summary view with color-coded percentages (Green for ≥75%).
    *   Detailed history view for each subject showing every recorded class with date, time slot, and status.
*   **Profile Management:** View and update profile pictures directly from the app using the pen icon. Full-screen zoomable profile viewer.
*   **Secure Authentication:** Login/Signup restricted to `@bmsce.ac.in` email IDs. Persistent sessions and secure password reset.

### For Teachers (In Progress)
*   **Teacher Profiles:** Quick view of department and contact details.
*   **Attendance Marking:** (Upcoming) Direct marking of attendance for mapped courses.

### For Admins (Web Panel)
*   **Admin Dashboard:** A standalone web-based control panel to manage students, teachers, and courses.
*   **Storage Optimization:** Specialized logic to ensure only one profile image exists per user to minimize storage costs.

## 🛠 Tech Stack

*   **Frontend:** Flutter (Dart)
*   **Backend:** Firebase
    *   **Authentication:** Email/Password based secure auth.
    *   **Firestore:** Real-time NoSQL database for student, teacher, and course mapping.
    *   **Storage:** Cloud Storage for profile photos.
*   **Design:** Material 3 with custom Glassmorphism and Gradient elements.

## 📱 Screenshots

| Splash & Login | Student Dashboard | Attendance Details | Profile Tab |
|:---:|:---:|:---:|:---:|
| ![Login](https://via.placeholder.com/200x400?text=Login) | ![Dashboard](https://via.placeholder.com/200x400?text=Dashboard) | ![Attendance](https://via.placeholder.com/200x400?text=Attendance) | ![Profile](https://via.placeholder.com/200x400?text=Profile) |

*(Note: Replace placeholders with actual screenshots from your `assets/` folder)*

## 📂 Project Structure

```
lib/
├── main.dart                # Entry point & Auth state management
├── login_screen.dart        # Secure login with role selection
├── signup_screen.dart       # User registration with email validation
├── forgot_password_screen.dart # Email-based password recovery
├── student_dashboard.dart   # Main hub for students (Tabs & Logic)
├── teacher_dashboard.dart   # Profile hub for teachers
└── user_role.dart           # Role definitions (Enum)
admin_panel.html             # Standalone Admin Control Web App
```

## ⚙️ Setup and Installation

1.  **Prerequisites:**
    *   Flutter SDK installed.
    *   Firebase Project created.
    *   Blaze Plan (required for Storage/Functions if using advanced features).

2.  **Clone the Repo:**
    ```bash
    git clone https://github.com/Suprabh07/AMS.git
    cd AMS_bmsce
    ```

3.  **Firebase Configuration:**
    *   Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
    *   Update `lib/firebase_options.dart` with your project keys.

4.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

5.  **Run the App:**
    ```bash
    flutter run
    ```

## 📊 Database Schema

*   **`students`**: usn, name, email, department_id, semester_id, section, profile_url.
*   **`teachers`**: name, email, department_id, phone, profile_url.
*   **`courses`**: course_code, course_name, credits, department_id, semester_id.
*   **`attendance`**: usn, course_code, date, start_time, end_time, status (Present/Absent).

## ⚠️ Security Note
The `lib/firebase_options.dart` file should **never** be pushed to public repositories if it contains sensitive keys. Ensure it is added to your `.gitignore`.

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.
