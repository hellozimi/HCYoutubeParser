Pod::Spec.new do |s|

  s.name         = "HCYoutubeParser"
  s.version      = "0.0.6"
  s.summary      = "Fetches YouTube mp4 URLS for iOS and tvOS."
  s.description  = "HCYoutubeParser is a class which lets you get the iOS compatible video url from YouTube so you don't need to use a UIWebView or open the YouTube Application."
  s.homepage     = "https://github.com/openwt/HCYoutubeParser"
  s.license      = "MIT"
  s.author       = "openwt"
  s.platform     = :ios
  s.source       = { :git => "https://github.com/openwt/HCYoutubeParser.git", :tag => "#{s.version}" }
  s.source_files = 'YoutubeParser/Classes'
  s.public_header_files = 'YoutubeParser/Classes/*.h'
  s.requires_arc = true
end
