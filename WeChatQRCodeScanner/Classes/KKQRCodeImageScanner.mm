//
//  KKQRCodeImageScanner.m
//  Pods
//
//  Created by king on 2021/2/26.
//

#import "KKQRCodeImageScanner.h"

#import "KKQRCodeScannerResult.h"

#import <opencv2/Mat.h>
#import <opencv2/WeChatQRCode.h>
#import <opencv2/core/hal/interface.h>

@interface KKQRCodeImageScanner ()
@property (nonatomic, assign) cv::Ptr<cv::wechat_qrcode::WeChatQRCode> detector;
@end

@implementation KKQRCodeImageScanner
- (instancetype)init {
    if (self == [super init]) {
        [self commonInit];
    }
    return self;
}

#pragma mark - Initial Methods
- (void)commonInit {
    NSBundle *mainBundle = [NSBundle bundleForClass:self.class];
    NSBundle *bundle = [NSBundle bundleWithPath:[mainBundle pathForResource:@"WeChatQRCodeScanner" ofType:@"bundle"]];
    NSString *detector_prototxt_path = [bundle pathForResource:@"detect" ofType:@"prototxt" inDirectory:@"wechat_qrcode"];
    NSString *detector_caffe_model_path = [bundle pathForResource:@"detect" ofType:@"caffemodel" inDirectory:@"wechat_qrcode"];
    NSString *super_resolution_prototxt_path = [bundle pathForResource:@"sr" ofType:@"prototxt" inDirectory:@"wechat_qrcode"];
    NSString *super_resolution_caffe_model_path = [bundle pathForResource:@"sr" ofType:@"caffemodel" inDirectory:@"wechat_qrcode"];

    _detector = cv::makePtr<cv::wechat_qrcode::WeChatQRCode>(detector_prototxt_path.UTF8String,
                                                             detector_caffe_model_path.UTF8String,
                                                             super_resolution_prototxt_path.UTF8String,
                                                             super_resolution_caffe_model_path.UTF8String);
}

- (NSArray<KKQRCodeScannerResult *> *)scannerForImage:(UIImage *)image {
    if (!image) {
        return nil;
    }

    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;

    cv::Mat cvMat(rows, cols, CV_8UC4);  // 8 bits per component, 4 channels (color channels + alpha)

    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,     // Pointer to  data
                                                    cols,           // Width of bitmap
                                                    rows,           // Height of bitmap
                                                    8,              // Bits per component
                                                    cvMat.step[0],  // Bytes per row
                                                    colorSpace,     // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                        kCGBitmapByteOrderDefault);  // Bitmap info flags

    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);

    //    cv::Mat transMat;
    //    cv::transpose(cvMat, transMat);
    //
    //    cv::Mat flipMat;
    //    cv::flip(transMat, flipMat, 1);

    std::vector<cv::Mat> points;
    std::vector<std::string> res = self.detector->detectAndDecode(cvMat, points);

    NSMutableArray<KKQRCodeScannerResult *> *results = nil;
    if (res.size() > 0) {

        size_t size = res.size();

        results = [NSMutableArray<KKQRCodeScannerResult *> arrayWithCapacity:size];

        for (size_t i = 0; i < size; i++) {
            NSString *content = [NSString stringWithCString:res[i].c_str() encoding:NSUTF8StringEncoding];
            cv::Mat &m = points[i];

            CGPoint topLeft = CGPointMake(m.at<float>(0, 0), m.at<float>(0, 1));
            CGPoint topRight = CGPointMake(m.at<float>(1, 0), m.at<float>(1, 1));
            CGPoint bottomLeft = CGPointMake(m.at<float>(2, 0), m.at<float>(2, 1));
            CGRect rectOfImage = (CGRect){topLeft, CGSizeMake(topRight.x - topLeft.x, bottomLeft.y - topLeft.y)};

            KKQRCodeScannerResult *r = [[KKQRCodeScannerResult alloc] initWithContent:content rectOfImage:rectOfImage rectOfView:CGRectZero];
            [results addObject:r];
        }
    }

    return [results copy];
}
@end
