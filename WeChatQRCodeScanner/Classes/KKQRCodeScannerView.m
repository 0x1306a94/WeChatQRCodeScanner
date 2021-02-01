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
@property (nonatomic, strong) WeChatQRCode *detector;

@property (nonatomic, strong) dispatch_queue_t workQueue;
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

    self.workQueue = dispatch_queue_create("com.0x1306a94.qrcode.scanner.workqueue", DISPATCH_QUEUE_SERIAL);

    self.detector = [[WeChatQRCode alloc] init];

    [self initAVCaptureSession];
}

- (void)initAVCaptureSession {
    self.session = [[AVCaptureSession alloc] init];
    //    self.session.sessionPreset = AVCaptureSessionPresetPhoto;

    NSError *error;

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //    if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
    //        NSError *error = nil;
    //        //对cameraDevice进行操作前，需要先锁定，防止其他线程访问，
    //        [device lockForConfiguration:&error];
    //        [device setFocusMode:AVCaptureFocusModeAutoFocus];
    //        //操作完成后，记得进行unlock。
    //        [device unlockForConfiguration];
    //    }

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
    [self.dataOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(0, 0)];
    if ([self.session canAddOutput:self.dataOutput]) {
        [self.session addOutput:self.dataOutput];
    }
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.layer addSublayer:self.previewLayer];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.previewLayer.frame = self.bounds;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {

    CVImageBufferRef imgBuf = CMSampleBufferGetImageBuffer(sampleBuffer);

    // lock the buffer
    CVPixelBufferLockBaseAddress(imgBuf, 0);

    // get the address to the image data
    void *imgBufAddr = CVPixelBufferGetBaseAddressOfPlane(imgBuf, 0);

    // get image properties
    int w = (int)CVPixelBufferGetWidth(imgBuf);
    int h = (int)CVPixelBufferGetHeight(imgBuf);

    NSData *data = [NSData dataWithBytes:imgBufAddr length:w * h * 4];
    Mat *image   = [[Mat alloc] initWithRows:h cols:w type:CV_8UC4 data:data];
    // unlock again
    CVPixelBufferUnlockBaseAddress(imgBuf, 0);
    NSArray<NSString *> *result = [self.detector detectAndDecode:image];
    if (result.count > 0 && self.delegate) {
        dispatch_async(self.workQueue, ^{
            [self.delegate qrcodeScannerView:self didScanner:result];
        });
    }
}

#pragma mark - public method
- (void)startScanner {
    dispatch_async(self.workQueue, ^{
        if (!self.session.isRunning) {
            [self.session startRunning];
        }
    });
}

- (void)stopScanner {
    dispatch_async(self.workQueue, ^{
        if (self.session.isRunning) {
            [self.session stopRunning];
        }
    });
}
@end

