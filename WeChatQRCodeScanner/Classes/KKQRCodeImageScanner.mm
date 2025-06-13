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
            auto pt1 = cv::Point((int)points[i].at<float>(0, 0), (int)points[i].at<float>(0, 1));
            auto pt2 = cv::Point((int)points[i].at<float>(1, 0), (int)points[i].at<float>(1, 1));
            auto pt3 = cv::Point((int)points[i].at<float>(2, 0), (int)points[i].at<float>(2, 1));
            auto pt4 = cv::Point((int)points[i].at<float>(3, 0), (int)points[i].at<float>(3, 1));

            //            std::cerr << pt1.x << " " << pt1.y << std::endl;
            //            std::cerr << pt2.x << " " << pt2.y << std::endl;
            //            std::cerr << pt3.x << " " << pt3.y << std::endl;
            //            std::cerr << pt4.x << " " << pt4.y << std::endl;

            auto minX = std::min({pt1.x, pt2.x, pt3.x, pt4.x});
            auto maxX = std::max({pt1.x, pt2.x, pt3.x, pt4.x});
            auto minY = std::min({pt1.y, pt2.y, pt3.y, pt4.y});
            auto maxY = std::max({pt1.y, pt2.y, pt3.y, pt4.y});

            CGRect rectOfImage = CGRectMake(pt1.x, pt1.y, maxX - minX, maxY - minY);

            KKQRCodeScannerResult *r = [[KKQRCodeScannerResult alloc] initWithContent:content rectOfImage:rectOfImage rectOfView:CGRectZero];
            [results addObject:r];
        }
    }

    return [results copy];
}
@end
