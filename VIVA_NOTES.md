# STREAMFLIX — Comprehensive Viva & Technical Interview Notes

This document contains **28 frequently asked viva questions and beginner-friendly answers** prepared for your external practical examination, project evaluation, and viva voce.

---

## Table of Contents
1. [General & Core Technologies (Q1–Q4)](#1-general--core-technologies)
2. [APIs, Networking & Data Handling (Q5–Q10)](#2-apis-networking--data-handling)
3. [Asynchronous Programming in Dart (Q11–Q13)](#3-asynchronous-programming-in-dart)
4. [Flutter Widgets & State Management (Q14–Q17)](#4-flutter-widgets--state-management)
5. [Local Storage & Persistence (Q18–Q19)](#5-local-storage--persistence)
6. [Feature Implementations in StreamFlix (Q20–Q23)](#6-feature-implementations-in-streamflix)
7. [Deployment & Web Architecture (Q24–Q25)](#7-deployment--web-architecture)
8. [Project Defense, Challenges & Limitations (Q26–Q28)](#8-project-defense-challenges--limitations)

---

## 1. General & Core Technologies

### Q1: What is Flutter?
**Answer:**
Flutter is an open-source UI software development kit (SDK) created by Google. It allows developers to build high-performance, natively compiled applications for Mobile (Android, iOS), Web (Chrome, Safari, Edge), Desktop (Windows, macOS, Linux), and embedded devices from a **single codebase**.

Unlike traditional web frameworks that rely on browser DOM manipulation, Flutter renders UI elements directly onto a Canvas using an optimized graphics engine (CanvasKit / WebGL or Skia), delivering consistent 60+ FPS visuals.

---

### Q2: What is Dart?
**Answer:**
Dart is an object-oriented, class-based, garbage-collected programming language developed by Google. It is the language used to write Flutter applications.

**Key Features of Dart:**
1. **Strong Typing & Sound Null Safety**: Prevents null pointer reference crashes at compile time.
2. **Dual Compilation Modes**:
   - *JIT (Just-In-Time)* during development for instant Hot Reload.
   - *AOT (Ahead-Of-Time)* during production builds for fast machine code execution (compiled to optimized JavaScript/WebAssembly for Flutter Web).
3. **Single-Threaded Event Loop**: Handles asynchronous tasks (like network calls and timers) without multithreading race conditions.

---

### Q3: How does Flutter Web work under the hood?
**Answer:**
When compiling for the Web (`flutter build web --release`), Flutter converts your Dart code into modern JavaScript (`main.dart.js`) and packages it with:
1. **CanvasKit / WebGL engine**: Renders custom UI elements with hardware acceleration.
2. **HTML/CSS fallback**: Handles accessible elements and text.
3. **Web Worker & Service Worker (`flutter_service_worker.js`)**: Caches assets for offline capability and fast load times.

---

### Q4: Why did you choose Flutter over standard React or vanilla HTML/CSS/JavaScript?
**Answer:**
1. **Single Codebase**: The exact same code written for this web application can be built and deployed as an Android APK, iOS app, or Windows desktop executable without rewriting UI logic.
2. **Pixel-Perfect Rendering**: UI looks identical across different browsers because Flutter controls every pixel on the canvas rather than depending on differing browser CSS engines.
3. **Rich Widget Library**: Built-in support for animations, responsive layouts, gestures, and material design out of the box.

---

## 2. APIs, Networking & Data Handling

### Q5: What is an API?
**Answer:**
API stands for **Application Programming Interface**. It is a set of defined rules and communication protocols that allows two software programs to communicate with each other. In StreamFlix, an API acts as a messenger between our Flutter Web frontend and TMDB's remote servers to retrieve real-time movie data.

---

### Q6: What is TMDB?
**Answer:**
TMDB (**The Movie Database**) is a popular, community-built RESTful database for movies and TV shows. It provides free REST API endpoints that return real movie metadata (titles, plot summaries, release dates, user ratings, and poster/backdrop image links).

---

### Q7: How does API integration work in StreamFlix?
**Answer:**
1. Our app initializes an HTTP client using Flutter’s `http` package.
2. A request is dispatched to a specific TMDB REST endpoint (e.g. `https://api.themoviedb.org/3/trending/movie/week?api_key=...`).
3. TMDB processes the request and responds with an HTTP status code (`200 OK`) and a JSON-formatted string body.
4. StreamFlix decodes the string into a Dart `Map<String, dynamic>` using `jsonDecode`.
5. The `Movie.fromJson` factory constructor converts the Map into strongly typed `Movie` Dart objects used to populate the UI.

---

### Q8: What is HTTP GET and what other HTTP methods exist?
**Answer:**
- **HTTP GET**: Used to request and retrieve data from a specified resource without altering server state. In StreamFlix, all TMDB interactions (popular movies, searches, details) use `GET`.
- **Other Common Methods**:
  - `POST`: Submits new data to a server (e.g. creating an account).
  - `PUT / PATCH`: Updates existing data on a server.
  - `DELETE`: Removes a resource from a server.

---

### Q9: What is JSON and what is JSON Parsing?
**Answer:**
- **JSON (JavaScript Object Notation)** is a lightweight, human-readable text format for transmitting structured data between a server and a web application using key-value pairs and arrays.
- **JSON Parsing**: The process of taking a raw JSON string and converting it into in-memory data structures that a programming language can manipulate. In Dart:
  ```dart
  // Raw String -> Dart Map -> Dart Object
  final Map<String, dynamic> data = jsonDecode(response.body);
  final Movie movie = Movie.fromJson(data);
  ```

---

### Q10: How secure is an API key in a static Flutter Web application?
**Answer:**
In client-side single-page applications (including Flutter Web, React, or Angular), any API key bundled into frontend code or transmitted over HTTP requests can be viewed by inspecting browser network developer tools.
- We do **not** claim frontend keys are secret.
- In StreamFlix, we support entering the key at runtime via the app's **"Set API Key"** settings, storing it securely in the user's browser `localStorage`, and adhering to TMDB's public v3 API terms and attribution guidelines.
- In enterprise applications, a backend proxy server (BFF - Backend for Frontend) would be placed between the client and third-party APIs to keep secret tokens completely off the client device.

---

## 3. Asynchronous Programming in Dart

### Q11: What are asynchronous functions?
**Answer:**
Asynchronous functions are operations that run without freezing the main application execution thread while waiting for an external task to finish (e.g. downloading data over the internet or reading from storage). They return control to the event loop immediately and provide the result when ready.

---

### Q12: What is a `Future` in Dart?
**Answer:**
A `Future<T>` represents a computation that does not complete immediately. It is an object that promises to deliver a value of type `T` or an error at some point in the future.
- **Uncompleted State**: The operation is still in progress (e.g. downloading movies).
- **Completed State**: The operation succeeded with data (`Movie`) or failed with an exception (`TmdbApiException`).

---

### Q13: What do `async` and `await` do?
**Answer:**
- `async`: Placed after a function declaration to mark it as asynchronous and enable the use of `await`.
- `await`: Pauses execution inside the async method until the awaited `Future` completes, returning the unwrapped value cleanly without nested callbacks:
  ```dart
  Future<void> fetchMovies() async {
    final response = await client.get(uri); // Pauses only this function
    print(response.statusCode);
  }
  ```

---

## 4. Flutter Widgets & State Management

### Q14: What is the difference between a `StatelessWidget` and a `StatefulWidget`?
**Answer:**
- **`StatelessWidget`**: Immutable widgets whose UI depends solely on initial configuration inputs and never changes dynamically after being built (e.g. `AppNavBar`, `MovieCard` static display, icon tags).
- **`StatefulWidget`**: Widgets that maintain mutable internal state across their lifecycle that can change during runtime (e.g. when fetching API data, toggling categories, or typing in the search bar).

---

### Q15: What is `setState()` and how does it work?
**Answer:**
`setState((){ ... })` is a method available inside a `State` object of a `StatefulWidget`.
When called, it informs the Flutter framework that the widget's internal state has changed. Flutter then schedules a call to the widget's `build()` method, re-evaluating the widget tree and updating only the parts of the screen that changed.

---

### Q16: Why did you not use third-party state managers like Bloc, Riverpod, or Redux?
**Answer:**
For StreamFlix, standard Flutter built-in state management (`StatefulWidget` and `setState`) alongside clean service classes (`TmdbService`, `WatchlistService`) is the most beginner-friendly, readable, and maintainable architecture. It avoids boilerplate code, minimizes dependency bloat, and makes the codebase straightforward to debug and explain during examination.

---

### Q17: What is `BuildContext`?
**Answer:**
`BuildContext` is a reference to the location of a widget within the application's overall widget tree. It is used to look up ancestral information, such as theme data (`Theme.of(context)`), media query screen dimensions (`MediaQuery.of(context)`), and displaying dialogs or SnackBars (`ScaffoldMessenger.of(context)`).

---

## 5. Local Storage & Persistence

### Q18: What is `SharedPreferences` and where does it store data on the Web?
**Answer:**
`SharedPreferences` is a cross-platform plugin for reading and writing simple key-value pairs asynchronously.
- On Android, it writes to XML files.
- On iOS, it writes to `NSUserDefaults`.
- **On Flutter Web, it writes to the browser’s `window.localStorage`**.
Because data resides in `localStorage`, saved watchlist movies and API keys persist across browser refreshes and tab closures.

---

### Q19: How are complex movie objects stored in `SharedPreferences`?
**Answer:**
`SharedPreferences` can only store primitive types (`String`, `int`, `double`, `bool`, `List<String>`).
To store a `List<Movie>`:
1. Each movie object is converted to a map via `movie.toJson()`.
2. The map is encoded to a JSON string via `jsonEncode()`.
3. The resulting list of strings is stored using `prefs.setStringList(key, stringList)`.
4. When loading, each string is parsed with `jsonDecode()` and passed to `Movie.fromJson()`.

---

## 6. Feature Implementations in StreamFlix

### Q20: How are movie posters loaded and how are missing images handled?
**Answer:**
Posters are loaded from TMDB's CDN (`https://image.tmdb.org/t/p/w500/...`) using Flutter's `Image.network` widget.
- **Loading State**: Uses `loadingBuilder` to display a spinning indicator while image bytes download.
- **Fallback / Error Handling**: Uses `errorBuilder`. If an image returns 404, or the poster path is null, or the device is offline, it renders a custom fallback card containing a movie icon and title so no broken links or red errors appear.

---

### Q21: How does movie search work and what is search debouncing?
**Answer:**
When the user types in the search bar:
1. A 400-millisecond countdown timer (`Timer`) starts on every keystroke.
2. If the user types another character before 400ms expires, the timer cancels and restarts (`_debounceTimer?.cancel()`).
3. Once the user pauses typing for 400ms, `tmdbService.searchMovies(query)` executes.
4. Results are displayed in a responsive grid, with dedicated loading and "No results found" empty states.

---

### Q22: How does the Watchlist ("My List") work?
**Answer:**
1. Users click the bookmark icon on any poster, billboard banner, or detail screen.
2. `WatchlistService.addMovie(movie)` or `removeMovie(movieId)` updates local storage.
3. The in-memory watchlist set updates via `setState()`, toggling the bookmark icon between active red and white across the entire app.
4. The "My List" screen displays the saved collection with an item count counter and a one-click remove option.

---

### Q23: What is Responsive Design and how is it achieved in StreamFlix?
**Answer:**
Responsive design ensures an application adapts seamlessly to any screen size—from smartphones ($390\text{px}$) to large desktop monitors ($1440\text{px}+$):
1. **Breakpoints**: We check `MediaQuery.of(context).size.width` to switch between a full desktop top-bar and a mobile hamburger drawer at $850\text{px}$.
2. **Adaptive Grid**: `LayoutBuilder` dynamically computes grid columns:
   - Width $\ge 1200\text{px} \rightarrow 6$ columns
   - Width $\ge 960\text{px} \rightarrow 5$ columns
   - Width $\ge 720\text{px} \rightarrow 4$ columns
   - Width $\ge 480\text{px} \rightarrow 3$ columns
   - Mobile $< 480\text{px} \rightarrow 2$ columns
3. **Flexible & SingleChildScrollView**: Prevents yellow-and-black striped `RenderFlex` overflow errors.

---

## 7. Deployment & Web Architecture

### Q24: How does GitHub Pages hosting work for Flutter Web?
**Answer:**
GitHub Pages is a static site hosting service that serves HTML, CSS, JavaScript, and image assets directly from a GitHub repository:
1. `flutter build web --release --base-href "/<repo-name>/"` compiles the Dart codebase into static web files inside `build/web/`.
2. The contents of `build/web/` are pushed to the `gh-pages` branch.
3. GitHub Pages serves `index.html` at `https://<username>.github.io/<repo-name>/`.

---

### Q25: Why is `--base-href` required when deploying to GitHub Pages?
**Answer:**
By default, Flutter Web assumes the application is hosted at the root domain (`https://domain.com/`, so base href is `/`).
However, GitHub Pages project repositories are hosted in a sub-directory (`https://username.github.io/streamflix/`).
Setting `--base-href "/streamflix/"` tells the browser where to look for assets, scripts (`main.dart.js`), and icons so they don't produce 404 Not Found errors.

---

## 8. Project Defense, Challenges & Limitations

### Q26: What challenges did you face during development and how did you resolve them?
**Answer:**
1. **Responsive Flex Overflow on Mobile**:
   - *Problem*: Nav bar tabs and billboards overflowed on narrow screens (`RenderFlex overflowed by X pixels`).
   - *Solution*: Implemented dynamic width breakpoints ($850\text{px}$), wrapping items in a collapsible bottom sheet menu for mobile and using `LayoutBuilder` for grids.
2. **TMDB Rate Limiting on Rapid Search**:
   - *Problem*: Every keystroke triggered an API request, causing unnecessary network traffic.
   - *Solution*: Implemented 400ms search debouncing using `dart:async`'s `Timer`.
3. **Broken Poster Images for Indie/Older Movies**:
   - *Problem*: Some movie records returned `null` for `poster_path`.
   - *Solution*: Implemented custom `errorBuilder` fallback widgets rendering stylized placeholders.
4. **Data Persistence on Browser Reload**:
   - *Problem*: Adding to watchlist initially only persisted in memory.
   - *Solution*: Integrated `SharedPreferences` with JSON serialization to persist data to browser `localStorage`.

---

### Q27: What are the limitations of this application?
**Answer:**
1. **Client-Side Storage**: The watchlist is stored locally on the user's specific browser. It does not sync across different devices because there is no cloud user authentication system (like Firebase or Supabase).
2. **Video Playback**: StreamFlix discovers movies and provides trailers/synopsis metadata; it does not host full copyrighted movie video streaming.
3. **Client-side API Key**: Due to static hosting, the TMDB key communicates directly from the client browser.

---

### Q28: If you had more time, what future enhancements would you add?
**Answer:**
1. **YouTube Trailer Integration**: Embed official movie trailers using the TMDB video endpoint (`/movie/{id}/videos`).
2. **User Authentication**: Add Firebase Auth or OAuth to synchronize the watchlist across multiple devices.
3. **Movie Filtering by Genre**: Allow multi-genre filtering (e.g. "Action + Sci-Fi") directly in the Movies catalog.
4. **Cast & Crew Section**: Display actor photos and director biographies on the Details screen.
