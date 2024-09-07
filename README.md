# Flutter Google Maps with notifications and background service

## App Demo

<p align="center">
  <a href="https://github.com/user-attachments/assets/2fcf3a9c-b424-41ec-88bc-03936701d9bf">
    <img src="https://github.com/user-attachments/assets/2fcf3a9c-b424-41ec-88bc-03936701d9bf" alt="App Demo" style="width: 100%; max-width: 1000px; aspect-ratio: 19 / 6;">
  </a>
</p>


## App Overview
This Flutter app provides a feature that tracks the user’s location and sends notifications when nearby gas stations are detected. The app runs location tracking in the background.

## Main Features

### 1. Location Tracking
- The app tracks the user’s location using the `Geolocator` and `Location` packages.
- Periodic location updates are handled in the background using `WorkManager`.
- In the foreground, the app displays the user's current location on a Google Map, along with markers for nearby gas stations.

### 2. Background Task
- The app uses `WorkManager` to execute a background task every 15 minutes that fetches the user's location and checks for nearby gas stations.
- This task runs even when the app is paused or in the background.

### 3. Notifications
- Notifications are implemented using the `AwesomeNotifications` package.
- The app displays notifications for nearby gas stations when detected in background modes.
- A background service notification is shown when the app is running in the background.

### 4. Map Integration
- The app uses the Google Maps API to display the user's location and fetch nearby gas stations using the Places API.
- Polylines are drawn on the map to show routes, and gas stations are marked with custom icons.

## App Lifecycle Management
- The app listens for lifecycle changes using `WidgetsBindingObserver` to handle transitions between foreground and background states.
- When the app enters the background, the background location task is started, and notifications are triggered for nearby gas stations.
- When the app resumes, the background task is canceled, and the background service notification is removed.

## Permissions
The app requests the following permissions at startup:
- **Location Permission:** For tracking the user’s location.
- **Notification Permission:** To display notifications for nearby gas stations.

## Code Structure

- **`main.dart`:** Initializes the app, requests necessary permissions, and sets up notification and location services.
- **`LocationService.dart`:** Manages location tracking, including checking for location permissions and handling location updates.
- **`NotificationService.dart`:** Handles all notification-related tasks, including showing gas station notifications and background service notifications.
- **`MapService.dart`:** Interacts with Google Maps and the Places API to fetch and display nearby gas stations on the map.

## Background Location Task
- The background location task fetches the user's location and checks for nearby gas stations every 15 minutes.
- Notifications are triggered when gas stations are detected.
