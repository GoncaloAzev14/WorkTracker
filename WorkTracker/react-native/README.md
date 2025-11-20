to fix expo dependencies:

1. apagar node_modules, android, ios e package-lock.json
2. corrigir package.json:   
    ```
    {
      "name": "worktrackerrn",
      "version": "1.0.0",
      "main": "expo/AppEntry.js",
      "scripts": {
        "start": "expo start",
        "android": "expo run:android",
        "ios": "expo run:ios",
        "web": "expo start --web"
      },
      "dependencies": {
        "@react-native-async-storage/async-storage": "2.2.0",
        "@react-native-community/datetimepicker": "8.4.4",
        "@react-native-picker/picker": "2.11.1",
        "expo": "~54.0.25",
        "expo-build-properties": "~1.0.9",
        "expo-status-bar": "~3.0.8",
        "pdf-lib": "^1.17.1",
        "react": "19.1.0",
        "react-native": "0.81.5",
        "react-native-safe-area-context": "~5.6.0",
        "react-native-screens": "~4.16.0",
        "react-native-share": "^12.2.1"
      },
      "devDependencies": {
        "@tsconfig/react-native": "^3.0.8",
        "@types/react": "~19.1.10",
        "typescript": "~5.9.2"
      },
      "private": true
    }
    ```
3. correr npm install
4. correr npx expo install
5. correr npx expo prebuild --clean
6. correr npx expo run:ios/android para correr nos telemoveis