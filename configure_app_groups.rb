#!/usr/bin/env ruby
# Configure App Groups and entitlements for NewsMobile
# Created by Jordan Koch

require 'xcodeproj'

project_path = '/Volumes/Data/xcode/NewsMobile/NewsMobile.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Configuring App Groups for NewsMobile..."

# Configure widget target entitlements
widget_target = project.targets.find { |t| t.name == 'NewsMobileWidget' }
if widget_target
  widget_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'NewsMobileWidget/NewsMobileWidget.entitlements'
  end
  puts "Widget entitlements configured"
end

# Add WidgetDataManager.swift to the project
main_target = project.targets.find { |t| t.name == 'NewsMobile' }
services_group = nil
project.main_group.recursive_children.each do |child|
  if child.is_a?(Xcodeproj::Project::Object::PBXGroup) && child.name == 'Services'
    services_group = child
    break
  end
end

if services_group && main_target
  existing = services_group.files.find { |f| f.path&.include?('WidgetDataManager.swift') }
  unless existing
    file_ref = services_group.new_file('WidgetDataManager.swift')
    main_target.source_build_phase.add_file_reference(file_ref)
    puts "WidgetDataManager.swift added to project"
  end
end

# Add widget entitlements file reference
widget_group = project.main_group.children.find { |c| c.name == 'NewsMobileWidget' }
if widget_group
  existing = widget_group.files.find { |f| f.path&.include?('entitlements') }
  unless existing
    widget_group.new_file('NewsMobileWidget/NewsMobileWidget.entitlements')
    puts "Widget entitlements file added to project"
  end
end

project.save
puts "App Groups configuration completed for NewsMobile!"
