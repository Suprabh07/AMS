<div align="center">
  <img src="assets/logo.png" alt="BMSCE AMS Logo" width="160" height="160">
  
  #  BMSCE Attendance Management System (AMS)
  
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
- [📂 Project Structure](#-project-structure)
- [⚙️ Setup & Installation](#-setup--installation)
- [🛡️ Security & Privacy](#-security--privacy)
- [📄 License](#-license)

---

## 🌟 Overview

The **BMSCE AMS** is a comprehensive academic companion designed specifically for the **BMS College of Engineering** ecosystem. It streamlines the complex processes of attendance marking, CIE (Continuous Internal Evaluation) calculations, and real-time student-teacher data synchronization.

---

## ✨ Key Features

### 🛡️ App Security
- **🔐 Biometric Guard:** Fingerprint and Face ID integration to protect academic data every time the app is opened or resumed from the background.
- **📧 Domain Verification:** Signup restricted exclusively to `@bmsce.ac.in` email addresses.

### 👨‍🎓 Student Experience
- **📊 Interactive Analytics:** Visualized attendance and marks trends using dynamic charts (`fl_chart`).
- **⚠️ Low Attendance Alerts:** Smart notification system that alerts students if their attendance drops below the mandatory 75%.
- **📅 Detailed Logs:** Transparent view of every attendance record with precise timestamps and session types.

### 👩‍🏫 Teacher Power-Tools
- **🎯 One-Tap Marking:** Optimized UI for marking attendance of entire sections in seconds with "Mark All" capabilities.
- **🛑 Proactive Monitoring:** Real-time notification badge that alerts faculty whenever a student in their course falls below 75% attendance.
- **🔢 Automated CIE Engine:** Effortless entry for Internals, Quizzes, AAT, and Lab Exams with automated Best-of-2 logic.

---

## 🛠 Tech Stack

| Layer | Technology | Role |
| :--- | :--- | :--- |
| **Frontend** | **Flutter & Material 3** | Modern UI/UX |
| **Backend** | **Firebase Firestore** | Real-time NoSQL database |
| **Auth** | **Firebase Auth** | Secure identity management |
| **Biometrics** | **Local Auth** | Hardware-level security |
| **Charts** | **FL Chart** | Data visualization |

---

## 📂 Project Structure

```bash
lib/
├── main.dart                # Biometric Guard & Entry Point
├── login_screen.dart        # Secure Multi-role Gateway
├── signup_screen.dart       # Verified Registration
├── student_dashboard.dart   # Student Hub & Analytics
├── teacher_dashboard.dart   # Attendance & CIE Management
├── user_role.dart           # Permission definitions
└── firebase_options.dart    # Cloud configuration
```

---

## ⚙️ Setup & Installation

### 1️⃣ Environment Prep
- Install [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Configure a [Firebase Project](https://console.firebase.google.com/)

### 2️⃣ Quick Start
```bash
# Clone the repository
git clone https://github.com/Suprabh07/AMS.git

# Install dependencies
flutter pub get

# Run on your device
flutter run
```

---

## 🛡️ Security & Privacy
- **Hardware-Level Security:** Biometric data never leaves the device.
- **Role Isolation:** Students cannot access teacher-only functions and vice-versa.
- **Data Integrity:** Marks entry is limited to authorized faculty members.

---

## 📄 License
This project is licensed under the **MIT License**.

---

<div align="center">
  <p><b>Crafted with ❤️ for the BMSCE Community</b></p>
  <sub>Suprabh07 &copy; 2024 • Version 1.0.0</sub>
</div>
