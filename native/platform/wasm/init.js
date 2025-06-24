Module["onRuntimeInitialized"] = function () {
  const makeRenderer = Module["makeRenderer"];
  let _offscreenGL = null;

  function makeGLRenderer(canvas, enableMSAA = false) {
    var contextAttributes = {
      "alpha": true,
      "depth": enableMSAA,
      "stencil": enableMSAA,
      "antialias": enableMSAA,
      "premultipliedAlpha": true,
      "preserveDrawingBuffer": 1,
      "powerPreference": "high-performance",
      "failIfMajorPerformanceCaveat": 0,
      "enableExtensionsByDefault": false,
      "explicitSwapControl": 0,
      "renderViaOffscreenBackBuffer": 0,
    };

    var gl = canvas.getContext("webgl2", contextAttributes);
    if (!gl) {
      return null;
    }
    var handle = GL.registerContext(gl, contextAttributes);

    GL.makeContextCurrent(handle);

    return {
      "_ptr": makeRenderer(canvas.width, canvas.height),
      _handle: handle,
      _canvas: canvas,
      _width: canvas.width,
      _height: canvas.height,
      _gl: gl,
    };
  }

  Module["makeRenderer"] = function (canvas) {
    if (!_offscreenGL) {
      function MakeOffscreenGL(enableMSAA) {
        const offscreenCanvas = document.createElement("canvas");
        offscreenCanvas.width = 1;
        offscreenCanvas.height = 1;
        _offscreenGL = makeGLRenderer(offscreenCanvas, enableMSAA);

        _offscreenGL._hasPixelLocalStorage = Boolean(
          _offscreenGL._gl.getExtension("WEBGL_shader_pixel_local_storage")
        );

        _offscreenGL._maxRTSize = Math.min(
          _offscreenGL._gl.getParameter(_offscreenGL._gl.MAX_RENDERBUFFER_SIZE),
          _offscreenGL._gl.getParameter(_offscreenGL._gl.MAX_TEXTURE_SIZE)
        );

        // WEBGL_shader_pixel_local_storage works without MSAA.
        _offscreenGL._enableAntialiasCanvas =
          !_offscreenGL._hasPixelLocalStorage;

        const webglDebugInfo = _offscreenGL._gl.getExtension(
          "WEBGL_debug_renderer_info"
        );
        if (webglDebugInfo) {
          const vendor = _offscreenGL._gl.getParameter(
            webglDebugInfo.UNMASKED_VENDOR_WEBGL
          );
          const renderer = _offscreenGL._gl.getParameter(
            webglDebugInfo.UNMASKED_RENDERER_WEBGL
          );
          if (
            vendor.includes("Google") &&
            renderer.includes("ANGLE Metal Renderer")
          ) {
            // We experience flickering on Chrome/Metal when using a WebGL context with
            // "antialias:true". This appears to be a synchronization issue internal to the browser.
            // Avoid "antialias:true" in this case, opting instead to do our own internal MSAA.
            _offscreenGL._enableAntialiasCanvas = false;
          }
        }

        return _offscreenGL;
      }

      _offscreenGL = MakeOffscreenGL(/*enableMSAA =*/ true);
      if (!_offscreenGL._enableAntialiasCanvas) {
        // This browser prefers "antialias:false". Re-create the offscreen without MSAA.
        _offscreenGL = MakeOffscreenGL(/*enableMSAA =*/ false);
      }
    }
    return makeGLRenderer(
      canvas,
      /*enableMSAA =*/ _offscreenGL._enableAntialiasCanvas
    );
  };

  const cppClear = Module["clearRenderer"];
  const cppResize = Module["resizeRenderer"];

  Module["clearRenderer"] = function (renderer, color) {
    // Resize WebGL surface if the canvas size changed.
    GL.makeContextCurrent(renderer._handle);
    const canvas = renderer._canvas;
    const w = canvas.clientWidth * window.devicePixelRatio || 1;
    const h = canvas.clientHeight * window.devicePixelRatio || 1;
    if (renderer._width != w || renderer._height != h) {
      canvas.width = w;
      canvas.height = h;
      cppResize(renderer["_ptr"], canvas.width, canvas.height);
      renderer._width = w;
      renderer._height = h;
    }
    cppClear(renderer["_ptr"], color);
  };

  Module["stringViewU8"] = function (start) {
    var wasmMemory = Module["wasmMemory"];
    var buffer = wasmMemory ? wasmMemory["buffer"] : Module["HEAPU8"]["buffer"];
    var data = wasmMemory
      ? new Uint8Array(buffer, buffer.byteOffset, buffer.byteLength)
      : Module["HEAPU8"];
    var current = start;
    while (data[current] != 0 && current < buffer.byteLength) {
      current++;
    }
    return new Uint8Array(buffer, start, current - start);
  };

  var nativeMakeGlyphPath = Module["makeGlyphPath"];
  var move = 0;
  var line = 1;
  var quad = 2;
  var cubic = 4;
  var close = 5;
  Module["makeGlyphPath"] = function (font, glyphId) {
    var glyph = nativeMakeGlyphPath(font, glyphId);
    var verbCount = glyph[3];
    var ptsPtr = glyph[1];
    var verbPtr = glyph[2];
    var verbs = Module["heapViewU8"](verbPtr, verbCount);

    let pointCount = 0;
    for (var verb of verbs) {
      switch (verb) {
        case move:
        case line:
          pointCount++;
          break;
        case quad:
          pointCount += 2;
          break;
        case cubic:
          pointCount += 3;
          break;
        default:
          break;
      }
    }

    const ptsStart = ptsPtr >> 2;
    return {
      "rawPath": glyph[0],
      "verbs": verbs,
      "points": Module["heapViewF32"](ptsStart, pointCount * 2),
    };
  };

  var nativeShapeText = Module["shapeText"];
  Module["shapeText"] = function (codeUnits, runsList, level) {
    var shapeResult = nativeShapeText(codeUnits, runsList, level);
    return {
      "rawResult": shapeResult,
      "results": Module["heapViewU8"](shapeResult),
    };
  };

  var nativeBreakLines = Module["breakLines"];
  Module["breakLines"] = function (shape, width, align, wrap) {
    var breakResult = nativeBreakLines(shape, width, align, wrap);
    return {
      "rawResult": breakResult,
      "results": Module["heapViewU8"](breakResult),
    };
  };

  var nativeFontFeatures = Module["fontFeatures"];
  Module["fontFeatures"] = function (font) {
    var featuresPtr = nativeFontFeatures(font);
    var heap = Module["heap"]();
    const view = new DataView(heap, featuresPtr);
    var dataPtr = view["getUint32"](0, true);
    var size = view["getUint32"](4, true);

    const dataView = new DataView(heap, dataPtr);

    var tags = [];
    for (var i = 0; i < size; i++) {
      var tag = dataView["getUint32"](i * 4, true);
      tags.push(tag);
    }

    Module["deleteFontFeatures"](featuresPtr);
    return tags;
  };

  Module["heap"] = function (start, length) {
    var wasmMemory = Module["wasmMemory"];
    if (!wasmMemory) {
      return Module["HEAPU8"]["buffer"];
    }
    return wasmMemory["buffer"];
  };

  Module["heapViewU8"] = function (start, length) {
    var wasmMemory = Module["wasmMemory"];
    if (!wasmMemory) {
      return new Uint8Array(Module["HEAPU8"]["buffer"], start, length);
    }
    return new Uint8Array(wasmMemory["buffer"], start, length);
  };

  Module["heapViewF32"] = function (start, length) {
    var wasmMemory = Module["wasmMemory"];
    if (!wasmMemory) {
      return new Float32Array(Module["HEAPF32"]["buffer"], start << 2, length);
    }
    return new Float32Array(wasmMemory["buffer"], start << 2, length);
  };

  Module["heapViewU32"] = function (start, length) {
    var wasmMemory = Module["wasmMemory"];
    if (!wasmMemory) {
      return new Uint32Array(Module["HEAPU32"]["buffer"], start << 2, length);
    }
    return new Uint32Array(wasmMemory["buffer"], start << 2, length);
  };

  var scriptingWorkspaceResponse = Module["scriptingWorkspaceResponse"];
  Module["scriptingWorkspaceResponse"] = function (workspace, workId) {
    var response = scriptingWorkspaceResponse(workspace, workId);
    var available = response[0];
    var dataPtr = response[1];
    var size = response[2];
    var data = available ? Module["heapViewU8"](dataPtr, size) : null;

    return {
      "available": available,
      "data": data,
    };
  };

  var scriptingWorkspaceHighlightRow = Module["scriptingWorkspaceHighlightRow"];
  Module["scriptingWorkspaceHighlightRow"] = function (workspace, name, row) {
    var response = scriptingWorkspaceHighlightRow(workspace, name, row);
    var count = response[0];
    var dataPtr = response[1];
    var data = Module["heapViewU32"](dataPtr >> 2, count);

    return data;
  };
};
