# StreamFlix — Movie Discovery Web Application

A responsive, Netflix-inspired movie discovery web application built completely with **Flutter Web**, **Dart**, and **The Movie Database (TMDB) REST API**.

---

## 🌟 Key Features

- **Netflix Dark Aesthetic**: Clean dark canvas (`#141414`), Netflix red accent (`#E50914`), modern typography, and hover effects.
- **Featured Billboard Banner**: Dynamic hero banner showcasing high-resolution backdrop art, rating badge, year, genres, plot overview, and quick actions.
- **Real-Time TMDB Catalogs**:
  - Trending movies this week
  - Popular movies
  - Top-rated classics & hits
  - Upcoming releases
- **Responsive Multi-Column Grid**: Dynamic column layout ($2$ to $6$ columns) calculated using `LayoutBuilder`.
- **Instant Search with Debouncing (400ms)**: Real-time search with popular keyword suggestions, loading spinners, and empty states.
- **Movie Details Modal**: Full view with backdrop, large poster card, runtime, genre chips, plot synopsis, and watchlist action.
- **Persistent "My List" Watchlist**: Local storage persistence via `SharedPreferences` (browser `localStorage`), surviving browser refreshes without an external backend.
- **24 Passing Automated Tests**: Comprehensive unit, widget, and responsive layout test suites.

---

## 🚀 Running Locally

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.47.x or higher)
- Google Chrome or any modern web browser

### Steps
1. Navigate to the project directory:
   ```bash
   cd streamflix
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run automated tests:
   ```bash
   flutter test
   ```
4. Run in Chrome:
   ```bash
   flutter run -d chrome
   ```
5. *(Optional)* Pass your TMDB API Key at build time:
   ```bash
   flutter run -d chrome --dart-define=TMDB_API_KEY=your_tmdb_api_key
   ```
   *(Or click the **"Set API Key"** button in the top navigation bar to configure it directly in the UI)*.

---

## 🌐 Deploying to GitHub Pages

### Method 1: Using the Included GitHub Actions Workflow (Recommended)
This repository includes an automated deployment workflow (`.github/workflows/deploy.yml`):
1. Create a repository on GitHub named `streamflix`.
2. Connect your local git repository and push:
   ```bash
   git remote add origin https://github.com/<your-username>/streamflix.git
   git push -u origin main
   ```
3. In GitHub, go to **Settings** $\rightarrow$ **Pages**.
4. Under **Build and deployment**, select **Deploy from a branch**.
5. Set branch to `gh-pages` and folder to `/(root)`, then save.
6. Your live website will be live at:
   ```text
   https://<your-username>.github.io/streamflix/
   ```

### Method 2: Manual Build & Deployment
1. Build the production release with your repository's base href:
   ```bash
   flutter build web --release --base-href "/streamflix/"
   ```
2. Deploy the `build/web/` folder to GitHub Pages:
   ```bash
   cd build/web
   git init
   git add -A
   git commit -m "Deploy StreamFlix to GitHub Pages"
   git branch -M gh-pages
   git remote add origin https://github.com/<your-username>/streamflix.git
   git push -u origin gh-pages --force
   ```

---

## 📚 Viva & Examination Preparation

For comprehensive viva preparation, refer to [VIVA_NOTES.md](VIVA_NOTES.md) which contains **28 structured questions and beginner-friendly answers** covering Flutter architecture, REST APIs, JSON parsing, asynchronous Dart, local storage, responsive design, and project defense.

---

## ⚖️ TMDB Attribution

This product uses the TMDB API but is not endorsed or certified by TMDB.
