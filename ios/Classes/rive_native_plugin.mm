#import "rive_native_plugin.h"
#include "rive_native/external.hpp"
#include "rive_native/external_objc.h"
#include "rive_native/read_write_ring.hpp"
#import "MetalKit/MetalKit.h"

RiveNativePlugin* riveNativePluginInstance = NULL;

// rive_binding wants this defined
bool usePLS = true;

@interface RiveNativeRenderTexture ()
{
    CVMetalTextureCacheRef _metalTextureCache;
    CVMetalTextureRef _metalTextureCVRef[3];
@public
    id<MTLTexture> _metalTexture[3];
@public
    MTLRenderPassDescriptor* _passDescriptor[3];
    CVPixelBufferRef _pixelData[3];
    void* _riveRenderer;
    ReadWriteRing _readWriteRing;
    std::mutex _mutex;
}
@end

@implementation RiveNativeRenderTexture
- (instancetype)initWithDevice:(id<MTLDevice>)device
                      andQueue:(id<MTLCommandQueue>)commandQueue
                      andWidth:(int)width
                     andHeight:(int)height
                  registerWith:(NSObject<FlutterTextureRegistry>*)registry
{
    self = [super init];
    _riveRenderer = nil;
    if (self)
    {
        _width = width;
        _height = height;
        NSDictionary* options = @{
            // This key is required to generate SKPicture with CVPixelBufferRef
            // in metal.
            (NSString*)kCVPixelBufferMetalCompatibilityKey : @YES
        };
        CVReturn status = CVMetalTextureCacheCreate(
            kCFAllocatorDefault, nil, device, nil, &_metalTextureCache);
        if (status != 0)
        {
            NSLog(@"CVMetalTextureCacheCreate error %d", (int)status);
        }
        for (int i = 0; i < 3; i++)
        {
            CVReturn status =
                CVPixelBufferCreate(kCFAllocatorDefault,
                                    width,
                                    height,
                                    kCVPixelFormatType_32BGRA,
                                    (__bridge CFDictionaryRef)options,
                                    &_pixelData[i]);
            if (status != 0)
            {
                NSLog(@"CVPixelBufferCreate error %d", (int)status);
            }

            status = CVMetalTextureCacheCreateTextureFromImage(
                kCFAllocatorDefault,
                _metalTextureCache,
                _pixelData[i],
                nil,
                MTLPixelFormatBGRA8Unorm,
                width,
                height,
                0,
                &_metalTextureCVRef[i]);
            if (status != 0)
            {
                NSLog(@"CVMetalTextureCacheCreateTextureFromImage error %d",
                      (int)status);
            }
            _metalTexture[i] = CVMetalTextureGetTexture(_metalTextureCVRef[i]);
            // make 3 of these...
            _passDescriptor[i] = [MTLRenderPassDescriptor renderPassDescriptor];
            _passDescriptor[i].colorAttachments[0].texture = _metalTexture[i];
            _passDescriptor[i].colorAttachments[0].loadAction =
                MTLLoadActionClear;
            _passDescriptor[i].colorAttachments[0].storeAction =
                MTLStoreActionStore;
            _passDescriptor[i].colorAttachments[0].clearColor =
                MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
        }

        _flutterTextureId = [registry registerTexture:self];
        _riveRenderer = createRiveRenderer(_flutterTextureId,
                                           (__bridge void*)commandQueue,
                                           &_readWriteRing,
                                           (__bridge void*)_metalTexture[0],
                                           (__bridge void*)_metalTexture[1],
                                           (__bridge void*)_metalTexture[2],
                                           width,
                                           height);
    }

    return self;
}

- (void)dealloc
{
    std::unique_lock<std::mutex> lock(_mutex);
    auto oldRenderer = _riveRenderer;
    _riveRenderer = nil;
    destroyRiveRenderer(oldRenderer);
    for (int i = 0; i < 3; i++)
    {
        _passDescriptor[i] = nil;
        _metalTexture[i] = nil;
        if (_metalTextureCVRef[i])
        {
            CFRelease(_metalTextureCVRef[i]);
            _metalTextureCVRef[i] = nil;
        }
        CVPixelBufferRelease(_pixelData[i]);
    }
    if (_metalTextureCache)
    {
        CFRelease(_metalTextureCache);
        _metalTextureCache = nil;
    }
}

// - (void)createMtlTextureFromCVPixBufferWithDevice:(id<MTLDevice>)device
//                                          andWidth:(int)width
//                                         andHeight:(int)height
//                                      withRegistry:(NSObject<FlutterTextureRegistry>*)registry
// {
//     if (!device)
//     {
//         return;
//     }

//     CVReturn status =
//         CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil,
//         &_metalTextureCache);
//     if (status != 0)
//     {
//         NSLog(@"CVMetalTextureCacheCreate error %d", (int)status);
//     }

//     status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
//                                                        _metalTextureCache,
//                                                        _pixelData,
//                                                        nil,
//                                                        MTLPixelFormatBGRA8Unorm,
//                                                        width,
//                                                        height,
//                                                        0,
//                                                        &_metalTextureCVRef);
//     if (status != 0)
//     {
//         NSLog(@"CVMetalTextureCacheCreateTextureFromImage error %d",
//         (int)status);
//     }
//     _metalTexture = CVMetalTextureGetTexture(_metalTextureCVRef);
//     // make 3 of these...
//     _passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
//     _passDescriptor.colorAttachments[0].texture = _metalTexture;
//     _passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
//     _passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
//     _passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0,
//     0.0, 0.0, 0.0);

