```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
```

nano ~/.zprofile
export PATH="/opt/homebrew/bin:$PATH"

source ~/.zprofile

brew doctor

brew install git

git --version

brew install flutter

flutter doctor

```

Im Android Studio die Android SDK Comanndline Tools nachinstallieren (unter more Actions)

Flutter Plugin installieren

```
flutter doctor --android-licenses
```
XCode installieren aus dem Appstore

```
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

```
sudo gem install cocoapods (hat nicht funktioniert statt dessen mit brew)

brew install cocoapods
```
