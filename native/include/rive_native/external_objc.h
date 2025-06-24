#ifndef _SBS_EXTERNAL_OBJC_H_
#define _SBS_EXTERNAL_OBJC_H_

#include <cstdint>
#import "MetalKit/MetalKit.h"

void preCommitCallback(id<MTLCommandBuffer>, int64_t);

#endif
