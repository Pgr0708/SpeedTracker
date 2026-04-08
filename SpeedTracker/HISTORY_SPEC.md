# History Specification

Complete specification for trip and pedometer history features.

## Overview

History provides users with:
- **Driving History**: Past trips with routes, stats, and maps (Premium)
- **Pedometer History**: Walking/running sessions (Premium)
- **Free Tier Preview**: Last 5 trips to demonstrate value

---

## Trip History (Driving)

### Access Levels

**Free Tier**:
- View last 5 trips only
- Basic trip information (no maps, no graphs)
- Read-only
- Upgrade banner prominent

**Premium Tier**:
- Unlimited trip history
- Full trip details with maps
- Speed and altitude graphs
- Export capability
- Search and filter
- Delete trips

### Trip List Screen

#### UI Layout

**Header**:
- Title: "Trip History"
- Search bar (Premium only)
- Filter button (Premium only)
- Sort button

**Trip List**:
- Sorted by date (newest first) by default
- Card-based design
- Infinite scroll (Premium)
- Limited to 5 cards (Free)

**Upgrade Banner** (Free users):
- Position: Below 5th trip
- Message: "Unlock unlimited history and detailed maps"
- CTA: "Upgrade to Premium"

#### Trip Card Design

Each trip card displays:

```
┌─────────────────────────────────────┐
│ 📍 Today, 2:45 PM                   │
│                                     │
│ Main St → Elm Ave                  │
│                                     │
│ 🕐 45 min    📏 23.5 mi    ⚡ 31 mph │
│                                     │
│ [Premium: Mini map thumbnail]      │
└─────────────────────────────────────┘
```

