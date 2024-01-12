//
//  KKQRCodeImageScanner.h
//  Pods
//
//  Created by king on 2021/2/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KKQRCodeScannerResult;
@class UIImage;

@interface KKQRCodeImageScanner : NSObject

- (NSArray<KKQRCodeScannerResult *> *)scannerForImage:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
