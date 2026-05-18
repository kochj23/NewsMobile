#!/usr/bin/env ruby
# Fix widget file paths in NewsMobile project
# Created by Jordan Koch

require 'xcodeproj'

project_path = '/Volumes/Data/xcode/NewsMobile/NewsMobile.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Fixing widget file paths..."

widget_target = project.targets.find { |t| t.name == 'NewsMobileWidget' }

if widget_target
  widget_target.source_build_phase.files.each { |f| f.remove_from_project }
  widget_target.resources_build_phase.files.each { |f| f.remove_from_project }
  puts "Cleared existing widget build phases"
end

widget_group = project.main_group.children.find { |c| c.name == 'NewsMobileWidget' }
widget_group.remove_from_project if widget_group

widget_group = project.main_group.new_group('NewsMobileWidget', 'NewsMobileWidget')

swift_ref = widget_group.new_file('NewsMobileWidget.swift')
info_ref = widget_group.new_file('Info.plist')
entitlements_ref = widget_group.new_file('NewsMobileWidget.entitlements')
assets_ref = widget_group.new_file('Assets.xcassets')

if widget_target
  widget_target.source_build_phase.add_file_reference(swift_ref)
  widget_target.resources_build_phase.add_file_reference(assets_ref)
  puts "Added files to widget target build phases"
end

project.save
puts "Widget file paths fixed successfully!"
