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
@property (nonatomic, weak) IBOutlet UILabel *tipsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchView;

@end

@implementation KKViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.title = @"微信二维码识别引擎";

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

	self.tipsLabel.textColor = UIColor.orangeColor;
	self.tipsLabel.text      = @"";
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.scannerView.delegate = self;
	//	[self.scannerView startScanner];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	//	[self.scannerView stopScanner];
}

- (IBAction)switchValueChanged:(UISwitch *)sender {

	if (sender.isOn) {
		[self.scannerView startScanner];
	} else {
		[self.scannerView stopScanner];
	}
}

#pragma mark - KKQRCodeScannerViewDelegate
- (BOOL)qrcodeScannerView:(KKQRCodeScannerView *)scannerView didScanner:(NSArray<NSString *> *)results elapsedTime:(NSTimeInterval)elapsedTime {
	if (!results || results.count == 0) {
		return NO;
	}
	self.switchView.on    = NO;
	NSMutableString *text = [NSMutableString string];
	for (NSString *str in results) {
		[text appendFormat:@"\n%@", str];
	}
	[text appendFormat:@"\n耗时: %fs", elapsedTime];

	self.tipsLabel.text = text;

	return NO;
}
@end

