<div align="center">
  <img src="assets/logo.png" alt="BMSCE AMS Logo" width="160" height="160">
  
  # 🚀 BMSCE Attendance Management System (AMS)
  
  ### *Digitalizing the Academic Pulse of BMS College of Engineering*
  
  <p align="center">
    <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
    <a href="https://firebase.google.com/"><img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"></a>
    <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"></a>
  </p>

  <p align="center">
    <b>A high-performance, real-time solution for students and educators.</b>
    <br />
    <a href="#-key-features"><strong>Explore the features »</strong></a>
    <br />
    <br />
    <a href="#-interface-preview">View Demo</a>
    ·
    <a href="https://github.com/Suprabh07/AMS/issues">Report Bug</a>
    ·
    <a href="https://github.com/Suprabh07/AMS/issues">Request Feature</a>
  </p>
</div>

---

## 📖 Table of Contents
- [🌟 Overview](#-overview)
- [✨ Key Features](#-key-features)
  - [👨‍🎓 Student Experience](#-student-experience)
  - [👩‍🏫 Teacher Power-Tools](#-teacher-power-tools)
- [🛠 Tech Stack](#-tech-stack)
- [📱 Interface Preview](#-interface-preview)
- [📂 Project Structure](#-project-structure)
- [📊 Data Architecture](#-data-architecture)
- [⚙️ Setup & Installation](#-setup--installation)
- [🛡️ Security & Privacy](#-security--privacy)
- [📄 License](#-license)

---

## 🌟 Overview

The **BMSCE AMS** is not just an attendance tracker; it's a comprehensive academic companion. Designed specifically for the **BMS College of Engineering** ecosystem, it streamlines the complex processes of attendance marking, CIE (Continuous Internal Evaluation) calculations, and student-teacher data synchronization.

> **Why BMSCE AMS?** 
> Manual attendance and CIE calculation are prone to errors and time-consuming. This system provides a **single source of truth** with automated logic that ensures 100% accuracy in "Best-of-2" internal scores and attendance percentages.

---

## ✨ Key Features

### 👨‍🎓 Student Experience
- **⚡ Real-time Dashboard:** Instant overview of attendance status across all courses.
- **📊 Smart Analytics:** Color-coded progress indicators (Green ≥75%, Red <75%) to help students stay on track.
- **📅 Session Transparency:** Detailed view of every record—know exactly when you were present or absent.
- **👤 Profile Hub:** Self-service profile management with secure cloud-synced image storage.
- **🔑 Secure Access:** Authenticated login restricted to official `@bmsce.ac.in` domains.

### 👩‍🏫 Teacher Power-Tools
- **🎯 Precision Marking:** Optimized interface for marking attendance of entire sections in seconds.
- **🔢 Automated CIE Engine:** 
  - Effortless entry for **Internals (I1, I2, I3), Quizzes, and AAT**.
  - Built-in logic for **Best-of-2** calculation and final CIE aggregation.
- **🛑 Intelligent Guards:** Real-time validation prevents data entry errors—automatic warnings if marks exceed thresholds.
- **📝 Total Control:** Full flexibility to view, edit, or delete historical attendance records.
- **🗺️ Tailored View:** Zero-clutter experience—teachers only see the specific sections and courses they handle.

---

## 🛠 Tech Stack

| Layer | Technology | Role |
| :--- | :--- | :--- |
| **Frontend** | **Flutter & Material 3** | Cross-platform UI with modern aesthetics |
| **Backend** | **Firebase Firestore** | Real-time NoSQL cloud database |
| **Auth** | **Firebase Auth** | Secure student/teacher identity management |
| **Storage** | **Cloud Storage** | Scalable hosting for profile assets |
| **Logic** | **Dart** | High-performance business logic |

---

## 📱 Interface Preview

<div align="center">
  <table style="border: none;">
    <tr>
      <td align="center"><b>Modern Login</b></td>
      <td align="center"><b>Student Dashboard</b></td>
      <td align="center"><b>Attendance History</b></td>
      <td align="center"><b>Teacher Tools</b></td>
    </tr>
    <tr>
      <td><img src="https://via.placeholder.com/200x400?text=Login+UI" width="180" style="border-radius: 15px;"></td>
      <td><img src="https://via.placeholder.com/200x400?text=Dashboard+UI" width="180" style="border-radius: 15px;"></td>
      <td><img src="https://via.placeholder.com/200x400?text=History+UI" width="180" style="border-radius: 15px;"></td>
      <td><img src="https://via.placeholder.com/200x400?text=Teacher+UI" width="180" style="border-radius: 15px;"></td>
    </tr>
  </table>
  <p><i>(Visualizing the future of BMSCE Academic Management)</i></p>
</div>

---

## 📂 Project Structure

```bash
lib/
├── main.dart                # System entry & Auth orchestration
├── login_screen.dart        # Multi-role secure gateway
├── student_dashboard.dart   # Interactive hub for student tools
├── teacher_dashboard.dart   # Attendance & CIE Management engine
├── user_role.dart           # Permission & Role definitions
└── firebase_options.dart    # Cloud configuration (Secure)
```

---

## 📊 Data Architecture

<details>
<summary>🔍 <b>Explore the Firestore Schema</b></summary>

The system utilizes a flat, highly-indexed NoSQL structure:

- **`students`**: USN-keyed records for rapid profile retrieval.
- **`teachers`**: Department-specific educator metadata.
- **`courses`**: Academic catalog including credit weightage and lab status.
- **`attendance`**: Daily session logs with atomic USN list updates.
- **`marks`**: Multi-component performance records with automated reduction fields.
- **`teacher_mappings`**: Secure authorization links for classroom management.

</details>

---

## ⚙️ Setup & Installation

### 1️⃣ Environment Prep
- Install [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable)
- Configure [Firebase Project](https://console.firebase.google.com/)

### 2️⃣ Quick Start
```bash
# Clone the repository
git clone https://github.com/Suprabh07/AMS.git

# Install dependencies
flutter pub get

# Setup Firebase (requires FlutterFire CLI)
flutterfire configure

# Run on your device
flutter run
```

---

## 🛡️ Security & Privacy
- **Domain Locking:** Access is strictly limited to verified institution email domains.
- **Role Isolation:** Built-in middleware ensures teachers cannot access student-only views and vice versa.
- **Secure Storage:** sensitive keys are managed via local properties and excluded from public version control.

---

## 📄 License
This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <p><b>Crafted with ❤️ for the BMSCE Community</b></p>
  <sub>Suprabh07 &copy; 2024 • Version 1.0.0</sub>
</div>
