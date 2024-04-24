# Flutter & Platform Specific Channels

A Flutter project demonstrating how to communicate with android and ios native sides.

## Setup

- Configure `MethodChannel` inside
  - `MainActivity.kt` for android
  - `AppDelegate.kt` for ios
- Define operations for individual call methods in the native side
- Return results from the native side
- Handle Errors in the native side
- Configure `MethodChannel` inside flutter
- Call `invokeMethods` on method channel inside flutter
- Do operation in flutter after getting response from the native side
- Handle platform exceptions inside flutter

## Examples

- Get an String object from the native side
- Get battery level from the native side
