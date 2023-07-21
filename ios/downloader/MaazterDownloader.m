#import <React/RCTEventEmitter.h>

@interface RCT_EXTERN_MODULE(MaazterDownloader, RCTEventEmitter)
RCT_EXTERN_METHOD(add: (nonnull NSString *)contentUri
        encKey: (NSString *)enckey
        quality: (nonnull NSString *)quality
        data: (NSString *)data
        resolve: (RCTPromiseResolveBlock)resolve
        reject: (RCTPromiseRejectBlock)reject
)
RCT_EXTERN_METHOD(remove: (nonnull NSString *)contentId)
RCT_EXTERN_METHOD(pause: (nonnull NSString *)contentId reason: (NSInteger *)reason)
RCT_EXTERN_METHOD(resume: (nonnull NSString *)contentId)
RCT_EXTERN_METHOD(pauseAll)
RCT_EXTERN_METHOD(resumeAll)
RCT_EXTERN_METHOD(getTracks: (nonnull NSString *)contentUri
        encKey: (NSString *)enckey
        resolve: (RCTPromiseResolveBlock)resolve
        reject: (RCTPromiseRejectBlock)reject
)
RCT_EXTERN_METHOD(listDownloads: (RCTPromiseResolveBlock)resolve reject: (RCTPromiseRejectBlock)reject)
@end
