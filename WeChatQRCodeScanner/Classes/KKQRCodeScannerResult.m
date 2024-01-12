//
//  KKQRCodeScannerResult.m
//  WeChatQRCodeScanner
//
//  Created by king on 2021/2/3.
//

#import "KKQRCodeScannerResult.h"

@interface KKQRCodeScannerResult ()
/// 识别的内容
@property (nonatomic, copy) NSString *content;
/// 二维码区域 基于原始图像坐标区域
@property (nonatomic, assign) CGRect rectOfImage;
/// 二维码区域 基于当前扫描容器View坐标系区域
@property (nonatomic, assign) CGRect rectOfView;
@end

@implementation KKQRCodeScannerResult

- (instancetype)initWithContent:(NSString *)content rectOfImage:(CGRect)rectOfImage rectOfView:(CGRect)rectOfView {
    if (self == [super init]) {
        _content = content;
        _rectOfImage = rectOfImage;
        _rectOfView = rectOfView;
    }
    return self;
}
@end
