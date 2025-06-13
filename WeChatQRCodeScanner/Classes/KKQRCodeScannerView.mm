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
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
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

    NSBundle *mainBundle = [NSBundle bundleForClass:self.class];
    NSBundle *bundle = [NSBundle bundleWithPath:[mainBundle pathForResource:@"WeChatQRCodeScanner" ofType:@"bundle"]];
    NSString *detector_prototxt_path = [bundle pathForResource:@"detect" ofType:@"prototxt" inDirectory:@"wechat_qrcode"];
    NSString *detector_caffe_model_path = [bundle pathForResource:@"detect" ofType:@"caffemodel" inDirectory:@"wechat_qrcode"];
    NSString *super_resolution_prototxt_path = [bundle pathForResource:@"sr" ofType:@"prototxt" inDirectory:@"wechat_qrcode"];
    NSString *super_resolution_caffe_model_path = [bundle pathForResource:@"sr" ofType:@"caffemodel" inDirectory:@"wechat_qrcode"];

    //    self.detector = [[WeChatQRCode alloc] initWithDetector_prototxt_path:detector_prototxt_path detector_caffe_model_path:detector_caffe_model_path super_resolution_prototxt_path:super_resolution_prototxt_path super_resolution_caffe_model_path:super_resolution_caffe_model_path];

    //    self.detector = [[WeChatQRCode alloc] init];

    _detector = cv::makePtr<cv::wechat_qrcode::WeChatQRCode>(detector_prototxt_path.UTF8String,
                                                             detector_caffe_model_path.UTF8String,
                                                             super_resolution_prototxt_path.UTF8String,
                                                             super_resolution_caffe_model_path.UTF8String);

    self.stoped = NO;

    //        self.workQueue = dispatch_queue_create("com.0x1306a94.qrcode.scanner.workqueue", DISPATCH_QUEUE_SERIAL);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.stoped) {
        return;
    }
    CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    int bufferWidth = (int)CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);

    cv::Mat sourceMat(bufferHeight, bufferWidth, CV_8UC4, pixel, CVPixelBufferGetBytesPerRow(pixelBuffer));
    cv::Mat processedMat = sourceMat;
    //    cv::transpose(sourceMat, processedMat);
    if (!CVImageBufferIsFlipped(pixelBuffer)) {
        //        cv::Mat transMat;
        //        cv::transpose(sourceMat, transMat);
        // 将原点坐标翻转为左上角
        cv::flip(sourceMat, processedMat, 1);
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    NSTimeInterval start = CACurrentMediaTime();

    std::vector<cv::Mat> points;
    std::vector<std::string> res = self.detector->detectAndDecode(processedMat, points);

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

            auto pt1 = cv::Point((int)points[i].at<float>(0, 0), (int)points[i].at<float>(0, 1));
            auto pt2 = cv::Point((int)points[i].at<float>(1, 0), (int)points[i].at<float>(1, 1));
            auto pt3 = cv::Point((int)points[i].at<float>(2, 0), (int)points[i].at<float>(2, 1));
            auto pt4 = cv::Point((int)points[i].at<float>(3, 0), (int)points[i].at<float>(3, 1));

            auto minX = std::min({pt1.x, pt2.x, pt3.x, pt4.x});
            auto maxX = std::max({pt1.x, pt2.x, pt3.x, pt4.x});
            auto minY = std::min({pt1.y, pt2.y, pt3.y, pt4.y});
            auto maxY = std::max({pt1.y, pt2.y, pt3.y, pt4.y});

            CGRect rectOfImage = CGRectMake(minX, minY, maxX - minX, maxY - minY);

            CGRect normalizedRect = CGRectMake(
                rectOfImage.origin.x / bufferWidth,
                rectOfImage.origin.y / bufferHeight,
                rectOfImage.size.width / bufferWidth,
                rectOfImage.size.height / bufferHeight);

            CGRect rectOfView = [self.previewLayer rectForMetadataOutputRectOfInterest:normalizedRect];

            KKQRCodeScannerResult *r = [[KKQRCodeScannerResult alloc] initWithContent:content rectOfImage:rectOfImage rectOfView:rectOfView];
            [results addObject:r];
        }
    }

    if (self.delegate && [self.delegate qrcodeScannerView:self didScanner:results elapsedTime:elapsedTime]) {
        self.stoped = YES;
    }
}

- (void)autoFocus {
    CGPoint pointOfInterest = CGPointMake(0.5, 0.5);
    NSError *error = nil;
    if ([self.captureDevice lockForConfiguration:&error]) {
        if ([self.captureDevice isFocusPointOfInterestSupported]) {
            [self.captureDevice setFocusPointOfInterest:pointOfInterest];
        }

        if ([self.captureDevice isSmoothAutoFocusEnabled]) {
            [self.captureDevice setSmoothAutoFocusEnabled:YES];
        }

        if ([self.captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [self.captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }

        //曝光
        if ([self.captureDevice isExposurePointOfInterestSupported]) {
            [self.captureDevice setExposurePointOfInterest:pointOfInterest];
        }

        if ([self.captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [self.captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
    }
    [self.captureDevice unlockForConfiguration];
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

    if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        device.focusPointOfInterest = CGPointMake(0.5, 0.5);
        device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    }

    if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        device.exposurePointOfInterest = CGPointMake(0.5, 0.5);
        device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    }

    //默认关闭闪光灯
    //    if ([device hasFlash]) {
    //        device.flashMode = AVCaptureFlashModeOff;
    //    }

    // 增强低光模式
    if (device.isLowLightBoostSupported) {
        device.automaticallyEnablesLowLightBoostWhenAvailable = YES;
    }

    //白平衡
    if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
        [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
    }

    device.subjectAreaChangeMonitoringEnabled = YES;
    //    device.activeVideoMinFrameDuration = CMTimeMake(20, 30 * 10);
    //    device.activeVideoMaxFrameDuration = device.activeVideoMinFrameDuration;
    [device unlockForConfiguration];

    self.captureDevice = device;
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&err];
    if (err) {
        if (error) {
            *error = err;
        }
        return;
    }

    self.session = [[AVCaptureSession alloc] init];

    //    self.session.sessionPreset = AVCaptureSessionPreset1280x720;

    if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
    }

    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }

    self.dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    NSString *key = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber *value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
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

    //            videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    //    videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    if ([self.session canAddOutput:self.dataOutput]) {
        [self.session addOutput:self.dataOutput];
    }

    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.session = self.session;

    //添加通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoFocus) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:device];

    if (!self.session.isRunning) {
        self.stoped = NO;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self.session startRunning];
        });
    }
}

- (void)stopScanner {
    if (self.session && self.session.isRunning) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.captureDevice];
        self.stoped = YES;
        [self.session stopRunning];
        self.captureDevice = nil;
        self.session = nil;
        self.videoInput = nil;
        self.dataOutput = nil;
    }
}
@end
