//
//  KKViewController.m
//  WeChatQRCodeScanner
//
//  Created by 0x1306a94 on 02/01/2021.
//  Copyright (c) 2021 0x1306a94. All rights reserved.
//

#import "KKViewController.h"

#import "KKQRCodeScannerController.h"

@interface KKViewController ()

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
@end

