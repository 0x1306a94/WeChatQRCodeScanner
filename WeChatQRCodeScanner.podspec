Pod::Spec.new do |s|
  s.name             = 'WeChatQRCodeScanner'
  s.version          = '1.2.0'
  s.summary          = 'WeChatQRCodeScanner.'
  s.description      = <<-DESC
  微信开源二维码识别引擎, opencv 4.9.0
                       DESC

  s.homepage         = 'https://github.com/0x1306a94/WeChatQRCodeScanner'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '0x1306a94' => '0x1306a94@gmail.com' }
  s.source           = { :git => 'https://github.com/0x1306a94/WeChatQRCodeScanner.git', :tag => s.version.to_s }

  s.platform = :ios, '11.0'

  s.source_files = 'WeChatQRCodeScanner/Classes/**/*.{h,m,mm}'
  
  s.preserve_paths = [
    'WeChatQRCodeScanner/Frameworks',
    'WeChatQRCodeScanner/Models',
    'script/downloadlib.sh'
  ]
  
  s.vendored_frameworks = [
    'WeChatQRCodeScanner/Frameworks/*.xcframework'
  ]

  s.prepare_command =<<-CMD
    script/downloadlib.sh "lib-v4.9.0"
  CMD

  s.resource_bundles = {
    'WeChatQRCodeScanner' => ['WeChatQRCodeScanner/Models/*']
  }
  
   s.pod_target_xcconfig = {
#     'OTHER_CPLUSPLUSFLAGS' => '-fmodules -fcxx-modules'
    'CLANG_WARN_DOCUMENTATION_COMMENTS' => 'NO',
   }

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
end
