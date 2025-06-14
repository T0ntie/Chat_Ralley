[[Firebase Projekt aufsetzen]]



```
rules_version = '2';  
  
service cloud.firestore {  
  match /databases/{database}/documents {  
    // Jeder authentifizierte Benutzer (auch anonymous) darf lesen und schreiben  
    match /{document=**} {  
      allow read, write: if request.auth != null;  
    }  
  }  
}
```

- firebase init firestore 

firebase deploy durchführen