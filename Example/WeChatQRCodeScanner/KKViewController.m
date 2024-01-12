//
//  KKViewController.m
//  WeChatQRCodeScanner
//
//  Created by 0x1306a94 on 02/01/2021.
//  Copyright (c) 2021 0x1306a94. All rights reserved.
//

#import "KKViewController.h"

#import "KKImageScannerResultViewController.h"
#import "KKQRCodeScannerController.h"

#import <WeChatQRCodeScanner/KKQRCodeImageScanner.h>
#import <WeChatQRCodeScanner/KKQRCodeScannerResult.h>

@interface KKViewController ()
@property (nonatomic, strong) KKQRCodeImageScanner *scanner;
@end

@implementation KKViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"微信二维码识别引擎";
}

- (IBAction)scannerButtonAction:(UIButton *)sender {
    KKQRCodeScannerController *vc = [[KKQRCodeScannerController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)imageScannerButtonAction:(UIButton *)sender {
    UIImage *image = [UIImage imageNamed:@"test3"];
    NSTimeInterval start = CACurrentMediaTime();
    NSArray<KKQRCodeScannerResult *> *results = [self.scanner scannerForImage:image];
    NSTimeInterval elapsedTime = CACurrentMediaTime() - start;
    if (!results) {
        return;
    }
    NSMutableString *string = [NSMutableString stringWithFormat:@"\n>>>>>>>>>>>>>>>> 识别结果 >>>>>>>>>>>>>>>>\n"];
    [string appendFormat:@"耗时: %fs\n", elapsedTime];
    [results enumerateObjectsUsingBlock:^(KKQRCodeScannerResult *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
        [string appendFormat:@"%@\ncontent: %@\nrectOfImage %@\n", obj, obj.content, NSStringFromCGRect(obj.rectOfImage)];
        [string appendString:@"-----------------------------------\n"];
    }];

    NSLog(@"%@", string);

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = 1.0;

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:image.size format:format];

    UIImage *drawImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext) {
        [image drawAtPoint:CGPointZero];
        do {
            UIBezierPath *path = [UIBezierPath bezierPathWithRect:renderer.format.bounds];
            path.lineWidth = 5;
            [UIColor.redColor setStroke];
            [path stroke];
        } while (0);

        for (KKQRCodeScannerResult *item in results) {
            UIBezierPath *path = [UIBezierPath bezierPathWithRect:item.rectOfImage];
            path.lineWidth = 5;
            [UIColor.yellowColor setStroke];
            [path stroke];
        }
    }];

    KKImageScannerResultViewController *vc = [[KKImageScannerResultViewController alloc] init];

    vc.image = drawImage;

    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - lazy
- (KKQRCodeImageScanner *)scanner {
    if (!_scanner) {
        _scanner = [[KKQRCodeImageScanner alloc] init];
    }
    return _scanner;
}
@end
