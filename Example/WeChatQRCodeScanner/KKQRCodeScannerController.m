//
//  KKQRCodeScannerController.m
//  WeChatQRCodeScanner_Example
//
//  Created by king on 2021/2/3.
//  Copyright © 2021 0x1306a94. All rights reserved.
//

#import "KKQRCodeScannerController.h"

#import <WeChatQRCodeScanner/KKQRCodeScannerResult.h>
#import <WeChatQRCodeScanner/KKQRCodeScannerView.h>

@interface KKQRCodeScannerController () <KKQRCodeScannerViewDelegate>
@property (nonatomic, strong) KKQRCodeScannerView *scannerView;
@property (nonatomic, weak) IBOutlet UILabel *tipsLabel;

@property (nonatomic, strong) CALayer *containerLayer;
@property (nonatomic, strong) NSMutableArray<CAShapeLayer *> *reuseMarkLayers;
@end

@implementation KKQRCodeScannerController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.scannerView = [[KKQRCodeScannerView alloc] initWithFrame:self.view.bounds];

    self.scannerView.backgroundColor = UIColor.whiteColor;

    [self.view insertSubview:self.scannerView atIndex:0];

    self.scannerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.scannerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scannerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.scannerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scannerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    self.tipsLabel.textColor = UIColor.redColor;
    self.tipsLabel.text = @"";

    self.reuseMarkLayers = [NSMutableArray<CAShapeLayer *> arrayWithCapacity:5];

    self.containerLayer = [CALayer layer];
    self.containerLayer.backgroundColor = UIColor.clearColor.CGColor;

    [self.scannerView.layer addSublayer:self.containerLayer];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.scannerView.delegate = self;
    self.containerLayer.frame = self.scannerView.layer.bounds;
    [self.scannerView startScanner:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.scannerView.delegate = nil;
    [self.scannerView stopScanner];
}

#pragma mark - clear
- (void)clearMarkLayers {
    if (self.containerLayer.sublayers.count > 0) {
        [self.reuseMarkLayers addObjectsFromArray:self.containerLayer.sublayers];
        [self.containerLayer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    }
}

#pragma mark - KKQRCodeScannerViewDelegate
- (BOOL)qrcodeScannerView:(KKQRCodeScannerView *)scannerView didScanner:(NSArray<KKQRCodeScannerResult *> *)results elapsedTime:(NSTimeInterval)elapsedTime {
    [self clearMarkLayers];
    if (!results || results.count == 0) {
        self.tipsLabel.text = @"";
        return NO;
    }
    NSMutableString *text = [NSMutableString string];
    for (KKQRCodeScannerResult *element in results) {
        [text appendFormat:@"\n%@", element.content];

        CAShapeLayer *markLayer = nil;
        if (self.reuseMarkLayers.count > 0) {
            markLayer = self.reuseMarkLayers.lastObject;
            [self.reuseMarkLayers removeLastObject];
        } else {
            markLayer = [CAShapeLayer layer];
            markLayer.fillColor = UIColor.clearColor.CGColor;
            markLayer.strokeColor = UIColor.greenColor.CGColor;
            markLayer.lineWidth = 2;
            markLayer.fillRule = kCAFillRuleEvenOdd;
        }

        UIBezierPath *path = [UIBezierPath bezierPathWithRect:element.rectOfView];
        markLayer.path = path.CGPath;
        [self.containerLayer addSublayer:markLayer];
    }
    [text appendFormat:@"\n耗时: %fs", elapsedTime];

    self.tipsLabel.text = text;

    return NO;
}

@end
