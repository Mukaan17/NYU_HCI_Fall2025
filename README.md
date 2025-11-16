Developer Setup Guide

This project uses Expo SDK 54, React 19, expo-router, and React Native 0.81.
Because of the newer versions, the setup must be followed exactly to avoid dependency conflicts.

🚀 1. Requirements
Node
    Use Node 18 or Node 20.
    Check:

        node -v

NPM:
    Use npm, not yarn/pnpm:
    Check:

        npm -v

Xcode (for iOS development):
    Open Xcode at least once

    Make sure iOS Simulator is installed
(       Xcode → Settings → Platforms → iOS)

--------------------------------------------------------

📦 2. Install Dependencies
Clone the project:

    git clone <repository-url>
    cd mobile


Install:

    npm install


⚠️ Do NOT install anything manually.
The dependency versions are intentionally locked to avoid conflicts.

------------------------------------------------------------------

📱 3. Install the iOS Development Build (Required)
    This project does not work in Expo Go.
    You must build and install the dev client:

        npx expo run:ios


    This step builds a native iOS app and installs it in the simulator.
    (First time takes ~10–20 minutes.)

---------------------------------------------------------------

▶️ 4. Run the App

Start Metro:

    npx expo start --clear


The simulator will automatically open the dev build and load the app.
If the simulator does not open:

    npx expo start --dev-client

Then press:

    i

-----------------------------------------------------------------------

📁 5. Required File Structure
Do not delete or rename these files:

mobile/
  app/
    _layout.tsx
    (onboarding)/
    (tabs)/
  package.json

-------------------------------------------------------------------------

⚠️ 6. Do NOT Do These Things to keep the project stable:

❌ Do NOT run npm install react
❌ Do NOT run npm install react-native
❌ Do NOT run npm install expo-router
❌ Do NOT update Expo or React Native
❌ Do NOT delete App.js
❌ Do NOT install navigation packages manually

Everything is preconfigured.

---------------------------------------------------------------------

🔄 7. Reset If Something Breaks

If you hit bundling errors or React version conflicts:

rm -rf node_modules
rm package-lock.json
npm install
npx expo run:ios
npx expo start --clear


This fixes:

Duplicate React packages

"React Element from older version" errors

Metro cache corruption

Missing module issues

---------------------------------------------------------------------------------

🎉 You're Ready to Develop

Once the setup is done, you can work normally inside:

mobile/app/


Adding screens, components, tabs, navigation, etc.
Everything else is already configured.