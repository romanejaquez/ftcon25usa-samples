
#include "rive_native/rive_native_plugin.h"

#include <flutter/plugin_registrar_windows.h>

#include "rive_native/rive_native_plugin.hpp"

void RiveNativePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar)
{
    RiveNativePlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarManager::GetInstance()
            ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}