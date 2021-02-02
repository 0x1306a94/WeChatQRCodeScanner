//
//  KKQRCodeScannerView.h
//  WeChatQRCodeScanner
//
//  Created by king on 2021/2/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KKQRCodeScannerViewDelegate;

@interface KKQRCodeScannerView : UIView
@property (nonatomic, weak) id<KKQRCodeScannerViewDelegate> delegate;

- (void)startScanner;
- (void)stopScanner;
@end

@protocol KKQRCodeScannerViewDelegate <NSObject>

@required
- (BOOL)qrcodeScannerView:(KKQRCodeScannerView *)scannerView didScanner:(NSArray<NSString *> *)results elapsedTime:(NSTimeInterval)elapsedTime;
@end
NS_ASSUME_NONNULL_END

