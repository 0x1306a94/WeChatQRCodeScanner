//
//  KKQRCodeScannerView.m
//  WeChatQRCodeScanner
//
//  Created by king on 2021/2/1.
//

#import "KKQRCodeScannerView.h"

#import <AVFoundation/AVFoundation.h>

#import <opencv2/Mat.h>
#import <opencv2/WeChatQRCode.h>
#import <opencv2/core/hal/interface.h>

@interface KKQRCodeScannerView () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign) cv::Ptr<cv::wechat_qrcode::WeChatQRCode> detector;
@property (nonatomic, strong) CALayer *containerLayer;
@property (nonatomic, strong) NSMutableArray<CAShapeLayer *> *reuseMarkLayers;
@property (nonatomic, strong) dispatch_queue_t workQueue;
@property (nonatomic, assign) BOOL stoped;
@end

@implementation KKQRCodeScannerView

#pragma mark - life cycle
- (instancetype)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		[self commonInit];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
		[self commonInit];
	}
	return self;
}

#pragma mark - Initial Methods
- (void)commonInit {
	/*custom view u want draw in here*/
	self.backgroundColor = [UIColor blackColor];

	NSBundle *mainBundle                        = [NSBundle bundleForClass:self.class];
	NSBundle *bundle                            = [NSBundle bundleWithPath:[mainBundle pathForResource:@"WeChatQRCodeScanner" ofType:@"bundle"]];
	NSString *detector_prototxt_path            = [bundle pathForResource:@"detect" ofType:@"prototxt" inDirectory:@"wechat_qrcode"];
	NSString *detector_caffe_model_path         = [bundle pathForResource:@"detect" ofType:@"caffemodel" inDirectory:@"wechat_qrcode"];
	NSString *super_resolution_prototxt_path    = [bundle pathForResource:@"sr" ofType:@"prototxt" inDirectory:@"wechat_qrcode"];
	NSString *super_resolution_caffe_model_path = [bundle pathForResource:@"sr" ofType:@"caffemodel" inDirectory:@"wechat_qrcode"];

	//	self.detector = [[WeChatQRCode alloc] initWithDetector_prototxt_path:detector_prototxt_path detector_caffe_model_path:detector_caffe_model_path super_resolution_prototxt_path:super_resolution_prototxt_path super_resolution_caffe_model_path:super_resolution_caffe_model_path];

	//	self.detector = [[WeChatQRCode alloc] init];

	_detector = cv::makePtr<cv::wechat_qrcode::WeChatQRCode>(detector_prototxt_path.UTF8String,
	                                                         detector_caffe_model_path.UTF8String,
	                                                         super_resolution_prototxt_path.UTF8String,
	                                                         super_resolution_caffe_model_path.UTF8String);

	self.reuseMarkLayers = [NSMutableArray<CAShapeLayer *> arrayWithCapacity:5];

	self.stoped = NO;

	self.workQueue = dispatch_queue_create("com.0x1306a94.qrcode.scanner.workqueue", DISPATCH_QUEUE_SERIAL);

	[self initAVCaptureSession];

	self.containerLayer                 = [CALayer layer];
	self.containerLayer.backgroundColor = UIColor.clearColor.CGColor;

	[self.layer addSublayer:self.containerLayer];
}

- (void)initAVCaptureSession {
	self.session = [[AVCaptureSession alloc] init];

	self.session.sessionPreset = AVCaptureSessionPreset1280x720;

	NSError *error;

	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	[device lockForConfiguration:&error];

	if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
		[device setFocusMode:AVCaptureFocusModeAutoFocus];
	}
	device.activeVideoMaxFrameDuration = CMTimeMake(1, 25);
	[device unlockForConfiguration];

	self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
	if (error) {
		NSLog(@"%@", error);
	}

	if ([self.session canAddInput:self.videoInput]) {
		[self.session addInput:self.videoInput];
	}

	self.dataOutput               = [[AVCaptureVideoDataOutput alloc] init];
	NSString *key                 = (NSString *)kCVPixelBufferPixelFormatTypeKey;
	NSNumber *value               = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
	NSDictionary *videoSettings   = [NSDictionary dictionaryWithObject:value forKey:key];
	self.dataOutput.videoSettings = videoSettings;
	[self.dataOutput setSampleBufferDelegate:self queue:self.workQueue];
	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in self.dataOutput.connections) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) {
			break;
		}
	}

	videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;

	if ([self.session canAddOutput:self.dataOutput]) {
		[self.session addOutput:self.dataOutput];
	}

	self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
	[self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	[self.layer addSublayer:self.previewLayer];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	self.previewLayer.frame   = self.bounds;
	self.containerLayer.frame = self.bounds;
}

