# Firebase Storage Setup Guide

## Issue Description
The app is experiencing Firebase Storage errors when trying to upload product images:
```
StorageException: The operation was cancelled.
Code: -13040 HttpResult: 0
Error: [firebase_storage/object-not-found] No object exists at the desired reference.
```

## Root Causes
1. **Firebase Storage not properly configured**
2. **Storage rules not allowing uploads**
3. **Storage bucket not created or accessible**
4. **Authentication issues**

## Solution Steps

### 1. Enable Firebase Storage
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `fastfood-48fa2`
3. Navigate to **Storage** in the left sidebar
4. Click **Get Started**
5. Choose **Start in test mode** (we'll secure it later)
6. Select a location (choose closest to your users)

### 2. Configure Storage Rules
1. In Firebase Console, go to **Storage > Rules**
2. Replace the default rules with the content from `storage.rules` file:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /products/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
    match /test/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

3. Click **Publish**

### 3. Verify Storage Bucket URL
Ensure the storage bucket URL in `firebase_options.dart` matches your actual bucket:
- Current: `fastfood-48fa2.firebasestorage.app`
- Verify this matches your Firebase project's storage bucket

### 4. Test the Fix
1. Run the app
2. Login as admin
3. Try to add a new product with an image
4. Check the console logs for detailed error information

## Code Improvements Applied

### Enhanced Error Handling
- Added specific Firebase Storage error codes handling
- Implemented retry mechanism with exponential backoff
- Added connectivity testing before upload attempts
- Improved user-friendly error messages in Uzbek

### Upload Improvements
- Added file size validation (max 10MB)
- Added file existence checks
- Added upload progress monitoring
- Added metadata for tracking uploads
- Implemented authentication checks before upload

### Retry Mechanism
- Automatic retry up to 3 times
- Exponential backoff between retries
- Connectivity testing before each attempt

## Testing Checklist
- [ ] Firebase Storage is enabled in console
- [ ] Storage rules are properly configured
- [ ] User can authenticate successfully
- [ ] Image upload works without errors
- [ ] Error messages are user-friendly
- [ ] Retry mechanism works on network issues

## Troubleshooting

### If storage bucket doesn't exist:
1. Go to Firebase Console > Storage
2. Click "Get Started" to create the bucket
3. Verify the bucket URL matches `firebase_options.dart`

### If authentication fails:
1. Ensure user is logged in before uploading
2. Check Firebase Auth is properly configured
3. Verify auth token is valid

### If rules are too restrictive:
1. Temporarily use test mode rules for debugging
2. Gradually tighten security once upload works

## Security Notes
- Only authenticated users can upload/download
- Files are organized in `/products/` folder
- Each upload includes metadata with user ID and timestamp
- File size is limited to 10MB maximum
