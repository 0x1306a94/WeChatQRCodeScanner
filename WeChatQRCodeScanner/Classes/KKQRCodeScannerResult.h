//
//  KKQRCodeScannerResult.h
//  WeChatQRCodeScanner
//
//  Created by king on 2021/2/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKQRCodeScannerResult : NSObject
/// 识别的内容
@property (nonatomic, copy, readonly) NSString *content;
/// 二维码区域 基于原始图像坐标区域
@property (nonatomic, assign, readonly) CGRect rectOfImage;
/// 二维码区域 基于当前扫描容器View坐标系区域
@property (nonatomic, assign, readonly) CGRect rectOfView;

- (instancetype)initWithContent:(NSString *)content rectOfImage:(CGRect)rectOfImage rectOfView:(CGRect)rectOfView;
@end

NS_ASSUME_NONNULL_END

