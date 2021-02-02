#
# Be sure to run `pod lib lint WeChatQRCodeScanner.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WeChatQRCodeScanner'
  s.version          = '1.0.0'
  s.summary          = 'WeChatQRCodeScanner.'
  s.description      = <<-DESC
  微信开源二维码识别引擎
                       DESC

  s.homepage         = 'https://github.com/0x1306a94/WeChatQRCodeScanner'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '0x1306a94' => '0x1306a94@gmail.com' }
  s.source           = { :git => 'https://github.com/0x1306a94/WeChatQRCodeScanner.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform = :ios, '11.0'

  s.source_files = 'WeChatQRCodeScanner/Classes/**/*.{h,m,mm}'
  
  s.preserve_paths = [
    'WeChatQRCodeScanner/Frameworks',
#     'WeChatQRCodeScanner/Models',
    'script/build.sh'
  ]
  
  s.vendored_frameworks = [
    'WeChatQRCodeScanner/Frameworks/*.framework'
  ]

  openv_version = "4.5.1"
  s.prepare_command = "script/build.sh #{openv_version}"

  # s.resource_bundles = {
  #   'WeChatQRCodeScanner' => ['WeChatQRCodeScanner/Models/*']
  # }
  
  # s.prefix_header_file = false
  # s.pod_target_xcconfig = {
  #   'OTHER_CPLUSPLUSFLAGS' => '-fmodules -fcxx-modules'
  # }

  # s.user_target_xcconfig = {
  #   'OTHER_CPLUSPLUSFLAGS' => '-fmodules -fcxx-modules'
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = [
    'AVFoundation', 
    'CoreImage', 
    'CoreGraphics', 
    'QuartzCore', 
    'Accelerate',
    'CoreVideo',
    'CoreMedia'
  ]

  s.libraries = [
    'c++'
  ]
  # s.dependency 'AFNetworking', '~> 2.3'
end
