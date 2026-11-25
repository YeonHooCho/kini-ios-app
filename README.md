# KINI (끼니) — Family Meal-Sharing & AI Conversation iOS App

> **SwiftUI · Firebase (Firestore / FCM / Cloud Functions) · Google Gemini Multimodal API**  
> An iOS social dining application designed to help busy family members stay connected by sharing daily meal photos on a virtual shared dining table, sparking warm conversations through context-aware AI prompts and interactive 3D mascot customization.

---

## Overview & Motivation
- Modern family members often eat separately due to work and study schedules, making daily check-ins feel repetitive or burdensome.
- **KINI** transforms routine meal logging into a shared visual experience: each member's uploaded meal photo populates a unified **multi-person dining table**, while a multimodal **Gemini AI** analyzes meal photos, memos, and recent chat context to suggest natural, 17-character conversation starters tailored to the family's chosen tone.

## Key Features
1. **Shared Dining Table & Family Room Onboarding (`ContentView`, `CreateFamilyFlowView`, `JoinFamilyFlowView`):**
   - Generates a unique 6-digit family invite code and onboarding goal tags, syncing real-time meal posts across family devices via **Firebase Firestore** with Base64 image compression (600×600 JPEG) to eliminate storage overhead.
2. **Multimodal Gemini AI Conversation Prompts (`AIService.swift`):**
   - Analyzes uploaded meal images alongside text memos and the latest 5 chat messages to generate context-aware questions (including empathetic check-ins when a member skips a meal or only drinks coffee).
   - Enforces a strict **17-character output constraint** for clean chat bubble rendering, supports customizable persona tones, and implements automatic retry/fallback handling for API resilience.
3. **Interactive Monkey-Tail Dropdown & Real-Time Family Chat (`DiningDropSheet`, `ChatRoomView`):**
   - Pulling down the mascot tail handle in the chat header reveals today's completed family dining table sheet (`DiningDropSheet`) over the conversation view.
   - Supports instant message synchronization and background **APNs remote push notifications** triggered via **Firebase Cloud Functions** and FCM tokens (`KkiniApp.swift`).
4. **3D Wool-Felt Mascot Customization & Satiety Gauge (`CharacterCustomView`):**
   - Features custom 3D-rendered monkey mascot outfits (12 outfit sets) and a dynamic hunger/satiety gauge linked to daily family meal participation.
5. **Family Dining Reports & Account Management (`PersonalProfileSettingView`, `AccountManagementView`):**
   - Aggregates weekly/monthly meal participation logs and supports custom avatar selection, camera/gallery meal capture, and profile management.

## Architecture & Tech Stack
- **iOS Client:** Swift, SwiftUI, UIKit Interop (Camera/Photo Picker), `UserDefaults` / `@AppStorage`
- **Backend & Real-Time Sync:** Firebase Firestore (real-time snapshot listeners), Firebase Cloud Messaging (FCM), Apple Push Notification service (APNs), Firebase Cloud Functions (Node.js)
- **Generative AI:** Google Gemini Vision/Multimodal REST API (`URLSession`, Base64 inline image encoding)

## Repository Structure

```text
├── Kkini.xcodeproj/                 # Xcode project configuration
└── Kkini/
    ├── KkiniApp.swift               # App lifecycle, Firebase initialization, APNs & FCM delegate
    ├── ContentView.swift            # Main 5-tab navigation, shared dining table, chat & report views
    ├── FirebaseManager.swift        # Firestore CRUD, real-time meal/chat listeners & image compression
    ├── AIService.swift              # Multimodal Gemini API client, prompt engineering & retry logic
    ├── SplashView.swift             # Animated launch splash screen
    ├── OnboardingStartView.swift    # Initial user onboarding flow
    ├── CreateFamilyFlowView.swift   # 6-digit family room creation flow
    ├── JoinFamilyFlowView.swift     # Family invite code validation & join flow
    ├── PersonalProfileSettingView.swift # Profile & custom avatar configuration
    ├── AccountManagementView.swift  # Family hub & account management
    └── Assets.xcassets/             # Custom 3D mascot outfits, icons, and splash assets
