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



---

## ⚖️ TMDB Attribution

This product uses the TMDB API but is not endorsed or certified by TMDB.
