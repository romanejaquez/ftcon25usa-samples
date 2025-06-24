
import 'package:example/rive_player.dart';
import 'package:flutter/material.dart';
import 'package:rive_native/rive_native.dart' as rive;

class FlutterConUSAApp extends StatefulWidget {
  const FlutterConUSAApp({super.key});

  @override
  State<FlutterConUSAApp> createState() => _FlutterConUSAAppState();
}

class _FlutterConUSAAppState extends State<FlutterConUSAApp> {

  rive.ViewModelInstance? fcApp;
  bool initialized = false;

  @override
  Widget build(BuildContext context) {

    if (initialized) {
      if (fcApp != null) {
        final dateLabel = fcApp!.string('dateLabel');
        //dateLabel!.value = 'june 25-26';

        final subTextLabel = fcApp!.string('subTextLabel');
        //subTextLabel!.value = 'builder party';

        final topTextLabel = fcApp!.string('topTextLabel');
        ///topTextLabel!.value = 'The top-notch';

        final locationLabel = fcApp!.string('locationLabel');
        //locationLabel!.value = 'stockholm,\nnorway'; 

        final nameLabel = fcApp!.string('nameLabel');
        nameLabel!.value = 'Roman Jaquez'; 
      }
    }

    return MaterialApp(
      home: Scaffold(
        body: RivePlayer(
          asset: "assets/flutterconusa.riv",
          artboardName: "main",
          stateMachineName: "main",
          fit: rive.Fit.cover,
          autoBind: true,
          withViewModelInstance: (viewModelInstance) {
            fcApp = viewModelInstance;

            Future.delayed(const Duration(seconds: 0), () {
              setState(() {
                initialized = true;
              });
            });
          },
        ),
      )
    );
  }
}

