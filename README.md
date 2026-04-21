# HelpDesk E-Ticketing App — Flutter Frontend

A production-ready Flutter frontend for an E-Ticketing Helpdesk system, built with clean architecture and Material 3 design.

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point, routing, theme switching
├── models/
│   └── ticket_model.dart        # Ticket, Comment, AppUser, enums (TicketStatus, UserRole)
├── providers/
│   └── app_provider.dart        # ChangeNotifier: auth, tickets, theme state
├── services/
│   └── dummy_data_service.dart  # Hardcoded dummy users & tickets
├── theme/
│   └── app_theme.dart           # Light/dark ThemeData + status color helpers
├── widgets/
│   ├── status_badge.dart        # Colored status pill (Open / In Progress / Done)
│   ├── ticket_card.dart         # Reusable ticket list card with category + status
│   └── shimmer_card.dart        # Shimmer skeleton for cards and stat boxes
└── screens/
    ├── splash_screen.dart       # Animated logo + auto-navigate to login
    ├── login_screen.dart        # Role selector + username/password login
    ├── home_screen.dart         # Bottom nav shell (Dashboard / Tiket / Profil)
    ├── dashboard_screen.dart    # Greeting, stat grid, quick actions, recent tickets
    ├── ticket_list_screen.dart  # Tabbed list (All / Open / Progress / Done) + search
    ├── ticket_detail_screen.dart# Full detail, image, chat-style comments, status update
    ├── create_ticket_screen.dart# Form: title, category chips, description, mock upload
    └── profile_screen.dart      # User info, stats, dark-mode toggle, logout
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0

### Installation

```bash
# 1. Navigate into the project
cd helpdesk_app

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

### Dependencies

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.1 | State management |
| `intl` | ^0.19.0 | Date formatting |
| `shimmer` | ^3.0.0 | Loading skeleton animations |
| `flutter_animate` | ^4.5.0 | Page & widget animations |
| `cached_network_image` | ^3.3.1 | Network image caching |
| `google_fonts` | ^6.2.1 | Plus Jakarta Sans typography |

---

## 🔐 Demo Login Credentials

| Role | Username | Password |
|---|---|---|
| User | `user` | `password` |
| Helpdesk | `helpdesk` | `password` |
| Admin | `admin` | `password` |

Use the role selector on the login screen — it pre-fills the username automatically.

---

## 🎨 Design System

| Token | Value |
|---|---|
| Primary | `#1565C0` (blue) |
| Font | Plus Jakarta Sans |
| Border Radius | 12–16px |
| Card Style | Flat with 1px border |
| Status — Open | Red `#EF5350` |
| Status — In Progress | Orange `#FF9800` |
| Status — Done | Green `#43A047` |

---

## 📱 Screens Overview

### Splash Screen
- App logo with scale + fade animation
- Circular progress indicator
- Auto-navigates to Login after 2.8s

### Login Screen
- Role selector (User / Helpdesk / Admin) pre-fills username
- Password visibility toggle
- Error banner with hint text
- Loading state on submit

### Dashboard
- Gradient header with user greeting and role badge
- 4-card stats grid (Total / Open / In Progress / Done) with shimmer loading
- Quick Action buttons (User only)
- Recent tickets list (latest 4), shimmer on initial load
- Pull-to-refresh

### Ticket List
- 4 tabs: Semua / Open / In Progress / Done with counts
- Live search (title / ID filter)
- Empty state with icon when no results
- Shimmer on first load

### Ticket Detail
- Network image with loading indicator
- Info card (creator, date, assigned agent)
- Full description
- Chat-style comment thread (left = others, right = current user)
- Role-colored author badges (User / Helpdesk / Admin)
- Send comment with keyboard action
- Admin/Helpdesk: Update Status & Assign via bottom sheets (popup menu)

### Create Ticket
- Validated form (title + description required)
- Category filter chips (Hardware / Software / Network / General)
- Mock image upload area (tap to toggle preview)
- Submit with loading state
- Success dialog with generated ticket ID

### Profile
- Gradient header with avatar, name, email, role badge
- Stats row (Total / Open / In Progress / Done)
- Account info section
- Settings section with **Dark/Light mode toggle**
- Logout with confirmation dialog

---

## ⚙️ Role-Based UI

| Feature | User | Helpdesk | Admin |
|---|---|---|---|
| See own tickets only | ✅ | ❌ | ❌ |
| See all tickets | ❌ | ✅ | ✅ |
| Create ticket (FAB) | ✅ | ❌ | ❌ |
| Update ticket status | ❌ | ✅ | ✅ |
| Assign ticket | ❌ | ✅ | ✅ |
| Add comments | ✅ | ✅ | ✅ |

---

## 🔌 Backend Integration Notes

This project is frontend-only with dummy data. To connect a real backend:

1. **Replace** `DummyDataService` calls in `AppProvider` with HTTP calls (e.g., `http` or `dio` package)
2. **Add** token storage (`flutter_secure_storage`)
3. **Replace** `provider.login()` with a real auth endpoint
4. **Add** `FutureProvider` or `StreamProvider` for real-time ticket updates
5. **Replace** mock image upload with `image_picker` + multipart form upload

The architecture is designed for this transition — `AppProvider` is the single data layer that screens never reach around.
