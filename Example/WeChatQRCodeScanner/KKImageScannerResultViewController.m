//
//  KKImageScannerResultViewController.m
//  WeChatQRCodeScanner_Example
//
//  Created by king on 2021/2/27.
//  Copyright © 2021 0x1306a94. All rights reserved.
//

#import "KKImageScannerResultViewController.h"

@import AVFoundation.AVUtilities;

@interface KKImageScannerResultViewController ()
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation KKImageScannerResultViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view from its nib.
	[self.view addSubview:self.imageView];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	CGRect frame         = AVMakeRectWithAspectRatioInsideRect(self.image.size, self.view.bounds);
	self.imageView.frame = frame;
	self.imageView.image = self.image;
}

#pragma mark - lazy
- (UIImageView *)imageView {
	if (!_imageView) {
		_imageView             = [[UIImageView alloc] init];
		_imageView.contentMode = UIViewContentModeScaleAspectFit;
	}
	return _imageView;
}

@end

