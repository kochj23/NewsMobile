#!/usr/bin/env ruby
# Add NewsMobile Widget extension target to Xcode project
# Created by Jordan Koch

require 'xcodeproj'

project_path = '/Volumes/Data/xcode/NewsMobile/NewsMobile.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Adding NewsMobile Widget extension target..."

# Check if widget target already exists
existing_target = project.targets.find { |t| t.name == 'NewsMobileWidget' }
if existing_target
  puts "Widget target already exists, removing and recreating..."
  existing_target.remove_from_project
end

# Create widget extension target
widget_target = project.new_target(:app_extension, 'NewsMobileWidget', :ios, '17.0')

# Set up build settings for widget
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.jordankoch.newsmobile.widget'
  config.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['INFOPLIST_FILE'] = 'NewsMobileWidget/Info.plist'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = 'QRRCB8HB3W'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
  config.build_settings['SKIP_INSTALL'] = 'YES'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'

  if config.name == 'Debug'
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
    config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
  else
    config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
    config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
  end
end

# Create widget group
widget_group = project.main_group.new_group('NewsMobileWidget', 'NewsMobileWidget')

# Add Swift file to widget target
swift_file_ref = widget_group.new_file('NewsMobileWidget/NewsMobileWidget.swift')
widget_target.source_build_phase.add_file_reference(swift_file_ref)

# Add Info.plist reference
widget_group.new_file('NewsMobileWidget/Info.plist')

# Add Assets.xcassets to widget target
assets_ref = widget_group.new_file('NewsMobileWidget/Assets.xcassets')
widget_target.resources_build_phase.add_file_reference(assets_ref)

# Add WidgetKit framework
widgetkit_ref = project.frameworks_group.new_file('System/Library/Frameworks/WidgetKit.framework', :sdk_root)
widget_target.frameworks_build_phase.add_file_reference(widgetkit_ref)

# Find main app target and embed widget
main_target = project.targets.find { |t| t.name == 'NewsMobile' }
if main_target
  embed_phase = main_target.build_phases.find { |p| p.class == Xcodeproj::Project::Object::PBXCopyFilesBuildPhase && p.name == 'Embed App Extensions' }

  unless embed_phase
    embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
    embed_phase.name = 'Embed App Extensions'
    embed_phase.dst_subfolder_spec = '13'
    embed_phase.dst_path = ''
    main_target.build_phases << embed_phase
  end

  widget_product = widget_target.product_reference
  build_file = embed_phase.add_file_reference(widget_product)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

  main_target.add_dependency(widget_target)
  puts "Widget embedded in main app target"
end

project.save
puts "NewsMobile Widget extension target added successfully!"
