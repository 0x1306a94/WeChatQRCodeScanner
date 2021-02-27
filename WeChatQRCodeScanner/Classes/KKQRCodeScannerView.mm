//
//  KKQRCodeScannerView.m
//  WeChatQRCodeScanner
//
//  Created by king on 2021/2/1.
//

#import "KKQRCodeScannerView.h"

#import "KKQRCodeScannerResult.h"

#import <AVFoundation/AVFoundation.h>

#import <opencv2/Mat.h>
#import <opencv2/WeChatQRCode.h>
#import <opencv2/core/hal/interface.h>

@interface KKQRCodeScannerView () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign) cv::Ptr<cv::wechat_qrcode::WeChatQRCode> detector;
//@property (nonatomic, strong) dispatch_queue_t workQueue;
@property (nonatomic, assign) BOOL stoped;
@end

@implementation KKQRCodeScannerView
#if DEBUG
- (void)dealloc {
	NSLog(@"[%@ dealloc]", NSStringFromClass(self.class));
}
#endif

+ (Class)layerClass {
	return AVCaptureVideoPreviewLayer.class;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
	return (AVCaptureVideoPreviewLayer *)self.layer;
}

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

	self.stoped = NO;

	//		self.workQueue = dispatch_queue_create("com.0x1306a94.qrcode.scanner.workqueue", DISPATCH_QUEUE_SERIAL);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	if (self.stoped) {
		return;
	}
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
	std::vector<std::string> res = self.detector->detectAndDecode(flipMat, points);

	NSTimeInterval elapsedTime = CACurrentMediaTime() - start;
	if (self.stoped) {
		return;
	}

	NSMutableArray<KKQRCodeScannerResult *> *results = nil;
	if (res.size() > 0) {

		size_t size = res.size();

		results = [NSMutableArray<KKQRCodeScannerResult *> arrayWithCapacity:size];

		for (size_t i = 0; i < size; i++) {
			NSString *content = [NSString stringWithCString:res[i].c_str() encoding:NSUTF8StringEncoding];
			cv::Mat &m        = points[i];

			CGPoint topLeft    = CGPointMake(m.at<float>(0, 0), m.at<float>(0, 1));
			CGPoint topRight   = CGPointMake(m.at<float>(1, 0), m.at<float>(1, 1));
			CGPoint bottomLeft = CGPointMake(m.at<float>(2, 0), m.at<float>(2, 1));
			//			CGPoint bottomRight = CGPointMake(m.at<float>(3, 0), m.at<float>(3, 1));
			CGRect rectOfImage = (CGRect){topLeft, CGSizeMake(topRight.x - topLeft.x, bottomLeft.y - topLeft.y)};

			CGFloat sx = CGRectGetWidth(self.bounds) / h;
			CGFloat sy = CGRectGetHeight(self.bounds) / w;

			CGAffineTransform transform = CGAffineTransformIdentity;

			transform         = CGAffineTransformScale(transform, sx, sy);
			CGRect rectOfView = CGRectApplyAffineTransform(rectOfImage, transform);

			KKQRCodeScannerResult *r = [[KKQRCodeScannerResult alloc] initWithContent:content rectOfImage:rectOfImage rectOfView:rectOfView];
			[results addObject:r];
		}
	}
	if (self.delegate && [self.delegate qrcodeScannerView:self didScanner:results elapsedTime:elapsedTime]) {
		self.stoped = YES;
	}
}

#pragma mark - public method
- (void)startScanner:(NSError *__autoreleasing _Nullable *)error {

	NSError *err;

	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	[device lockForConfiguration:&err];
	if (err) {
		if (error) {
			*error = err;
		}
		return;
	}
	//	if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
	//		[device setFocusMode:AVCaptureFocusModeAutoFocus];
	//	}
	device.activeVideoMaxFrameDuration = CMTimeMake(1, 25);
	[device unlockForConfiguration];

	self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&err];
	if (err) {
		if (error) {
			*error = err;
		}
		return;
	}

	self.session = [[AVCaptureSession alloc] init];

	//	self.session.sessionPreset = AVCaptureSessionPreset1280x720;

	if ([self.session canAddInput:self.videoInput]) {
		[self.session addInput:self.videoInput];
	}

	self.dataOutput               = [[AVCaptureVideoDataOutput alloc] init];
	NSString *key                 = (NSString *)kCVPixelBufferPixelFormatTypeKey;
	NSNumber *value               = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
	NSDictionary *videoSettings   = [NSDictionary dictionaryWithObject:value forKey:key];
	self.dataOutput.videoSettings = videoSettings;
	// 延迟的视频帧都被丢弃
	self.dataOutput.alwaysDiscardsLateVideoFrames = YES;
	[self.dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
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

	self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	self.previewLayer.session      = self.session;

	if (!self.session.isRunning) {
		self.stoped = NO;
		[self.session startRunning];
	}
}

- (void)stopScanner {
	if (self.session && self.session.isRunning) {
		self.stoped = YES;
		[self.session stopRunning];
		self.session    = nil;
		self.videoInput = nil;
		self.dataOutput = nil;
	}
}
@end

