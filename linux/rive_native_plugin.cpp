#include "include/rive_native/rive_native_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>

#define RIVE_NATIVE_PLUGIN(obj)                                                \
    (G_TYPE_CHECK_INSTANCE_CAST((obj),                                         \
                                rive_native_plugin_get_type(),                 \
                                RiveNativePlugin))

struct _RiveNativePlugin
{
    GObject parent_instance;
};

G_DEFINE_TYPE(RiveNativePlugin, rive_native_plugin, g_object_get_type())

FlMethodResponse* get_platform_version()
{
    struct utsname uname_data = {};
    uname(&uname_data);
    g_autofree gchar* version = g_strdup_printf("Linux %s", uname_data.version);
    g_autoptr(FlValue) result = fl_value_new_string(version);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

// Called when a method call is received from Flutter.
static void rive_native_plugin_handle_method_call(RiveNativePlugin* self,
                                                  FlMethodCall* method_call)
{
    g_autoptr(FlMethodResponse) response = nullptr;

    const gchar* method = fl_method_call_get_name(method_call);

    if (strcmp(method, "getPlatformVersion") == 0)
    {
        response = get_platform_version();
    }
    else
    {
        response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
    }

    fl_method_call_respond(method_call, response, nullptr);
}

static void rive_native_plugin_dispose(GObject* object)
{
    G_OBJECT_CLASS(rive_native_plugin_parent_class)->dispose(object);
}

static void rive_native_plugin_class_init(RiveNativePluginClass* klass)
{
    G_OBJECT_CLASS(klass)->dispose = rive_native_plugin_dispose;
}

static void rive_native_plugin_init(RiveNativePlugin* self) {}

static void method_call_cb(FlMethodChannel* channel,
                           FlMethodCall* method_call,
                           gpointer user_data)
{
    RiveNativePlugin* plugin = RIVE_NATIVE_PLUGIN(user_data);
    rive_native_plugin_handle_method_call(plugin, method_call);
}
#define EXPORT                                                                 \
    extern "C" __attribute__((visibility("default"))) __attribute__((used))

class FlutterRenderer;
EXPORT void* loadRiveFile(const uint8_t* bytes, uint64_t length);
EXPORT void deleteFlutterRenderer(FlutterRenderer* renderer);
namespace rive
{
class RenderPath;
class Factory;
} // namespace rive

// Rive Renderer not implemented on Linux.
rive::Factory* riveFactory() { return nullptr; }

EXPORT void rewindRenderPath(rive::RenderPath* path);
EXPORT void* disposeYogaStyle(void* style);

void rive_native_plugin_register_with_registrar(FlPluginRegistrar* registrar)
{
    RiveNativePlugin* plugin = RIVE_NATIVE_PLUGIN(
        g_object_new(rive_native_plugin_get_type(), nullptr));

    g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
    g_autoptr(FlMethodChannel) channel =
        fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                              "rive_native",
                              FL_METHOD_CODEC(codec));
    fl_method_channel_set_method_call_handler(channel,
                                              method_call_cb,
                                              g_object_ref(plugin),
                                              g_object_unref);

    g_object_unref(plugin);

    // Force link these methods to get the whole object file.
    loadRiveFile(nullptr, 0);
    deleteFlutterRenderer(nullptr);
    rewindRenderPath(nullptr);
    disposeYogaStyle(nullptr);
}
