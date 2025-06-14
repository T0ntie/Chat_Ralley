[[Firebase Projekt aufsetzen]]

![[Pasted image 20250613224247.png|300]]
- Get Started drücken
- ![[Pasted image 20250613230017.png|300]]
- ![[Pasted image 20250613230912.png|300]] ![[Pasted image 20250613230940.png|300]]
.firebaserc
```
```{  
  "projects": {  
    "default": "aitrailsgo",  
    "prod": "aitrailsgo"  
  },  
  "targets": {},  
  "etags": {}  
}```

firebase.json
```{  
  "hosting": {  
    "public": "public",  
    "ignore": [  
      "firebase.json",  
      "**/.*",  
      "**/node_modules/**"  
    ],  
    "headers": [  
      {  
        "source": "**/*.svg",  
        "headers": [  
          {  
            "key": "Access-Control-Allow-Origin",  
            "value": "*"  
          },  
          {  
            "key": "Content-Type",  
            "value": "image/svg+xml"  
          }  
        ]  
      }  
    ]  
  },  
  "functions": [  
    {  
      "source": "functions",  
      "codebase": "default",  
      "ignore": [  
        "node_modules",  
        ".git",  
        "firebase-debug.log",  
        "firebase-debug.*.log",  
        "*.local"  
      ],  
      "predeploy": [  
        "npm --prefix \"$RESOURCE_DIR\" run lint",  
        "npm --prefix \"$RESOURCE_DIR\" run build"      ]  
    }  
  ]  
}
```
- firebase deploy --only hosting