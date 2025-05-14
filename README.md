# Flutter Full-Stack CRUD Task Management Module

## Overview

This project is a comprehensive Flutter module demonstrating Create, Read, Update, and Delete (CRUD) operations for tasks. It showcases best practices in Flutter development including a layered architecture, BLoC for state management, local data persistence with SQLite, mock API integration for remote data simulation, responsive UI design, and various advanced features. Key functionalities include task tagging, robust search, multi-criteria sorting, status and tag-based filtering, and dynamic theme switching (Light/Dark) with user preference persistence.

This project was developed to fulfill the requirements of a Flutter full-stack module assignment, emphasizing clean code, maintainability, and a feature-rich user experience.

## Features Implemented

*   **Core Task Management (CRUD):**
    *   Create, Read, Update, and Delete task items.
    *   Tasks include fields for title, description, completion status, creation date, priority level, and comma-separated tags.
*   **Data Persistence & Synchronization:**
    *   Local data caching using **SQLite**, enabling offline access and faster load times.
    *   Schema migration handled for database updates (e.g., adding the `tags` column).
    *   **Mock RESTful API Integration:** Simulates remote data operations using the `http` package and an in-memory mock data source within `TaskRemoteDataSourceImpl`. This allows for testing API interaction patterns without a live backend.
*   **State Management:**
    *   **BLoC (flutter_bloc)** pattern for managing complex task-related state, including search, sort, filter, tagging logic, and responsive UI detail pane state.
    *   **Cubit (flutter_bloc)** for managing the application-wide theme (Light/Dark mode).
*   **User Interface (UI) & User Experience (UX):**
    *   Dedicated screens for listing, adding, and editing tasks.
    *   **Responsive Layout:**
        *   Single-pane view for task list and forms on narrow screens (phones).
        *   Two-pane (master-detail) view on wider screens (tablets/web/desktop) for the `TaskListScreen`, displaying the task list and task form/details side-by-side.
    *   Intuitive task display using custom `TaskCard` widgets.
    *   Forms with input validation for adding/editing tasks (`TaskFormScreen`).
    *   Swipe-to-delete functionality on task list items.
    *   User feedback via themed Snackbars, loading indicators, and clear error messages.
    *   Network status banner indicating offline/online connectivity.
*   **Advanced Task Functionality:**
    *   **Search:** Real-time client-side search for tasks by title or description, featuring debounce logic (using `rxdart`) to optimize performance.
    *   **Sorting:** Tasks can be sorted by Priority (High-Low, Low-High), Creation Date (Newest First, Oldest First), or Title (A-Z, Z-A) via an AppBar menu.
    *   **Filtering:**
        *   Filter tasks by completion status (All, Completed, Incomplete) via an AppBar menu.
        *   Filter tasks by user-defined tags via an AppBar menu, with an option to clear the tag filter.
    *   **Tagging:** Users can assign multiple comma-separated tags to tasks. Tags are displayed on task cards.
*   **Theming:**
    *   **Dark/Light Mode Switching:** Users can toggle between light and dark themes via an AppBar action icon.
    *   Theme preference is persisted locally using `shared_preferences`.
    *   Custom `ThemeData` defined for both light and dark modes for a consistent and accessible look and feel, utilizing Material 3 principles.
*   **Technical Implementation Details:**
    *   **Layered Architecture:** Clear separation into Presentation, Business Logic (BLoC/Cubit), and Data (Repositories/Data Sources) layers.
    *   **Repository Pattern:** `TaskRepository` abstracts data sources, handling logic for fetching from remote or local based on network status.
    *   **Dependency Injection:** Using `get_it` for managing and providing dependencies throughout the application.
    *   Network Connectivity Handling: `connectivity_plus` used to check network status, reflected in UI and repository logic.
    *   JSON serialization/deserialization implemented manually in data models.
    *   Structured debug logging using the `logger` package.
*   **Testing:**
    *   Unit tests for `TaskBloc` covering various events, state transitions, and interactions with filters/sorts.
    *   Unit tests for `ThemeCubit` testing theme loading from preferences and toggling.
    *   Unit tests for `TaskRepositoryImpl` for basic online/offline data fetching and mutation scenarios.
    *   A widget test for `TaskListScreen` verifying basic UI rendering with mocked dependencies.

## Architecture

The application follows a clean, layered architecture to promote separation of concerns and maintainability:

1.  **Presentation Layer:** (Located in `lib/presentation/`)
    *   Contains UI elements: Screens (`TaskListScreen`, `TaskFormScreen`) and reusable Widgets (`TaskCard`, `PrioritySelector`, `NetworkStatusBanner`, `LoadingIndicator`, `ErrorMessageWidget`).
    *   Interacts with the Business Logic Layer via BLoCs/Cubits.
2.  **Business Logic Layer (BLL):** (Located in `lib/presentation/bloc/`, `lib/presentation/theme_cubit/`)
    *   Contains `TaskBloc` (for task operations) and `ThemeCubit` (for theme management). These manage application state, user interactions, and business rules.
    *   Orchestrates calls to the Data Layer via Repositories.
3.  **Data Layer:** (Located in `lib/data/`)
    *   **Repositories:** (`TaskRepositoryImpl` implementing `TaskRepository`) Abstracts data sources. It decides whether to fetch data from a remote source or local cache based on network availability and manages caching of remote data.
    *   **Data Sources:**
        *   `TaskLocalDataSourceImpl`: Manages all interactions with the SQLite database (creating schema, CRUD operations).
        *   `TaskRemoteDataSourceImpl`: Simulates interactions with a remote REST API using an in-memory store for demonstration purposes.
    *   **Models:** (`Task`) Defines the data structure for task items, including methods for JSON and database map conversion.
