# RecyLink : A Connected Recycling Ecosystem

# RecyLink: Smart Recycling & Upcycling Marketplace

## 📌 Project Overview
**RecyLink** is a mobile application developed as a Final Year Project (FYP) to promote sustainable living through technology. The app combines AI-powered waste classification with a community-driven marketplace, making recycling easier and more rewarding for users.

The system aims to solve the difficulty of identifying recyclable materials and provides a platform for trading upcycled goods, bridging the gap between waste management and circular economy participation.

## 🚀 Key Features
* **🤖 AI Waste Classification:**
    * Uses **TensorFlow Lite** for on-device image recognition.
    * Users can scan an item to instantly identify its material type and recyclability status.
* **🛍️ Upcycled Marketplace:**
    * A dedicated platform for users to buy and sell upcycled or reusable items.
    * Connects eco-conscious buyers with sellers.
* **🏆 Rewards & Challenges System:**
    * Gamified experience where users earn points for verifying recycling activities.
    * Complete daily/weekly challenges to climb the leaderboard.
* **⚙️ Admin Panel:**
    * A separate web-based dashboard for managing users, verifying marketplace listings, and monitoring app activity.

## 🛠 Tech Stack
* **Framework:** Flutter (Dart)
* **Backend:** Firebase (Authentication, Firestore Database, Storage)
* **Machine Learning:** TensorFlow Lite (Mobile-optimized classification models)


## 📸 Demo Video
Link - https://youtu.be/HTvQLZGWdk8

## ⚙️ Installation & Setup

### Prerequisites
* Flutter SDK (3.x or later)
* Dart SDK
* Firebase Project Setup (with `google-services.json` / `GoogleService-Info.plist`)

### Steps
1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/yourusername/recylink.git](https://github.com/yourusername/recylink.git)
    ```
2.  **Install dependencies:**
    ```bash
    cd recylink
    flutter pub get
    ```
3.  **Setup Firebase:**
    * Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.
4.  **Run the app:**
    ```bash
    flutter run
    ```

## 🧠 AI Model Details
The waste classification feature is powered by a custom TensorFlow Lite model trained on [Dataset Name/Type]. It runs locally on the device to ensure fast performance without needing a heavy server-side inference cost.

## 📄 License
This project is for educational purposes (Final Year Project).
