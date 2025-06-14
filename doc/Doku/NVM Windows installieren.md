
[[Firebase Functions einrichten]]

https://github.com/coreybutler/nvm-windows/releases/tag/1.2.2

nvm install 20
nvm use 20
node -v

um node.js auf die Version 20 "downzugraden"

Typingfehler in importiertem library code vermeiden:

```{  
  "compilerOptions": {  
    "module": "NodeNext",  
    "esModuleInterop": true,  
    "moduleResolution": "nodenext",  
    "noImplicitReturns": true,  
    "noUnusedLocals": true,  
    "outDir": "lib",  
    "sourceMap": true,  
    "strict": true,  
    "target": "es2017",  
    "skipLibCheck": true  
  },  
  "compileOnSave": true,  
  "include": [  
    "src"  
  ]  
}
```
Code in index.ts anpassen nicht res returnieren 

npm run build

danach:

 firebase deploy --project=aitrailsgo --only functions

 How many days do you want to keep container images before they're deleted? (1)
 
 https://console.firebase.google.com/project/aitrailsgo/overview