4.  **Core Layer:** (Located in `lib/core/`)
    *   Contains utilities, constants, error/failure definitions, network information, and dependency injection setup.

**Dependency Injection:** The `get_it` package is utilized for service location, making dependencies (like repositories, data sources, BLoCs, Cubits) easily available and facilitating testability (setup in `lib/core/di/injector.dart`).

## How to Run

1.  **Clone the repository:**
    ```bash
    git clone <your-repository-url>
    cd <project-directory-name>
    ```
2.  **Ensure Flutter SDK is installed and configured.** (This project was developed targeting Flutter SDK `'>=3.0.0 <4.0.0'`).
3.  **Get dependencies:** From the project root directory in your terminal, run:
    ```bash
    flutter pub get
    ```
4.  **Run the application:**
    ```bash
    flutter run
    ```
    The application can be run on an Android emulator/device, iOS simulator/device, or as a web/desktop application (ensure the target platform is enabled in your Flutter setup). On the first run on a mobile device, if a database schema migration is needed (e.g., due to the `tags` column addition), uninstalling any previous version of this app from the device might be necessary for the `onCreate` database logic to execute cleanly.

## Key Packages Used

*   **State Management:**
    *   `flutter_bloc: ^8.1.3`
    *   `equatable: ^2.0.5`
*   **Dependency Injection:**
    *   `get_it: ^7.6.4`
*   **Data & Networking:**
    *   `http: ^1.1.0` (for mock API calls)
    *   `sqflite: ^2.3.0` (local SQLite database)
    *   `path_provider: ^2.1.1` (for finding database path)
    *   `path: ^1.8.3` (for joining paths)
    *   `shared_preferences: ^2.2.2` (for theme persistence)
    *   `connectivity_plus: ^5.0.2` (for network status)
*   **Utilities:**
    *   `uuid: ^4.2.1` (for generating unique Task IDs)
    *   `intl: ^0.18.1` (for date formatting)
    *   `either_dart: ^1.0.0` (for functional error handling)
    *   `rxdart: ^0.27.7` (for debounce in search)
    *   `logger: ^2.0.2+1` (for structured logging)
*   **UI:**
    *   `cupertino_icons: ^1.0.6`
*   **Testing:**
    *   `flutter_test` (from SDK)
    *   `bloc_test: ^9.1.5`
    *   `mocktail: ^1.0.1`
*   **Linting:**
    *   `flutter_lints: ^3.0.1`

## Database Schema (SQLite - `tasks` table - Version 2)

*   `id`: TEXT PRIMARY KEY
*   `title`: TEXT NOT NULL
*   `description`: TEXT
*   `isCompleted`: INTEGER NOT NULL (0 for false, 1 for true)
*   `createdDate`: TEXT NOT NULL (ISO 8601 String, e.g., "2023-10-27T10:00:00.000Z")
*   `priority`: TEXT NOT NULL (Stored as string: "low", "medium", "high")
*   `tags`: TEXT DEFAULT '' (Comma-separated string, e.g., "work,urgent")

Indexes are created on `isCompleted`, `priority`, and `tags` columns for query optimization. Database versioning and upgrades (like adding the `tags` column) are handled by `TaskLocalDataSourceImpl` using `onUpgrade`.

## Testing

The project includes a suite of unit tests and a basic widget test to ensure code quality and correctness:

*   **Unit Tests:**
    *   `ThemeCubit`: Testing theme loading from preferences and theme toggling.
    *   `TaskBloc`: Covering various events like loading tasks, adding, searching, filtering by completion status and tags, sorting, and handling responsive detail pane selections.
    *   `TaskRepositoryImpl`: Testing data fetching logic for online/offline scenarios and basic mutation operations.
*   **Widget Tests:**
    *   `TaskListScreen`: Basic test verifying the rendering of key UI elements with mocked BLoC/Cubit dependencies.

To run all tests:
```bash
flutter test
```

## Known Limitations / Future Improvements

- **Mock Remote API**: The application currently uses an in-memory mock for its remote data source. For a production application, this would need to be replaced with integration to a live backend API.

- **Offline Write Operations**: While tasks can be read from the local cache when offline, write operations (add, update, delete) are currently designed to attempt remote calls and will fail if offline. A robust offline mutation queue with a sync mechanism would be a significant enhancement for true offline-first capability.

- **Error Handling Granularity**: User-facing error messages are functional but could be improved with more specific details and context-sensitive recovery options.

- **Advanced Responsive Details**: 
  - The `TaskFormScreen`, when navigated to as a standalone screen on narrow devices, could benefit from further responsive refinements.
  - The two-pane layout in `TaskListScreen` could be enhanced with features like a resizable divider.

- **User Authentication**: No user authentication or multi-user support is implemented. This would be essential for production scenarios involving user data segregation and access control.

- **Comprehensive Test Coverage**: While foundational tests are in place, test coverage could be expanded—especially for:
  - Complex UI interactions  
  - Edge cases in data sources  
  - Combinations of filters and sort options

- **Data Import/Export**: This feature was considered but not included in the final scope of this iteration. It could be added to allow users to back up or transfer their task data.
