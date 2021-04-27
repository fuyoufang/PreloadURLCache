#
# Be sure to run `pod lib lint PreloadURLCache.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PreloadURLCache'
  s.version          = '0.1.0'
  s.summary          = 'A short description of PreloadURLCache.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/FuYouFang/PreloadURLCache.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'fuyoufang@163.com' => 'fuyoufang@163.com' }
  s.source           = { :git => 'https://github.com/FuYouFang/PreloadURLCache.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.source_files = 'PreloadURLCache/Classes/**/*'
    s.dependency 'Then'
  
  
  s.subspec 'JavascriptBridge' do |jsBridge|
          jsBridge.dependency 'WebViewJavascriptBridge'
      jsBridge.source_files = 'PreloadURLCache/JavascriptBridge/**/*'
  end
  
  s.subspec 'WKWebView' do |webView|
    webView.source_files = 'PreloadURLCache/WKWebView/**/*'
    webView.public_header_files = 'PreloadURLCache/WKWebView/**/*.h'
    webView.frameworks = 'UIKit', 'WebKit'
  end
  
end
