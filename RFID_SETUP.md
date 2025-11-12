# RFID Real-Time Database Setup

## Overview
This Flutter application now properly connects to your Firebase Realtime Database and displays RFID tag data in real-time.

## Firebase Database Structure
Your database structure (as shown in the screenshot):
```
Root
├── 341B3402
│   ├── product_count: 1
│   ├── rfid_tag: "341B3402"
│   ├── timestamp: 183072
│   └── weight: 5877.73
├── [Other RFID Tags...]
```

## Changes Made

### 1. Updated Data Model (`arduino_product_data.dart`)
- Changed field names to match Firebase structure:
  - `stockCount` → `productCount`
  - Added `rfidTag` field
  - Updated parsing to handle your exact Firebase structure
- The model now correctly parses data with fields: `product_count`, `rfid_tag`, `timestamp`, `weight`

### 2. Updated Firebase Service (`firebase_service.dart`)
- Changed database reference to read from **root level** (where your RFID tags are stored)
- Added filtering to only read nodes with RFID structure
- Ignores other nodes like `inventory`, `inventory_history`, etc.
- Real-time stream automatically updates when data changes

### 3. Created RFID Monitor Screen (`rfid_monitor_screen.dart`)
A dedicated screen to view real-time RFID data with:
- **Connection Status**: Shows if connected to Firebase
- **Live Updates**: Automatically refreshes when data changes
- **RFID Tag Cards**: Displays each tag with:
  - RFID Tag ID (e.g., "341B3402")
  - Product Count
  - Weight
  - Timestamp
  - Status (In Stock / Low Stock / Out of Stock)

## How to Use

### Method 1: From Landing Screen
1. Run the app
2. On the landing screen, click the **"RFID Monitor"** floating button (bottom right)
3. View real-time RFID data

### Method 2: Direct Navigation
```dart
Navigator.pushNamed(context, '/rfid-monitor');
```

## Real-Time Updates
The app uses Firebase Realtime Database streams:
- **Automatic**: Updates happen instantly when Arduino writes to Firebase
- **No Polling**: Uses Firebase's built-in real-time listeners
- **Efficient**: Only transmits changed data

## Testing
1. **Add/Update RFID Data in Firebase Console**:
   - Go to Firebase Console → Realtime Database
   - Add a new node with structure:
     ```json
     {
       "product_count": 5,
       "rfid_tag": "ABC123",
       "timestamp": 183072,
       "weight": 1234.56
     }
     ```
   - The app will automatically display the new data

2. **From Arduino/ESP32**:
   - Your Arduino should write to the root level
   - Use RFID tag as the node key
   - Include all four fields: `product_count`, `rfid_tag`, `timestamp`, `weight`

## Stock Status Logic
- **Out of Stock**: `product_count == 0` (Red)
- **Low Stock**: `product_count <= 2` (Orange)
- **In Stock**: `product_count > 2` (Green)

## Firebase Connection
- Database URL: `https://arduino-148de-default-rtdb.asia-southeast1.firebasedatabase.app`
- Project ID: `arduino-148de`
- Region: `asia-southeast1`

## Troubleshooting

### No Data Showing
1. Check Firebase Console - ensure data exists at root level
2. Verify Firebase rules allow read access
3. Check console logs for errors

### Data Not Updating
1. Ensure you're using the RFID Monitor screen (not cached data)
2. Check internet connection
3. Verify Firebase Database rules

### Connection Issues
1. Check `google-services.json` is properly configured
2. Verify Firebase initialization in `main.dart`
3. Check Firebase project settings

## Firebase Rules (Recommended)
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```
**Note**: For production, implement proper authentication and security rules.

## Next Steps
1. Run the app: `flutter run`
2. Navigate to RFID Monitor
3. Add test data in Firebase Console
4. Watch real-time updates!

## Features
✅ Real-time Firebase Realtime Database integration
✅ Automatic updates (no manual refresh needed)
✅ Clean, modern UI with status indicators
✅ Stock level monitoring
✅ Weight tracking
✅ Timestamp display
✅ Connection status indicator
