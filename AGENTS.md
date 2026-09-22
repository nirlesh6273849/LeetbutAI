# AGENTS.md — Master Architecture & Developer Guide for NuCode (Pulse)

Welcome, AI Coding Agent. This document is the single source of truth for the **NuCode (Pulse)** platform. It provides exhaustive context covering the system architecture, complete database schemas, all REST API endpoints, sandboxed execution internals, business domains, frontend state management, local workflows, and strict engineering constraints.

Read this document in its entirety before analyzing, proposing, or modifying any code in this repository.

---

## Table of Contents
1. [System Overview & Architecture](#1-system-overview--architecture)
2. [Repository Layout & Directory Map](#2-repository-layout--directory-map)
3. [Technology Stack & Environment](#3-technology-stack--environment)
4. [Complete Database Schema (Flyway V1–V9)](#4-complete-database-schema-flyway-v1v9)
5. [Complete REST API Specification](#5-complete-rest-api-specification)
6. [Core Subsystems & Architectural Workflows](#6-core-subsystems--architectural-workflows)
   - [A. Sandboxed Code Execution Engine](#a-sandboxed-code-execution-engine)
   - [B. Timed Coding Contests](#b-timed-coding-contests)
   - [C. Assessments & Organization Verification](#c-assessments--organization-verification)
   - [D. Skill Certifications](#d-skill-certifications)
   - [E. Dynamic Translation & Localization Engine](#e-dynamic-translation--localization-engine)
   - [F. Authentication, RBAC & Security](#f-authentication-rbac--security)
7. [Default Seed Data & Credentials](#7-default-seed-data--credentials)
8. [Development & Operational Workflows](#8-development--operational-workflows)
9. [Strict Rules & Pitfalls for Coding Agents](#9-strict-rules--pitfalls-for-coding-agents)

---

## 1. System Overview & Architecture

**NuCode (Pulse)** is a production-grade algorithmic problem solving, timed contest, candidate assessment, and skill certification platform (comparable to LeetCode and HackerRank).

### High-Level Topology
```
┌──────────────────────────────────────────────────────────────┐
│ Browser Client (React 19 + Vite 8 + Tailwind 4 + Monaco)     │
│ http://localhost:3000 (proxied) or http://localhost:5173     │
└──────────────────────────────┬───────────────────────────────┘
                               │ HTTP /api (JWT Bearer Auth)
                               ▼
┌──────────────────────────────────────────────────────────────┐
│ Spring Boot 3.4.3 Backend API (Java 21, port 8080)           │
│ - Security & JWT Filter Chain                                │
│ - REST Controllers & Service Layer                           │
│ - DeepL Translation Client                                   │
│ - Docker Execution Dispatcher (DOCKER_HOST=tcp://runner:2375)│
└───────────────┬──────────────────────────────┬───────────────┘
                │ JDBC                         │ Docker Daemon API
                ▼                              ▼
┌──────────────────────────────┐ ┌─────────────────────────────┐
│ MySQL 8.4 Container          │ │ Docker-in-Docker Runner     │
│ Internal: 3306, Host: 3307   │ │ docker:27-dind (port 2375)  │
│ Flyway Schema (V1 - V9)      │ │ Mounts pulse-execution vol  │
└──────────────────────────────┘ └─────────────────────────────┘
```

---

## 2. Repository Layout & Directory Map

```
LeetbutAI/
├── AGENTS.md                               <-- Root master coding agent guide
├── README.md                               <-- High-level overview pointing to AGENTS.md
├── V4__add_demo_users.sql                  <-- Standalone seed script backup
├── insert_data.sql                         <-- Initial problem dataset queries
│
└── Pulse/                                  <-- Full application workspace
    ├── AGENTS.md                           <-- Subdirectory mirror of this guide
    ├── docker-compose.yml                  <-- Multi-container production-like stack
    ├── .env / .env.example                 <-- Runtime environment variables
    ├── run-local.ps1                       <-- PowerShell local startup script
    ├── run-backend-local.ps1               <-- PowerShell backend-only runner script
    │
    ├── backend/                            <-- Spring Boot 3.4.3 Maven Project
    │   ├── pom.xml
    │   ├── Dockerfile
    │   └── src/main/
    │       ├── java/com/infosys/pulse/
    │       │   ├── PulseApplication.java
    │       │   ├── config/                 <-- SecurityConfig, AppConfig, CorsConfig
    │       │   ├── controller/             <-- REST endpoints (14 controllers)
    │       │   ├── dto/                    <-- Request / Response DTOs & Records
    │       │   ├── entity/                 <-- JPA Hibernate entities
    │       │   ├── execution/              <-- Sandbox runner & multi-language executors
    │       │   │   ├── CodeExecutionService.java
    │       │   │   ├── DockerExecutionService.java
    │       │   │   ├── RunnerGenerator.java
    │       │   │   ├── RunnerGeneratorFactory.java
    │       │   │   ├── JavaExecutor.java / JavaRunnerGenerator.java
    │       │   │   ├── PythonExecutor.java / PythonRunnerGenerator.java
    │       │   │   ├── CppExecutor.java / CppRunnerGenerator.java
    │       │   │   └── JavaScriptExecutor.java / JavaScriptRunnerGenerator.java
    │       │   ├── repository/             <-- Spring Data JPA repositories
    │       │   ├── security/               <-- JWT Provider, Filter, UserDetailsService
    │       │   └── service/                <-- Business services (ContestService, InvitationEmailService, AuthService, ...)
    │       └── resources/
    │           ├── application.properties
    │           ├── application-local.properties
    │           └── db/migration/           <-- Flyway versioned SQL scripts (V1 - V9)
    │
    └── frontend/                           <-- React 19 + Vite 8 Single Page App
        ├── package.json
        ├── vite.config.js                  <-- Includes @tailwindcss/vite plugin
        ├── Dockerfile
        ├── nginx.conf                      <-- Reverse proxy routing /api -> backend:8080
        └── src/
            ├── main.jsx                    <-- App bootstrapper
            ├── App.jsx                     <-- Master route table & role guards
            ├── index.css                   <-- CSS variables, themes & Tailwind directives
            ├── context/
            │   ├── ThemeContext.jsx        <-- Dark / Light theme provider
            │   └── TranslationContext.jsx  <-- DeepL client-side batching hook & cache
            ├── components/
            │   ├── ProtectedRoute.jsx      <-- Guard for any logged-in user
            │   ├── AdminRoute.jsx          <-- Guard for ADMIN role
            │   ├── PublicRoute.jsx         <-- Guard for unauthenticated routes
            │   ├── Leaderboard.jsx         <-- Global / Contest scoreboards
            │   ├── admin/                  <-- Admin control panels (17 components)
            │   └── user/                   <-- User views (17 components)
            └── pages/                      <-- Core route views (ProblemPage, Dashboards, Auth)
```

---

## 3. Technology Stack & Environment

| Component | Technology | Details / Versions |
| --- | --- | --- |
| **Java Runtime** | Java 21 LTS | Eclipse Temurin 21 |
| **Backend Framework** | Spring Boot | 3.4.3 (`spring-boot-starter-web`, `data-jpa`, `security`, `mail`) |
| **Database** | MySQL | 8.4 Server (default DB: `pulse`, port `3306` container, `3307` host) |
| **DB Migrations** | Flyway | `flyway-core`, `flyway-mysql` (Hibernate `ddl-auto=validate`) |
| **Authentication** | JWT | `io.jsonwebtoken:jjwt-api:0.12.6` (HMAC-SHA256, stateless Bearer token) |
| **Code Runner** | Docker-in-Docker | `docker:27-dind` (privileged daemon at `tcp://runner:2375`) |
| **Translation** | DeepL API | Proxy controller via `RestTemplate` (`https://api-free.deepl.com/v2/translate`) |
| **Frontend Runtime** | Node.js / React | React 19.2.8, Vite 8.2.0 |
| **Frontend Styling** | Tailwind CSS | v4.3.3 (`@tailwindcss/vite`), custom design system in `index.css` |
| **Code Editor** | Monaco Editor | `@monaco-editor/react` (Java, Python, C++, JS syntax highlighting) |
| **UI Icons / Alerts** | Lucide / Sonner | `lucide-react` icons, `sonner` toast alerts |
| **Reverse Proxy** | Nginx | Multi-stage build serving built SPA bundle on port 80 (mapped to 3000) |

---

## 4. Complete Database Schema (Flyway V1–V9)

Hibernate is configured with `spring.jpa.hibernate.ddl-auto=validate`. All JPA entity classes must precisely match the tables below.

### Core Tables (`V1__initial_schema.sql`)
- **`users`**:
  - `id` BIGINT AUTO_INCREMENT PRIMARY KEY
  - `name` VARCHAR(255) NOT NULL
  - `username` VARCHAR(255) NOT NULL UNIQUE
  - `email` VARCHAR(255) NOT NULL UNIQUE
  - `password` VARCHAR(255) NOT NULL (BCrypt hashed)
  - `role` VARCHAR(32) NOT NULL (`USER`, `ADMIN`, `ORGANIZATION`)
  - `bio` TEXT, `location` VARCHAR(255), `github` VARCHAR(255), `website` VARCHAR(255)
  - `joined_at` TIMESTAMP NOT NULL
- **`problems`**:
  - `id` BIGINT AUTO_INCREMENT PRIMARY KEY
  - `title` VARCHAR(255) NOT NULL, `slug` VARCHAR(255) NOT NULL UNIQUE
  - `description` TEXT NOT NULL
  - `difficulty` VARCHAR(16) NOT NULL (`EASY`, `MEDIUM`, `HARD`)
  - `function_name` VARCHAR(255) NOT NULL, `return_type` VARCHAR(255) NOT NULL
  - `editorial` TEXT, `time_limit_ms` INT DEFAULT 5000, `memory_limit_mb` INT DEFAULT 512
- **`problem_topics`**, **`problem_constraints`**, **`problem_hints`**: Child tables linked to `problem_id` (CASCADE DELETE).
- **`problem_parameters`**: `id`, `problem_id`, `name`, `type` (e.g., `int[]`, `String`, `int`).
- **`problem_starter_codes`**: `id`, `problem_id`, `language`, `code` (UNIQUE on `problem_id, language`).
- **`test_cases`**:
  - `id` BIGINT AUTO_INCREMENT PRIMARY KEY
  - `problem_id` BIGINT NOT NULL
  - `input` TEXT NOT NULL, `expected_output` TEXT NOT NULL
  - `hidden` BOOLEAN NOT NULL DEFAULT FALSE, `time_limit_ms` INT
- **`submissions`**:
  - `id` BIGINT AUTO_INCREMENT PRIMARY KEY
  - `user_id` BIGINT NOT NULL, `problem_id` BIGINT NOT NULL
  - `code` TEXT NOT NULL, `language` VARCHAR(32) NOT NULL
  - `status` VARCHAR(32) NOT NULL (`ACCEPTED`, `WRONG_ANSWER`, `COMPILATION_ERROR`, `RUNTIME_ERROR`, `TIME_LIMIT_EXCEEDED`, `MEMORY_LIMIT_EXCEEDED`, `INTERNAL_ERROR`)
  - `passed_test_cases` INT DEFAULT 0, `total_test_cases` INT DEFAULT 0
  - `execution_time_ms` BIGINT DEFAULT 0, `memory_mb` DOUBLE, `error_message` TEXT, `submitted_at` TIMESTAMP NOT NULL
- **`submission_results`**: Test-case level breakdown per submission (`submission_id`, `test_case_id`, `status`, `passed`, `actual_output`, `error_message`).
- **`leaderboard_entries`**: `user_id` UNIQUE, `score` BIGINT, `solved_count` INT, `updated_at` TIMESTAMP.

### Contests, Certifications & Assessments (`V5__certifications_assessments_contests.sql`)
- **`certification_tracks`**: `id`, `name`, `description`, `created_at`.
- **`certification_track_problems`**: `track_id`, `problem_id`, `problem_order` (UNIQUE on `track_id, problem_id`).
- **`user_certifications`**: `user_id`, `track_id`, `cert_uuid` VARCHAR(64) UNIQUE, `score` INT, `earned_at` (UNIQUE on `user_id, track_id`).
- **`contests`**: `id`, `host_id`, `title`, `description`, `duration_minutes`, `status` (`DRAFT`, `ACTIVE`, `COMPLETED`), `scheduled_start`, `started_at`, `ended_at`, `created_at`.
- **`contest_problems`**: `contest_id`, `problem_id`, `problem_order`.
- **`contest_participants`**: `contest_id`, `email`, `user_id`, `score`, `problems_solved`, `finished`, `joined_at`.
- **`contest_submissions`**: `contest_id`, `participant_id`, `problem_id`, `code`, `language`, `status`, `passed_test_cases`, `total_test_cases`, `execution_time_ms`, `submitted_at`.
- **`assessments`**: `id`, `host_id`, `title`, `description`, `duration_minutes`, `status` (`DRAFT`, `ACTIVE`, `COMPLETED`), `scheduled_start`, `started_at`, `ended_at`, `created_at`.
- **`assessment_problems`**: `assessment_id`, `problem_id`, `problem_order`.
- **`assessment_participants`**: `assessment_id`, `email`, `user_id`, `score`, `problems_solved`, `finished`, `joined_at`.
- **`assessment_submissions`**: `assessment_id`, `participant_id`, `problem_id`, `code`, `language`, `status`, `passed_test_cases`, `total_test_cases`, `execution_time_ms`, `submitted_at`.

### Organization Verifications & Proctoring (`V6__organization_assessments.sql`)
- **`organization_verifications`**:
  - `id` BIGINT AUTO_INCREMENT PRIMARY KEY, `user_id` BIGINT NOT NULL UNIQUE
  - `organization_name`, `employer_name`, `employer_id`, `additional_information`
  - `business_proof_name`, `business_proof_type`, `business_proof` LONGBLOB NOT NULL
  - `identity_proof_name`, `identity_proof_type`, `identity_proof` LONGBLOB NOT NULL
  - `status` VARCHAR(32) DEFAULT 'PENDING' (`PENDING`, `APPROVED`, `REJECTED`)
  - `rejection_remarks` TEXT, `reviewed_by` BIGINT, `submitted_at` TIMESTAMP, `reviewed_at` TIMESTAMP
- **Assessment Proctoring Columns added to `assessment_participants`**:
  - `invitation_token` VARCHAR(64) NOT NULL UNIQUE
  - `invitation_status` VARCHAR(32) DEFAULT 'PENDING' (`PENDING`, `ACCEPTED`, `DECLINED`)
  - `camera_ready` BOOLEAN DEFAULT FALSE, `microphone_ready` BOOLEAN DEFAULT FALSE, `fullscreen_ready` BOOLEAN DEFAULT FALSE
  - `environment_verified_at` TIMESTAMP, `violation_count` INT DEFAULT 0
- **`assessment_violations`**: `id`, `participant_id`, `violation_type` (e.g., `TAB_SWITCH`, `FULLSCREEN_EXIT`), `details`, `occurred_at`.

### Contest Scheduling, Open Access & Invitation Flags (`V7`–`V9`)
- **`V7__contest_scheduling_and_points.sql`**:
  - `contests.scheduled_end` TIMESTAMP NULL
  - `contest_problems.points` INTEGER NOT NULL DEFAULT 100
- **`V8__contest_allow_all.sql`**:
  - `contests.allow_all` BOOLEAN NOT NULL DEFAULT FALSE (open join without an explicit invite)
- **`V9__contest_notify_everyone.sql`**:
  - `contests.notify_everyone` BOOLEAN NOT NULL DEFAULT FALSE (broadcast invitation emails to all real `USER` accounts)

Current `contests` columns after V5–V9: `id`, `host_id`, `title`, `description`, `duration_minutes`, `status` (`DRAFT`, `ACTIVE`, `COMPLETED`), `allow_all`, `notify_everyone`, `scheduled_start`, `scheduled_end`, `started_at`, `ended_at`, `created_at`.
Current `contest_problems` columns: `id`, `contest_id`, `problem_id`, `problem_order`, `points`.

---

## 5. Complete REST API Specification

### 1. Authentication (`/api/auth`)
| Method | Endpoint | Access | Body / Params | Description |
| --- | --- | --- | --- | --- |
| `POST` | `/api/auth/register` | Public | `{ name, username, email, password }` | Registers user, returns JWT token string |
| `POST` | `/api/auth/login` | Public | `{ email, password }` | Authenticates user, returns JWT token string |
| `POST` | `/api/auth/admin/login` | Public | `{ email, password }` | Authenticates admin, verifies `ADMIN` role |

### 2. User & Profile (`/api/user`)
| Method | Endpoint | Access | Body / Params | Description |
| --- | --- | --- | --- | --- |
| `GET` | `/api/user/profile` | USER | — | Returns current user profile DTO |
| `PUT` | `/api/user/profile` | USER | `{ name, bio, location, github, website }` | Updates profile details |
| `GET` | `/api/user/leaderboard` | USER | — | Returns top users ranked by score and solved count |

### 3. Problems & Execution (`/api/problems`)
| Method | Endpoint | Access | Body / Params | Description |
| --- | --- | --- | --- | --- |
| `GET` | `/api/problems` | USER / ADMIN | — | Lists all available practice problems |
| `GET` | `/api/problems/{id}` | USER / ADMIN | — | Fetches problem details by numeric ID |
| `GET` | `/api/problems/slug/{slug}` | USER / ADMIN | — | Fetches problem details by URL slug |
| `POST` | `/api/problems/{id}/run` | USER / ADMIN | `{ code, language }` | Executes against visible test cases only |
| `POST` | `/api/problems/{id}/submit` | USER / ADMIN | `{ code, language }` | Executes against hidden test cases, updates DB score |
| `POST` | `/api/problems` | ADMIN | `CreateProblemRequest` | Creates a new problem with parameters & starter codes |
| `PUT` | `/api/problems/{id}` | ADMIN | `CreateProblemRequest` | Updates existing problem |
| `DELETE` | `/api/problems/{id}` | ADMIN | — | Deletes problem and cascades to test cases |

### 4. Admin Management (`/api/admin`)
| Method | Endpoint | Access | Body / Params | Description |
| --- | --- | --- | --- | --- |
| `GET` | `/api/admin/dashboard` | ADMIN | — | Aggregated stats: total users, problems, submissions |
| `GET` | `/api/admin/users` | ADMIN | — | Lists non-admin users |
| `DELETE` | `/api/admin/users/{id}` | ADMIN | — | Deletes user account (prevents self-deletion) |
| `GET` | `/api/admin/submissions` | ADMIN | — | Global submission audit log |
| `GET` | `/api/admin/hints?problemId={id}` | ADMIN | — | Gets hints for a problem |
| `POST` | `/api/admin/hints` | ADMIN | `{ problemId, hintText }` | Creates new hint |
| `PUT` | `/api/admin/hints/{hintId}` | ADMIN | `{ hintText }` | Updates hint |
| `DELETE` | `/api/admin/hints/{hintId}` | ADMIN | — | Deletes hint |
| `GET` | `/api/admin/problems/{id}/editorial` | ADMIN | — | Gets editorial solution |
| `PUT` | `/api/admin/problems/{id}/editorial` | ADMIN | `{ editorial }` | Updates editorial solution |

### 5. Contests (`/api/admin/contests` & `/api/user/contests`)
| Method | Endpoint | Access | Description |
| --- | --- | --- | --- |
| `GET` | `/api/admin/contests` | ADMIN | List all contests |
| `POST` | `/api/admin/contests` | ADMIN | Create contest `{ title, description, scheduledStart, scheduledEnd, problems, participantEmails, allowAll, notifyEveryone }` |
| `POST` | `/api/admin/contests/problems` | ADMIN | Create a reusable contest problem (`CreateProblemRequest`) |
| `GET` | `/api/admin/contests/{id}` | ADMIN | Detailed contest admin view |
| `PUT` | `/api/admin/contests/{id}` | ADMIN | Update contest metadata (DRAFT only) |
| `DELETE` | `/api/admin/contests/{id}` | ADMIN | Delete contest |
| `POST` | `/api/admin/contests/{id}/problems` | ADMIN | Add an existing problem `{ problemId, points }` |
| `DELETE` | `/api/admin/contests/{id}/problems/{problemId}` | ADMIN | Remove a problem from a DRAFT contest |
| `POST` | `/api/admin/contests/{id}/participants` | ADMIN | Add a participant `{ email }` and send invitation mail |
| `DELETE` | `/api/admin/contests/{id}/participants/{email}` | ADMIN | Remove a participant from a DRAFT contest |
| `POST` | `/api/admin/contests/{id}/end` | ADMIN | Sets status to `COMPLETED`, records `ended_at` |
| `GET` | `/api/admin/contests/{id}/results` | ADMIN | View full contest leaderboard and submissions |
| `GET` | `/api/user/contests` | USER | List contests user is participating in or available |
| `GET` | `/api/user/contests/{id}` | USER | Contest problem list and participant timer |
| `POST` | `/api/user/contests/{id}/submit` | USER | Submit contest solution `{ problemId, code, language }` |
| `POST` | `/api/user/contests/{id}/complete` | USER | Mark the participant attempt as finished |
| `GET` | `/api/user/contests/{id}/results` | USER | View participant leaderboard and standings |

### 6. Assessments & Proctoring (`/api/user/assessments`)
| Method | Endpoint | Access | Description |
| --- | --- | --- | --- |
| `GET` | `/api/user/assessments` | USER / ORG | List hosted and invited assessments |
| `POST` | `/api/user/assessments` | USER / ORG | Create assessment with time windows & candidate emails |
| `POST` | `/api/user/assessments/problems` | VERIFIED ORG | Create organization-specific assessment problem |
| `GET` | `/api/user/assessments/invitations/{token}` | USER | Candidate checks invitation & instructions |
| `POST` | `/api/user/assessments/invitations/{token}/environment` | USER | Verifies `{ camera, microphone, fullscreen }` |
| `POST` | `/api/user/assessments/{id}/violations` | USER | Records proctoring violation `{ type, details }` |
| `POST` | `/api/user/assessments/{id}/run` | USER | Runs candidate solution on visible tests |
| `POST` | `/api/user/assessments/{id}/submit` | USER | Evaluates candidate submission and updates score |
| `GET` | `/api/user/assessments/{id}/results` | USER / ORG | Candidate scorecard and host report |

### 7. Organization Verifications (`/api/user/organization-verification` & `/api/admin/...`)
| Method | Endpoint | Access | Description |
| --- | --- | --- | --- |
| `GET` | `/api/user/organization-verification` | USER | Get current user's verification status |
| `POST` | `/api/user/organization-verification` | USER | Multipart upload: proofs + company details |
| `GET` | `/api/admin/organization-verifications` | ADMIN | Review list of pending organization applications |
| `PUT` | `/api/admin/organization-verifications/{id}/decision` | ADMIN | Decide `{ decision: 'APPROVE'|'REJECT', remarks }` |
| `GET` | `/api/admin/organization-verifications/{id}/documents/{kind}` | ADMIN | Streams proof document file binary |

### 8. Certifications (`/api/user/certifications` & `/api/admin/certifications`)
| Method | Endpoint | Access | Description |
| --- | --- | --- | --- |
| `GET` | `/api/user/certifications/tracks` | USER | Available tracks and user solve progress |
| `GET` | `/api/user/certifications/earned` | USER | User's claimed certificates with UUIDs |
| `POST` | `/api/user/certifications/tracks/{trackId}/claim` | USER | Verifies all track problems solved, issues certificate |
| `GET` | `/api/user/certifications/certificate/{certUuid}` | Public/USER | Public verification endpoint with certificate details |
| `GET` | `/api/admin/certifications/tracks` | ADMIN | Admin list of all certification tracks |
| `POST` | `/api/admin/certifications/tracks` | ADMIN | Create track `{ name, description, problemIds }` |
| `PUT` | `/api/admin/certifications/tracks/{id}` | ADMIN | Update track details and problem mappings |
| `DELETE` | `/api/admin/certifications/tracks/{id}` | ADMIN | Delete track |
| `GET` | `/api/admin/certifications/tracks/{id}/holders` | ADMIN | View users who have earned this certificate |

### 9. Translation Proxy (`/api/translate`)
| Method | Endpoint | Access | Body / Params | Description |
| --- | --- | --- | --- | --- |
| `POST` | `/api/translate` | Authenticated | `{ texts: ["..."], targetLang: "ES" }` | Proxies batch translation to DeepL API |

---

## 6. Core Subsystems & Architectural Workflows

### A. Sandboxed Code Execution Engine
Located in package `com.infosys.pulse.execution`:
1. **Runner Generators**:
   - `RunnerGeneratorFactory` selects the appropriate generator for the target `Language` (`JAVA`, `PYTHON`, `CPP`, `JAVASCRIPT`).
   - For Java: Generates `Runner.java`, which reads stdin tokens, parses parameter types (`int`, `int[]`, `String`, etc.), executes `Solution.functionName(...)`, and formats output.
   - For Python: Reads token stream with type introspection and executes `Solution().functionName(...)`.
   - For C++: Generates GCC harness with standard `<iostream>`, `<vector>`, `<string>` parsers.
   - For JavaScript: Generates Node.js execution wrapper.
2. **Docker-in-Docker Execution Mechanism**:
   - Spring Boot runs with `DOCKER_HOST=tcp://runner:2375` and `JAVA_TOOL_OPTIONS=-Djava.io.tmpdir=/execution-work`.
   - Both `backend` and `runner` share the Docker volume `pulse-execution` mapped at `/execution-work`.
   - When `Files.createTempDirectory()` is invoked, files (`Solution.java`, `Runner.java`, `input.txt`) are written to `/execution-work/pulse-java-xxx`.
   - Because the path `/execution-work/...` exists identically inside the `runner` container, the runner executes:
     ```bash
     docker run --rm --network none --memory 512m --cpus 1 --pids-limit 64 --ulimit cpu=5 \
       --cap-drop ALL --security-opt no-new-privileges \
       -v /execution-work/pulse-java-xxx:/app eclipse-temurin:17-jdk \
       sh -c "cd /app && javac Solution.java Runner.java && java Runner < input.txt"
     ```
3. **Execution Safety**:
   - Containers are strictly un-networked (`--network none`).
   - Hard limits on CPU, memory (512MB), process IDs (64), and capabilities dropped (`--cap-drop ALL`).
   - Temp directories are cleaned up in a `finally` block via `deleteDirectory()`.

### B. Timed Coding Contests
- Admin schedules contest with `scheduledStart`, `scheduledEnd`, problem set (each with `points`), optional invite whitelist, `allowAll`, and `notifyEveryone`.
- Status is schedule-driven (`ContestService.updateScheduledContestStatuses` every 10s): `DRAFT` becomes `ACTIVE` at `scheduledStart`, `ACTIVE` becomes `COMPLETED` at `scheduledEnd`. There is no manual start endpoint.
- `allowAll` lets any signed-in user join without an explicit invite. `notifyEveryone` is independent: it only controls invitation emails/participant auto-enrollment.
- When `notifyEveryone` is enabled, invitation emails go to all real `USER` accounts (dummy `@example.com` seeds are skipped). Explicit participant emails are still invited even if the toggle is off.
- Newly registered real users are added as participants and emailed only for currently scheduled `DRAFT`/`ACTIVE` contests that have `notifyEveryone` enabled (`AuthService.register` → `ContestService.inviteNewUserToOpenContests`).
- Mail is sent by `InvitationEmailService.sendContestInvitation(...)` and still requires `MAIL_ENABLED` plus a real SMTP host. Dummy/`@example.com` addresses are never mailed.
- Participant enters `/contests/:id`. The countdown timer calculates remaining time from `started_at` until `scheduled_end`.
- Submissions are evaluated via `contestService.submitSolution()`. Scoring rewards early accepted solutions while penalizing failed attempts.
- Live leaderboard is cached and aggregated across all participants.

### C. Assessments & Organization Verification
- Employers apply via `/api/user/organization-verification` providing corporate IDs and proof documents.
- Admin verifies the organization. Once approved, the organization can:
  1. Author private problems via `/api/user/assessments/problems`.
  2. Create timed recruitment assessments.
  3. Send invitations (generating 64-character UUID tokens like `/assessment-invite/:token`).
- Candidates must pass the **Proctoring Environment Check** (webcam, microphone, and browser full-screen lock) before problems unlock.
- Tab switching or exiting full-screen triggers a violation recorded via `/api/user/assessments/{id}/violations`. Multiple violations flag the candidate.

### D. Skill Certifications
- Tracks group cohesive problems (e.g., "Algorithms I", "Dynamic Programming Mastery").
- The system checks if all problems in the track have been solved with status `ACCEPTED`.
- Claiming generates an unforgeable `cert_uuid` stored in `user_certifications` with calculated competency score.
- Publicly verifiable by anyone without login at `/certifications/:certUuid`.

### E. Dynamic Translation & Localization Engine
- **Frontend Hook (`TranslationContext.jsx`)**:
  - Exposes `t(text)` and `language`.
  - **Critical Pure Render Invariant**: `t()` MUST remain a pure lookup function during the React render cycle.
  - If a string is uncached, it is added to a `pendingRef` Set.
  - A decoupled `useEffect` monitors pending entries, debounces them, and dispatches a single batch request to `POST /api/translate`.
  - Translations are stored in a persistent memory cache ref `cacheRef.current[lang][text] = translated`.
  - **Never** schedule `setTimeout` or dispatch state updates directly inside `t()` during render, as this causes infinite re-render loops and icon twitching.

### F. Authentication, RBAC & Security
- Stateless JWT authentication via `JwtAuthenticationFilter`.
- Tokens are extracted from `Authorization: Bearer <token>` and validated using `jwt.secret`.
- Roles:
  - `ROLE_USER`: Practice problems, user contests, certifications, assessments.
  - `ROLE_ADMIN`: User management, problem authoring, global submissions, contest administration, verification decisions.
  - `ROLE_ORGANIZATION`: Sub-tier of verified users allowed to author private problems and manage assessments.
- Passwords hashed using Spring Security `BCryptPasswordEncoder`.

---

## 7. Default Seed Data & Credentials

### Default Administrator Account (Seeded on first migration)
- **Email**: `admin@gmail.com`
- **Password**: `Admin@123`
- **Role**: `ADMIN`

### Demo User Accounts (Seeded via `V4__add_demo_users.sql`)
All demo accounts use the standard password: `Password@123`
| Name | Username | Email |
| --- | --- | --- |
| Alex Turner | `alex_turner` | `alex@example.com` |
| Sarah Connor | `sarah_c` | `sarah@example.com` |
| David Miller | `david_m` | `david@example.com` |
| Emma Watson | `emma_w` | `emma@example.com` |
| Chen Wei | `chen_w` | `chen@example.com` |

---

## 8. Development & Operational Workflows

### 1. Docker Compose (Standard Deployment)
Run from `c:\Projects\LeetbutAI\Pulse`:
```powershell
# Start all containers in background with build
docker compose up --build

# View real-time logs for backend or runner
docker compose logs -f backend
docker compose logs -f runner

# Stop all containers
docker compose down

# Complete clean reset (wipes MySQL data volume)
docker compose down -v
```

### 2. Port Mappings Reference
| Service | Internal Container Port | Host Port | Purpose |
| --- | --- | --- | --- |
| `frontend` | 80 | **3000** | Production Nginx web server & `/api` reverse proxy |
| `backend` | 8080 | **8080** | Direct Spring Boot REST API |
| `mysql` | 3306 | **3307** | MySQL database (accessible via MySQL Workbench/DBeaver) |
| `runner` | 2375 | *internal* | Docker-in-Docker engine communication |

### 3. Local Standalone Development (Without Docker Compose)
If developing locally on Windows:
```powershell
# In Pulse/backend:
.\mvnw.cmd clean test-compile
.\mvnw.cmd spring-boot:run

# In Pulse/frontend:
npm install
npm run dev        # Launches Vite development server on http://localhost:5173
npm run build      # Verifies bundle compilation (MUST pass with 0 errors)
```

---

## 9. Strict Rules & Pitfalls for Coding Agents

1. **PowerShell / Windows Environment**:
   - This workstation runs **Windows** with **PowerShell**.
   - NEVER use bash syntax (`export VAR=val`, `curl | jq`, complex escaped single-quote strings).
   - Use `Invoke-RestMethod` for HTTP calls and standard PowerShell variables (`$env:VAR = 'val'`).
2. **Never Execute Untrusted Code on Host OS**:
   - All code compilation and execution MUST route through `DockerExecutionService` and the runner container. Never call `Runtime.getRuntime().exec()` on the host machine.
3. **Database Migration Rules**:
   - Flyway scripts (`V1` through `V9`) are immutable once applied.
   - Any new schema changes must be placed in a new migration script following the strict sequential naming: `V10__<feature_description>.sql` in `Pulse/backend/src/main/resources/db/migration/`.
   - Entity definitions must strictly mirror DB columns; Hibernate DDL auto is set to `validate`.
4. **React 19 & Context Purity**:
   - Render functions must be strictly pure.
   - Do NOT invoke timeouts, trigger API fetches, or mutate state directly inside helper getters like `t()`.
   - Use `sonner` (`toast.success()`, `toast.error()`) for notifications; avoid browser `alert()`.
5. **API & Controller Structure**:
   - Controllers must remain thin. Place business logic, security validations, and transaction boundaries in `@Service` classes.
   - Always return typed `ResponseEntity<?>` with proper HTTP status codes (`200 OK`, `201 Created`, `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`).
6. **Mandatory Build Verification**:
   - Backend modifications must be verified via:
     `.\mvnw.cmd test-compile` (or `mvn compile`)
   - Frontend modifications must be verified via:
     `npm run build` in `Pulse/frontend`

---
*Keep this document updated whenever new migrations, API endpoints, or services are introduced.*
