//
//  KKViewController.m
//  WeChatQRCodeScanner
//
//  Created by 0x1306a94 on 02/01/2021.
//  Copyright (c) 2021 0x1306a94. All rights reserved.
//

#import "KKViewController.h"

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
	UIImage *image                            = [UIImage imageNamed:@"test3"];
	NSArray<KKQRCodeScannerResult *> *results = [self.scanner scannerForImage:image];
	[results enumerateObjectsUsingBlock:^(KKQRCodeScannerResult *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
		NSLog(@"\n%@\ncontent: %@\nrectOfImage %@\n", obj, obj.content, NSStringFromCGRect(obj.rectOfImage));
	}];
}

#pragma mark - lazy
- (KKQRCodeImageScanner *)scanner {
	if (!_scanner) {
		_scanner = [[KKQRCodeImageScanner alloc] init];
	}
	return _scanner;
}
@end

