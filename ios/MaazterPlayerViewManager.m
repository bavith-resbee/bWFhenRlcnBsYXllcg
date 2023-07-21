#import "React/RCTViewManager.h"

@interface RCT_EXTERN_MODULE(MaazterPlayerViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(theme, NSString)
RCT_EXPORT_VIEW_PROPERTY(buttonState, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(source, NSDictionary)
RCT_EXPORT_VIEW_PROPERTY(resizeMode, NSString)

RCT_EXPORT_VIEW_PROPERTY(onChangeResizeMode, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onProgress, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFullscreenChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onQualityChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPlaybackSpeedChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPlayStateChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onVideoSizeChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onCreate, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onDestroy, RCTDirectEventBlock)

RCT_EXPORT_VIEW_PROPERTY(onBackClick, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onNextClick, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPreviousClick, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onSettingsClick, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFullscreenClick, RCTDirectEventBlock)

RCT_EXTERN_METHOD(play: (nonnull NSNumber *)node)
RCT_EXTERN_METHOD(pause: (nonnull NSNumber *)node)
RCT_EXTERN_METHOD(setFullscreen: (nonnull NSNumber *)node isFullscreen:(BOOL *)isFullscreen)


@end
