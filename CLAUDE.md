{\rtf1\ansi\ansicpg1252\cocoartf2761
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 # Academathon iPad \'97 Project Context for Claude\
\
## What this is\
A focused iPad app built in SwiftUI, integrating with the existing\
Academathon backend (Spring Boot, JWT auth, REST API at api.academathon.com).\
\
This is interview prep, not a product. I have a junior iOS interview on\
Thursday, May 28, 2026. The goal is to learn iOS fundamentals well enough\
to discuss them confidently, while shipping something real I can point to.\
\
## App Scope: Tutor Whiteboard\
\
The app has 4 screens total:\
\
1. Login screen \'97 email/password, calls backend POST /api/auth/login,\
   stores JWT in Keychain\
2. Lesson list \'97 fetches tutor's lessons from backend, shows student name,\
   subject, date/time, and status badge\
3. Lesson detail / Whiteboard \'97 full-screen PencilKit canvas with Apple\
   Pencil support; lesson info at top; save drawing as PNG locally\
4. Saved drawings (only if time permits) \'97 grid of previously saved drawings\
\
Features:\
- JWT-based authentication against existing backend\
- Real lessons fetched from real backend\
- Apple Pencil drawing via PencilKit (PKCanvasView + PKToolPicker)\
- Local save to documents directory\
- Logout (clears Keychain)\
\
Do not add features beyond this list. Scope creep kills this project.\
\
## Out of Scope (do NOT build)\
- Signup flow (use existing tutor account)\
- Stripe or any payment features\
- Messaging\
- Scheduling or availability editor\
- Reviews\
- Admin features\
- Student-facing screens\
- Uploading drawings to the backend\
- Video calling\
- Polished visual design (clean and functional is enough)\
\
## How I want Claude to help me (CRITICAL)\
This is the most important section. I am not just trying to ship. I am\
trying to LEARN iOS so I can speak about it in an interview.\
\
When writing code:\
- Explain WHY, not just WHAT. Every new SwiftUI concept (for example\
  @State, @StateObject, NavigationStack, .task, EnvironmentObject) needs a\
  2-3 sentence plain-English explanation before or after the code.\
- When you use a new Swift language feature (protocols, optionals,\
  guard/if-let, async/await, Codable, generics), briefly explain it.\
- Point out iOS conventions I might not know (file organization, naming,\
  where view models go, how Apple expects MVVM to be structured in SwiftUI).\
- When there are 2+ ways to do something, briefly mention the alternative\
  and say why we are picking this one. Junior interviewers love\
  "why did you choose X over Y" questions.\
- If I write something that is not idiomatic Swift, tell me.\
- Flag common interview questions as we encounter them: "interview-likely"\
\
When I ask a question:\
- Default to a clear, beginner-level explanation\
- Use the actual code we have written as the example whenever possible\
\
Do NOT:\
- Skip explanations to save time. Explanations ARE the work here.\
- Introduce advanced topics (Combine, async sequences, custom property\
  wrappers, actors, etc.) unless directly relevant.\
- Use SwiftUI features that require iOS 17+ without telling me. My\
  deployment target is iOS 17.\
\
## Stack\
- Language: Swift (latest)\
- UI: SwiftUI (NOT UIKit)\
- iPad-specific: PencilKit for Apple Pencil canvas\
- Networking: URLSession + async/await + Codable (no third-party libs)\
- Token storage: Keychain via Keychain Services\
- Target: iPadOS 17+, iPad only (not Universal)\
- No third-party dependencies. Learning vanilla Apple frameworks is the\
  point of this project.\
\
## Backend (existing, DO NOT MODIFY)\
- Base URL: https://api.academathon.com\
- Login: POST /api/auth/login returns JWT (exact request/response shape to\
  be confirmed when we wire up auth \'97 ask me, do not guess)\
- Lessons: GET endpoint for tutor's lessons (exact path to be confirmed \'97\
  ask me before using)\
- All authenticated endpoints require: Authorization: Bearer <JWT> header\
\
If you do not know an endpoint's exact path, request body, or response\
shape, STOP and ask me. I will paste the real curl example or response.\
Do not invent endpoints or mock data silently.\
\
## Architecture\
Simple MVVM, no over-engineering:\
- SomethingView.swift \'97 the SwiftUI view\
- SomethingViewModel.swift \'97 @MainActor ObservableObject with state +\
  service calls\
- SomethingService.swift \'97 network layer (AuthService, LessonService)\
- Models/ \'97 Codable structs matching backend responses\
\
Junior interview level. No coordinators, no protocol-oriented gymnastics.\
\
## Suggested project structure}