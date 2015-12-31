Pod::Spec.new do |s|
  s.name         = "HCYoutubeParser"
  s.version      = "0.0.5"
  s.license      = 'Public Domain'

  s.ios.deployment_target = '7.0'
  s.tvos.deployment_target = '9.0'

  s.author       = "hellozimi"
  s.summary      = "Retrieves the iOS compatible video URL from YouTube."
  s.description  = "HCYoutubeParser is a class which lets you get the iOS compatible video url from YouTube so you don't need to use a UIWebView or open the YouTube Application."
  s.homepage     = "https://github.com/hellozimi/HCYoutubeParser"

  s.source       = { :git => "https://github.com/hellozimi/HCYoutubeParser.git", :tag => "0.0.5" }

  s.source_files = 'YoutubeParser/Classes'
  s.public_header_files = 'YoutubeParser/Classes/*.h'

  s.requires_arc = true
end
