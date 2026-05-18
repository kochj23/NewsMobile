#!/usr/bin/env ruby
# Fix bundle identifiers for NewsMobile
# Created by Jordan Koch

require 'xcodeproj'

project_path = '/Volumes/Data/xcode/NewsMobile/NewsMobile.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Fixing bundle identifiers..."

# Get main app bundle ID
main_target = project.targets.find { |t| t.name == 'NewsMobile' }
main_bundle_id = nil
if main_target
  main_target.build_configurations.each do |config|
    if config.name == 'Debug'
      main_bundle_id = config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
      puts "Main app bundle ID: #{main_bundle_id}"
      break
    end
  end
end

# Fix widget bundle ID
widget_target = project.targets.find { |t| t.name == 'NewsMobileWidget' }
if widget_target && main_bundle_id
  widget_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{main_bundle_id}.widget"
  end
  puts "Widget bundle ID set to: #{main_bundle_id}.widget"
end

project.save
puts "Bundle identifiers fixed!"
