# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

target 'MyMapProject' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for MyMapProject
pod 'GoogleMaps'
pod 'RealmSwift'
pod 'SwipeCellKit'
pod 'ChameleonFramework/Swift', :git => 'https://github.com/wowansm/Chameleon.git', :branch => 'swift5'
pod 'Purchases'

pod 'Firebase/Crashlytics'
pod 'Firebase/Analytics'
pod 'FirebaseUI/Auth'
pod 'GoogleSignIn'
pod 'Google-Mobile-Ads-SDK'

pod 'Firebase/Firestore'
pod 'Firebase/Storage'

pod 'Google-Maps-iOS-Utils'

post_install do |pi|
    pi.pods_project.targets.each do |t|
      t.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
end
end
