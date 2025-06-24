#import <FlutterMacOS/FlutterMacOS.h>
#import <MetalKit/MetalKit.h>

@interface RiveNativePlugin : NSObject <FlutterPlugin>
@end

@interface RiveNativeRenderTexture : NSObject <FlutterTexture>
- (instancetype)initWithDevice:(id<MTLDevice>)device
                      andQueue:(id<MTLCommandQueue>)commandQueue
                      andWidth:(int)width
                     andHeight:(int)height
                  registerWith:(NSObject<FlutterTextureRegistry>*)registry;
@property(nonatomic, assign) int width;
@property(nonatomic, assign) int height;
@property(nonatomic, assign) int64_t flutterTextureId;
@end

extern RiveNativePlugin* renderPluginIntance;