//     // id<MTLCommandQueue> commandQueue = [device newCommandQueue];
//     // id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
//     // id<MTLRenderCommandEncoder> commandEncoder =
//     //     [commandBuffer
//     renderCommandEncoderWithDescriptor:_passDescriptor];
//     // [commandEncoder endEncoding];
//     // [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer>
//     commandBuffer) {
//     //   [registry textureFrameAvailable:self->_flutterTextureId];
//     // }];
//     // [commandBuffer commit];
// }

#pragma mark - FlutterTexture

- (CVPixelBufferRef)copyPixelBuffer
{
    int readIndex = _readWriteRing.currentRead();
    auto data = _pixelData[readIndex];
    CVBufferRetain(data);
    return data;
}

@end

@interface RiveNativePlugin ()
{
    id<MTLDevice> _metalDevice;
    id<MTLCommandQueue> _metalCommandQueue;
    void* _riveRendererContext;
}
@property(nonatomic, strong) NSObject<FlutterTextureRegistry>* textureRegistry;
@property(nonatomic, strong)
    NSMutableDictionary<NSNumber*, RiveNativeRenderTexture*>* renderTextures;
@end

@implementation RiveNativePlugin

- (instancetype)initWithTextures:(NSObject<FlutterTextureRegistry>*)textures
{
    self = [super init];
    if (self)
    {
        _textureRegistry = textures;
        _renderTextures = [[NSMutableDictionary alloc] init];

        _metalDevice = MTLCreateSystemDefaultDevice();
        _metalCommandQueue = [_metalDevice newCommandQueue];
        _riveRendererContext =
            createRiveRendererContext((__bridge void*)_metalDevice);
        setGPU((__bridge void*)_metalDevice,
               (__bridge void*)_metalCommandQueue);
    }
    return self;
}

- (void)dealloc
{
    destroyRiveRendererContext(_riveRendererContext);
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
    FlutterMethodChannel* channel =
        [FlutterMethodChannel methodChannelWithName:@"rive_native"
                                    binaryMessenger:[registrar messenger]];
    riveNativePluginInstance =
        [[RiveNativePlugin alloc] initWithTextures:[registrar textures]];
    [registrar addMethodCallDelegate:riveNativePluginInstance channel:channel];
}

RiveNativeRenderTexture* getBoundRenderTexture(int64_t textureId)
{
    return [riveNativePluginInstance->_renderTextures
        objectForKey:[NSNumber numberWithLongLong:textureId]];
}

void preCommitCallback(id<MTLCommandBuffer> commandBuffer, int64_t textureId)
{
    RiveNativeRenderTexture* rt = getBoundRenderTexture(textureId);
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
      std::unique_lock<std::mutex> lock(rt->_mutex);
      if (rt->_riveRenderer == nil)
      {
          return;
      }
      rt->_readWriteRing.nextRead();
      [riveNativePluginInstance->_textureRegistry
          textureFrameAvailable:[rt flutterTextureId]];
    }];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
    if ([call.method isEqualToString:@"createTexture"])
    {
        NSNumber* width;
        NSNumber* height;
        if (call.arguments)
        {
            width = call.arguments[@"width"];
            if (width == NULL)
            {
                result([FlutterError
                    errorWithCode:@"CreateTexture Error"
                          message:@"No width received by the native part of "
                                  @"RiveNative.createTexture"
                          details:NULL]);
                return;
            }
            height = call.arguments[@"height"];
            if (height == NULL)
            {
                result([FlutterError
                    errorWithCode:@"CreateTexture Error"
                          message:@"No height received by the native part of "
                                  @"RiveNative.createTexture"
                          details:NULL]);
                return;
            }
        }
        else
        {
            result([FlutterError
                errorWithCode:@"No arguments"
                      message:@"No arguments received by the native part of "
                              @"RiveNative.createTexture"
                      details:NULL]);
            return;
        }

        RiveNativeRenderTexture* renderTexture =
            [[RiveNativeRenderTexture alloc] initWithDevice:_metalDevice
                                                   andQueue:_metalCommandQueue
                                                   andWidth:width.intValue
                                                  andHeight:height.intValue
                                               registerWith:_textureRegistry];

        [_renderTextures
            setObject:renderTexture
               forKey:[NSNumber
                          numberWithLongLong:[renderTexture flutterTextureId]]];

        // clear();
        // flush();
        result(@{
            @"textureId" :
                [NSNumber numberWithLongLong:[renderTexture flutterTextureId]]
        });

        return;
    }
    if ([call.method isEqualToString:@"removeTexture"])
    {
        NSNumber* id;
        if (call.arguments)
        {
            id = call.arguments[@"id"];
            if (id == NULL)
            {
                result([FlutterError
                    errorWithCode:@"removeTexture Error"
                          message:@"no id received by the native part of "
                                  @"RiveNative.removeTexture"
                          details:NULL]);
                return;
            }
            RiveNativeRenderTexture* texture =
                [_renderTextures objectForKey:id];
            [_textureRegistry unregisterTexture:[texture flutterTextureId]];
            [_renderTextures removeObjectForKey:id];
            result(nil);
            return;
        }
        else
        {
            result([FlutterError
                errorWithCode:@"No arguments"
                      message:@"No arguments received by the native part of "
                              @"RiveNative.removeTexture"
                      details:NULL]);
            return;
        }
    }

    result(FlutterMethodNotImplemented);
}
@end
