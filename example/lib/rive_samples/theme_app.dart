
import 'package:example/rive_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive_native/rive_native.dart' as rive;

const _appBarColor = Color(0xFF323232);
const _backgroundColor = Color(0xFF1D1D1D);
const _primaryColor = Color(0xFF57A5E0);

class MyThemedApp extends ConsumerWidget {
  const MyThemedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,

      darkTheme: ThemeData.dark().copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _backgroundColor,
        appBarTheme: const AppBarTheme(backgroundColor: _appBarColor),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.amber,
          secondary: _appBarColor),
      ),
      theme: ThemeData.light().copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(backgroundColor: _appBarColor),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.green,
          secondary: Colors.white,
        ),
      ),

      themeMode: ref.watch(themeProvider),
      home: const DuuprLogoRiveVM(),
    );
  }
}

class DuuprLogoRiveVM extends StatefulWidget {
  const DuuprLogoRiveVM({super.key});

  @override
  State<DuuprLogoRiveVM> createState() => _DuuprLogoRiveVMState();
}

class _DuuprLogoRiveVMState extends State<DuuprLogoRiveVM> {

  rive.ViewModelInstance? duuprLogoVMInstance;
  rive.ViewModelInstance? duuprTextVMInstance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer(
            builder: (context, ref, child) {
              
              final themeValue = ref.watch(themeProvider);
              final colorScheme = Theme.of(context).colorScheme;
              
              if (duuprLogoVMInstance != null && duuprTextVMInstance != null) {
                final theme = Theme.of(context);
                final colorScheme = theme.colorScheme;
                final themeBrightness = theme.brightness;

                final logoThemeColor = duuprLogoVMInstance!.color('themeColor');
                final logoThemeBgColor = duuprLogoVMInstance!.color('themeBgColor');

                final ribbonTextThemeColor = duuprTextVMInstance!.color('themeColor');
                final ribbonTextThemeBgColor = duuprTextVMInstance!.color('themeBgColor');
                final ribbonText = duuprTextVMInstance!.string('themeMode');

                logoThemeColor!.value = ribbonTextThemeColor!.value = colorScheme.primary;
                logoThemeBgColor!.value = ribbonTextThemeBgColor!.value = colorScheme.secondary;
                ribbonText!.value = '${themeBrightness.name} mode';
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.light_mode, color: colorScheme.primary),
                    Switch(
                      thumbColor: WidgetStatePropertyAll(colorScheme.primary,),
                      trackColor: WidgetStatePropertyAll(colorScheme.primary.withValues(alpha: 0.5)),
                      activeTrackColor: colorScheme.primary,
                      inactiveTrackColor: colorScheme.primary,
                      value: ref.watch(themeProvider) == ThemeMode.dark,
                      
                      onChanged: (value) {
                        ref.read(themeProvider.notifier).state =
                            value ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                    Icon(Icons.dark_mode, color: colorScheme.primary),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Consumer(
          builder: (context, ref, child) {

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [


                SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  height: 400,
                  child: RivePlayer(
                    asset: "assets/duuprlogo.riv",
                    artboardName: "duuprtext",
                    stateMachineName: "duuprtext",
                    fit: rive.Fit.cover,
                    autoBind: true,
                    withViewModelInstance: (viewModelInstance) {
                      duuprTextVMInstance = viewModelInstance;

                      Future.microtask(() {
                        setState(() {
                        });
                      });
                    },
                  ),
                ),

                SizedBox(
                  width: 300,
                  height: 300,
                  child: RivePlayer(
                    asset: "assets/duuprlogo.riv",
                    artboardName: "duuprlogo",
                    stateMachineName: "duuprlogo",
                    autoBind: true,
                    withViewModelInstance: (viewModelInstance) {
                      duuprLogoVMInstance = viewModelInstance;

                      Future.microtask(() {
                        setState(() {
                        });
                      });
                    },
                  ),
                ),
              ],
            );
          }
        ),
      
      ),
    );
  }
}

final themeProvider = StateProvider((ref) => ThemeMode.light);