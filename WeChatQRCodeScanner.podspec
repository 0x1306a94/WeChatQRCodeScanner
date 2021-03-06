Pod::Spec.new do |s|
  s.name             = 'WeChatQRCodeScanner'
  s.version          = '1.1.0'
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
    'WeChatQRCodeScanner/Models',
    # 'patch',
    # 'script/build.sh'
    'script/downloadlib.sh'
  ]
  
  s.vendored_frameworks = [
    'WeChatQRCodeScanner/Frameworks/*.framework'
  ]

  # s.prepare_command =<<-CMD
  #   script/build.sh "4.5.1"
  # CMD

  s.prepare_command =<<-CMD
    script/downloadlib.sh "lib-v1"
  CMD

  s.resource_bundles = {
    'WeChatQRCodeScanner' => ['WeChatQRCodeScanner/Models/*']
  }
  
  # s.prefix_header_file = false
   s.pod_target_xcconfig = {
#     'OTHER_CPLUSPLUSFLAGS' => '-fmodules -fcxx-modules'
    'CLANG_WARN_DOCUMENTATION_COMMENTS' => 'NO',
    'VALID_ARCHS' => 'arm64 x86_64',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64'
   }

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