#pragma mark - clear
- (void)clearMarkLayers {
	if (self.containerLayer.sublayers.count > 0) {
		[self.reuseMarkLayers addObjectsFromArray:self.containerLayer.sublayers];
		[self.containerLayer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
	}
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	if (self.stoped) {
		return;
	}
	@autoreleasepool {
		CVImageBufferRef imgBuf = CMSampleBufferGetImageBuffer(sampleBuffer);

		CVPixelBufferLockBaseAddress(imgBuf, 0);

		void *imgBufAddr = CVPixelBufferGetBaseAddressOfPlane(imgBuf, 0);

		int w = (int)CVPixelBufferGetWidth(imgBuf);
		int h = (int)CVPixelBufferGetHeight(imgBuf);

		cv::Mat mat(h, w, CV_8UC4, imgBufAddr, 0);

		cv::Mat transMat;
		cv::transpose(mat, transMat);

		cv::Mat flipMat;
		cv::flip(transMat, flipMat, 1);

		CVPixelBufferUnlockBaseAddress(imgBuf, 0);

		NSTimeInterval start = CACurrentMediaTime();

		std::vector<cv::Mat> points;
		std::vector<std::string> result = self.detector->detectAndDecode(flipMat, points);

		NSTimeInterval elapsedTime = CACurrentMediaTime() - start;
#if DEBUG
		NSLog(@"耗时: %f", elapsedTime);
#endif

		dispatch_async(dispatch_get_main_queue(), ^{
			[self clearMarkLayers];

			if (result.size() > 0 && self.delegate) {

				NSMutableArray<NSString *> *transformResult = [NSMutableArray<NSString *> arrayWithCapacity:result.size()];
				for (const std::string &e : result) {
					NSString *str = [NSString stringWithCString:e.c_str() encoding:NSUTF8StringEncoding];
					[transformResult addObject:str];
				}
#if DEBUG
				NSLog(@"识别到内容: \n%@", transformResult);
#endif
				for (const cv::Mat &m : points) {
					CGPoint topLeft    = CGPointMake(m.at<float>(0, 0), m.at<float>(0, 1));
					CGPoint topRight   = CGPointMake(m.at<float>(1, 0), m.at<float>(1, 1));
					CGPoint bottomLeft = CGPointMake(m.at<float>(2, 0), m.at<float>(2, 1));
					//			CGPoint bottomRight = CGPointMake(m.at<float>(3, 0), m.at<float>(3, 1));
					CGRect rect = (CGRect){topLeft, CGSizeMake(topRight.x - topLeft.x, bottomLeft.y - topLeft.y)};
#if DEBUG
					NSLog(@"rect: %@", NSStringFromCGRect(rect));
#endif
					CGFloat sx = CGRectGetWidth(self.bounds) / h;
					CGFloat sy = CGRectGetHeight(self.bounds) / w;

					CGAffineTransform transform = CGAffineTransformIdentity;

					transform = CGAffineTransformScale(transform, sx, sy);
					rect      = CGRectApplyAffineTransform(rect, transform);
#if DEBUG
					NSLog(@"rect: %@", NSStringFromCGRect(rect));
#endif
					CAShapeLayer *markLayer = nil;
					if (self.reuseMarkLayers.count > 0) {
						markLayer = self.reuseMarkLayers.lastObject;
						[self.reuseMarkLayers removeLastObject];
					} else {
						markLayer             = [CAShapeLayer layer];
						markLayer.fillColor   = UIColor.clearColor.CGColor;
						markLayer.strokeColor = UIColor.greenColor.CGColor;
						markLayer.lineWidth   = 2;
						markLayer.fillRule    = kCAFillRuleEvenOdd;
					}

					UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
					markLayer.path     = path.CGPath;
					[self.containerLayer addSublayer:markLayer];
				}

				if ([self.delegate qrcodeScannerView:self didScanner:transformResult elapsedTime:elapsedTime]) {
					self.stoped = YES;
					[self.session stopRunning];
				}
			}
		});
	}
}

#pragma mark - public method
- (void)startScanner {
	dispatch_async(self.workQueue, ^{
		if (!self.session.isRunning) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self clearMarkLayers];
			});
			self.stoped = NO;
			[self.session startRunning];
		}
	});
}

- (void)stopScanner {
	dispatch_async(self.workQueue, ^{
		if (self.session.isRunning) {
			self.stoped = YES;
			[self.session stopRunning];
		}
	});
}
@end

