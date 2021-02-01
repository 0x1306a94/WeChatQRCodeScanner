//
//  KKViewController.m
//  WeChatQRCodeScanner
//
//  Created by 0x1306a94 on 02/01/2021.
//  Copyright (c) 2021 0x1306a94. All rights reserved.
//

#import "KKViewController.h"

#import <WeChatQRCodeScanner/KKQRCodeScannerView.h>

@interface KKViewController () <KKQRCodeScannerViewDelegate>
@property (nonatomic, strong) KKQRCodeScannerView *scannerView;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@end

@implementation KKViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.scannerView = [[KKQRCodeScannerView alloc] initWithFrame:self.view.bounds];

    [self.view insertSubview:self.scannerView atIndex:0];

    self.textView.textColor       = UIColor.orangeColor;
    self.textView.backgroundColor = UIColor.clearColor;
    self.textView.text            = @"";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.scannerView.frame = self.view.bounds;
    self.scannerView.delegate = self;
    [self.scannerView startScanner];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.scannerView stopScanner];
}

#pragma mark - kk
- (void)qrcodeScannerView:(KKQRCodeScannerView *)scannerView didScanner:(NSArray<NSString *> *)results {
    if (!results || results.count == 0) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *text = self.textView.text;
        for (NSString *str in results) {
            text = [text stringByAppendingFormat:@"\n%@", str];
        }
        self.textView.text = text;
        [self.textView scrollRangeToVisible:NSMakeRange(text.length - 1, 1)];
    });
}
@end

