# Rive Flutter Samples
### Rive Samples Using the rive_native package
This is a companion repo containing resources shared during my presentation at FlutterCon USA '25 with the title **Rive: The Final Frontier of Graphics for Flutter Apps**.

## Resources

Slides (as a Flutter app itself, animated in Rive) 
[https://github.com/romanejaquez/ftcon25usa-slides]

Rive Inspector
[https://rive-inspector.web.app/]

Youtube Series on Flutter w/ Rive
[https://www.youtube.com/@romanjustcodes]

## Follow me
- On X [https://x.com/drcoderz]
- On LinkedIn [https://www.linkedin.com/in/roman-jaquez-8941a424/]
- On BlueSky [https://bsky.app/profile/romanjaquez.bsky.social]



# rive_native

Rive Native is a new runtime that allows you to display and interact with Rive graphics in your Flutter app, powered by the [Rive Renderer](https://rive.app/renderer).

For up to date information on Rive Native, see the [official documentation](https://rive.app/docs/runtimes/flutter/rive-native).

## Getting Started

`rive_native` is not yet publicly available on GitHub but will be soon. For now, you can pull the source code and example by running:

```bash
dart pub unpack rive_native # Unpack the package source code and example app
cd rive_native/example      # Navigate to the example folder
flutter create .            # Create the platform folders
flutter pub get             # Fetch dependencies
flutter run                 # Run the example app
```

A higher-level declarative API is under development to simplify working with Rive graphics in Flutter.

For an example implementation, see the `rive_player.dart` file in `rive_native/example/rive_player.dart`.

---

## Platform Support

| Platform | Flutter Renderer | Rive Renderer |
|----------|------------------|---------------|
| iOS      | ✅               | ✅             |
| Android  | ✅               | ✅             |
| macOS    | ✅               | ✅             |
| Windows  | ✅               | ✅             |
| Linux    | ❌               | ❌             |
| Web      | ✅               | ✅             |

> **Note**: Android support is currently limited to `arm` and `arm64` architectures.

---

## Feature Support

The following runtime features are supported by `rive_native`:

| Feature                          | Support |
|----------------------------------|---------|
| Set State Machine Inputs         | ✅       |
| Set State Machine Nested Inputs  | ✅       |
| Updating Text Runs               | ✅       |
| Updating Nested Text Runs        | ✅       |
| Responsive Layouts               | ✅       |
| Rive Audio                       | ✅       |
| Out-of-Band Assets               | ✅       |
| Rive Events                      | ✅       |

---

## Troubleshooting

The required native libraries should be automatically downloaded during the build step (`flutter run` or `flutter build`). If you encounter issues, try the following:

1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run`

Alternatively, you can manually run the `rive_native` setup script. In the root of your Flutter app, execute:

```bash
dart run rive_native:setup --verbose --clean --platform macos
```

This will clean the `rive_native` setup and download the platform-specific libraries specified with the `--platform` flag. Refer to the **Platform Support** section above for details.

---

## Building `rive_native`

By default, prebuilt native libraries are downloaded and used. If you prefer to build the libraries yourself, use the `--build` flag with the setup script:

```bash
flutter clean # Important
dart run rive_native:setup --verbose --clean --build --platform macos
```

> **Note**: Building the libraries requires specific tooling on your machine. Additional documentation will be provided soon.

---

## Testing

Shared libraries are included in the download/build process. If you encounter issues using `rive_native` in your tests, please reach out to us for assistance.

## Support

- Reach out to us on our [Community](https://community.rive.app/feed)
- File an issue on the [Rive Flutter repository](https://github.com/rive-app/rive-flutter/issues)