**Fields**:
- **Icon**: 📍 or 🚗
- **Date/Time**: "Today, 2:45 PM" or "Jan 15, 10:30 AM"
- **Route**: "Start Address → End Address" (geocoded)
- **Duration**: "45 min" or "1h 23m"
- **Distance**: "23.5 mi" (respects user's distance unit)
- **Avg Speed**: "31 mph" (respects user's speed unit)
- **Map Preview** (Premium): Small thumbnail of route

**Interaction**:
- Tap card → Open trip detail
- Swipe left → Delete (confirmation required)

#### Empty State

If no trips recorded:

```
┌─────────────────────────────────────┐
│          🚗                         │
│                                     │
│    No Trips Yet                     │
│                                     │
│ Start driving to record your first │
│ trip automatically                  │
│                                     │
│ [Start Driving]                     │
└─────────────────────────────────────┘
```

**Button**: Opens Home screen (speed tracking)

#### Implementation

```swift
struct TripHistoryView: View {
    @StateObject private var viewModel = TripHistoryViewModel()
    @State private var showingFilter = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if isPremium {
                    SearchBar(text: $searchText)
                }
                
                if viewModel.trips.isEmpty {
                    EmptyTripHistoryView()
                } else {
                    List {
                        ForEach(displayedTrips) { trip in
                            NavigationLink(destination: TripDetailView(trip: trip)) {
                                TripCardView(trip: trip)
                            }
                        }
                        .onDelete(perform: deleteTrip)
                        
                        if !isPremium && viewModel.trips.count > 5 {
                            UpgradeBanner()
                        }
                    }
                }
            }
            .navigationTitle("Trip History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Sort by Date") { sortByDate() }
                        Button("Sort by Distance") { sortByDistance() }
                        Button("Sort by Duration") { sortByDuration() }
                        if isPremium {
                            Button("Filter...") { showingFilter = true }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
    
    var displayedTrips: [Trip] {
        let filtered = searchText.isEmpty ? viewModel.trips : viewModel.trips.filter { trip in
            trip.startAddress.localizedCaseInsensitiveContains(searchText) ||
            trip.endAddress.localizedCaseInsensitiveContains(searchText)
        }
        
        return isPremium ? filtered : Array(filtered.prefix(5))
    }
}
```

### Trip Detail Screen (Premium)

Full-screen detailed view of a single trip.

#### Sections

**1. Header**:
- Date and time
- Duration badge
- Share button (top-right)
- Delete button (trash icon)

**2. Map Section**:
- Apple Maps with route polyline
- Start marker (green pin) with address
- End marker (red pin) with address
- Full-screen map button
- Route color: Blue

**3. Stats Grid**:
```
┌──────────────┬──────────────┬──────────────┐
│   Duration   │   Distance   │  Avg Speed   │
│   45 min     │   23.5 mi    │   31 mph     │
├──────────────┼──────────────┼──────────────┤
│  Max Speed   │   Altitude   │  Coordinates │
│   68 mph     │   1,234 ft   │  37.7, -122  │
└──────────────┴──────────────┴──────────────┘
```

**4. Speed Graph**:
- Title: "Speed Over Time"
- Line chart
- X-axis: Time (HH:MM)
- Y-axis: Speed (in user's unit)
- Highlight max speed point
- Tap to see exact speed at any point
- Expandable to full-screen

**5. Altitude Graph**:
- Title: "Elevation Profile"
- Area chart
- X-axis: Distance
- Y-axis: Altitude (ft or m)
- Gradient fill

**6. Details Section**:
- Starting Address (full)
- Ending Address (full)
- Starting Coordinates
- Ending Coordinates
- GPS Accuracy (average)
- Date and Time (full format)

**7. Actions Section**:
- Export Trip Data (button)
- Share Trip Summary (button)
- Delete Trip (button, destructive)

#### Map Implementation

```swift
struct TripMapView: View {
    let trip: Trip
    @State private var region: MKCoordinateRegion
    
    init(trip: Trip) {
        self.trip = trip
        self._region = State(initialValue: trip.mapRegion)
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: trip.markers) { marker in
            MapAnnotation(coordinate: marker.coordinate) {
                Image(systemName: marker.isStart ? "mappin.circle.fill" : "flag.fill")
                    .foregroundColor(marker.isStart ? .green : .red)
            }
        }
        .overlay(
            RoutePolyline(coordinates: trip.routeCoordinates)
        )
        .frame(height: 300)
        .cornerRadius(12)
    }
}

struct RoutePolyline: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) { }
}
```

#### Speed Graph Implementation

```swift
import Charts

struct SpeedGraphView: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Speed Over Time")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(trip.speedPoints) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Speed", point.speed.toUserUnit())
                )
                .foregroundStyle(.blue)
                
                // Highlight max speed
                if point.speed == trip.maxSpeed {
                    PointMark(
                        x: .value("Time", point.timestamp),
                        y: .value("Speed", point.speed.toUserUnit())
                    )
                    .foregroundStyle(.red)
                    .symbolSize(100)
                }
            }
            .frame(height: 200)
            .padding()
        }
    }
}
```

#### Export Trip Data

Exports trip as JSON or GPX format:

**JSON Format**:
```json
{
  "id": "trip-uuid",
  "startDate": "2026-04-08T14:30:00Z",
  "endDate": "2026-04-08T15:15:00Z",
  "duration": 2700,
  "distance": 37842.5,
  "averageSpeed": 14.01,
  "maxSpeed": 30.56,
  "startAddress": "123 Main St, City",
  "endAddress": "456 Elm Ave, City",
  "route": [
    {"lat": 37.7749, "lon": -122.4194, "timestamp": "...", "speed": 0},
    ...
  ]
}
```

**GPX Format** (for GPS apps):
```xml
<?xml version="1.0"?>
<gpx version="1.1">
  <trk>
    <name>Speed Tracker Trip</name>
    <trkseg>
      <trkpt lat="37.7749" lon="-122.4194">
        <time>2026-04-08T14:30:00Z</time>
        <speed>0</speed>
      </trkpt>
      ...
    </trkseg>
  </trk>
</gpx>
```

**Share Options**:
- Save to Files
- AirDrop
- Email
- Share to other apps

### Search & Filter (Premium)

#### Search

- Real-time search as user types
- Search by:
  - Starting address
  - Ending address
  - Date

#### Filter

Filter sheet with options:

**Date Range**:
- Today
- Last 7 days
- Last 30 days
- Custom range (date picker)

**Distance**:
- Under 10 miles
- 10-50 miles
- 50-100 miles
- Over 100 miles

**Duration**:
- Under 30 min
- 30-60 min
- 1-2 hours
- Over 2 hours

**Apply Filters** (button)

**Implementation**:
```swift
struct FilterView: View {
    @Binding var filters: TripFilters
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Date Range") {
                    Picker("Range", selection: $filters.dateRange) {
                        Text("Today").tag(DateRange.today)
                        Text("Last 7 Days").tag(DateRange.week)
                        Text("Last 30 Days").tag(DateRange.month)
                        Text("Custom").tag(DateRange.custom)
                    }
                    
                    if filters.dateRange == .custom {
                        DatePicker("From", selection: $filters.startDate, displayedComponents: .date)
                        DatePicker("To", selection: $filters.endDate, displayedComponents: .date)
                    }
                }
                
                Section("Distance") {
                    Picker("Distance", selection: $filters.distance) {
                        Text("All").tag(DistanceFilter.all)
                        Text("Under 10 mi").tag(DistanceFilter.short)
                        Text("10-50 mi").tag(DistanceFilter.medium)
                        Text("50-100 mi").tag(DistanceFilter.long)
                        Text("Over 100 mi").tag(DistanceFilter.veryLong)
                    }
                }
                
                Section("Duration") {
                    Picker("Duration", selection: $filters.duration) {
                        Text("All").tag(DurationFilter.all)
                        Text("Under 30 min").tag(DurationFilter.short)
                        Text("30-60 min").tag(DurationFilter.medium)
                        Text("1-2 hours").tag(DurationFilter.long)
                        Text("Over 2 hours").tag(DurationFilter.veryLong)
                    }
                }
            }
            .navigationTitle("Filter Trips")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
```

---

## Pedometer History (Premium)

Similar structure to trip history but for walking/running sessions.

### Pedometer Session Card

```
┌─────────────────────────────────────┐
│ 🏃 Today, 7:30 AM                   │
│                                     │
│ Morning Walk                        │
│                                     │
│ 👣 5,234    📏 2.5 mi    🔥 185 cal │
│                                     │
│ Goal: 10,000 steps (52% complete)  │
└─────────────────────────────────────┘
```

**Fields**:
- **Icon**: 🏃 or 🚶 (based on activity type)
- **Date/Time**: "Today, 7:30 AM"
- **Title**: "Morning Walk" (auto-generated or user-named)
- **Steps**: "5,234 steps"
- **Distance**: "2.5 mi"
- **Calories**: "185 cal"
- **Goal Progress**: Bar or percentage

### Pedometer Detail Screen

**Stats**:
- Steps
- Distance
- Duration
- Average pace (min/mile or min/km)
- Calories burned
- Average speed
- Step goal
- Goal achievement status

**No Map** (pedometer doesn't track route)

**Graph**:
- Steps per minute over time
- Pace graph

**Actions**:
- Export session data
- Delete session

---

## Auto-Save Logic

### Trip Auto-Save

**Start Conditions**:
- Speed > 3 mph (5 km/h)
- Continues for at least 10 seconds

**End Conditions**:
- Speed = 0 for 5+ minutes
- App closed/backgrounded for 10+ minutes
- Manual stop (future feature)

**Save Trigger**:
- When session ends, automatically save trip
- Show notification (if enabled): "Trip saved: 23.5 mi, 45 min"

**Implementation**:
```swift
class TripRecorder: ObservableObject {
    @Published var isRecording = false
    private var currentTrip: Trip?
    private var lastMovementTime: Date?
    
    func locationDidUpdate(location: CLLocation) {
        let speed = location.speed
        
        if speed > 1.34 { // 3 mph in m/s
            if !isRecording {
                startTrip(at: location)
            }
            lastMovementTime = Date()
            recordPoint(location)
        } else if isRecording {
            checkForSessionEnd()
        }
    }
    
    func checkForSessionEnd() {
        guard let lastMovement = lastMovementTime else { return }
        
        let timeSinceMovement = Date().timeIntervalSince(lastMovement)
        
        if timeSinceMovement >= 300 { // 5 minutes
            endTrip()
        }
    }
    
    func startTrip(at location: CLLocation) {
        currentTrip = Trip(userID: currentUserID, startDate: Date())
        currentTrip?.startLatitude = location.coordinate.latitude
        currentTrip?.startLongitude = location.coordinate.longitude
        isRecording = true
    }
    
    func endTrip() {
        guard let trip = currentTrip, trip.isValid else { return }
        
        trip.endDate = Date()
        trip.duration = trip.endDate.timeIntervalSince(trip.startDate)
        
        // Geocode addresses
        geocodeLocations(for: trip)
        
        // Save to Core Data
        saveTrip(trip)
        
        // Sync to iCloud
        if isPremium {
            syncToCloud(trip)
        }
        
        // Send notification
        if notificationsEnabled {
            sendTripCompletedNotification(trip)
        }
        
        currentTrip = nil
        isRecording = false
    }
}
```

### Pedometer Auto-Save

**Manual Start/Stop** (not automatic):
- User taps "Start Walking" in Pedometer tab
- User taps "Stop" when done
- Automatically saves session

---

## Data Retention

### Free Tier

- Keep last 5 trips locally
- Older trips automatically deleted
- No iCloud sync

**Deletion Logic**:
```swift
func enforceFreeTierLimit() {
    guard !isPremium else { return }
    
    let trips = fetchAllTrips()
    
    if trips.count > 5 {
        let tripsToDelete = trips.dropFirst(5) // Keep first 5 (newest)
        for trip in tripsToDelete {
            deleteTrip(trip)
        }
    }
}
```

### Premium Tier

- Keep all trips indefinitely
- Sync to iCloud
- No automatic deletion

**Manual Deletion**:
- User can delete individual trips
- Confirmation required
- Syncs deletion to iCloud

---

## Performance Optimization

### Lazy Loading

Don't load all trips at once:

```swift
func fetchTrips(page: Int = 0, pageSize: Int = 20) -> [Trip] {
    let request = Trip.fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
    request.fetchLimit = pageSize
    request.fetchOffset = page * pageSize
    
    return try? context.fetch(request) ?? []
}
```

### Map Thumbnail Caching

Pre-generate map thumbnails for list view:

```swift
func generateMapThumbnail(for trip: Trip) -> UIImage? {
    let options = MKMapSnapshotter.Options()
    options.region = trip.mapRegion
    options.size = CGSize(width: 300, height: 200)
    
    let snapshotter = MKMapSnapshotter(options: options)
    
    return try? await snapshotter.start().image
}
```

Cache thumbnails to avoid regenerating.

---

## Testing Checklist

- [ ] Test trip auto-start when moving
- [ ] Test trip auto-end after 5 minutes stopped
- [ ] Test trip list display (free: 5, premium: all)
- [ ] Test trip detail with map
- [ ] Test speed graph rendering
- [ ] Test altitude graph rendering
- [ ] Test trip deletion with confirmation
- [ ] Test trip export (JSON, GPX)
- [ ] Test search functionality (premium)
- [ ] Test filter functionality (premium)
- [ ] Test sort options
- [ ] Test pedometer session recording
- [ ] Test pedometer session detail
- [ ] Test upgrade banner (free users)
- [ ] Test trip notification
- [ ] Test geocoding (addresses)
- [ ] Test iCloud sync (premium)
- [ ] Test data retention limits (free)
- [ ] Test empty state
- [ ] Test map thumbnail generation
- [ ] Test lazy loading/pagination
