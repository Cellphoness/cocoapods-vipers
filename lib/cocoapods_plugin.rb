require 'cocoapods-vipers/vipers-sync'
require 'cocoapods'

module CocoapodsVipers

  Pod::HooksManager.register('cocoapods-vipers', :pre_install) do |_context, _|
    paths = []
    puts 'vipers hook pre_install'
    dependencies = _context.podfile.dependencies
      dependencies.each do |d|
        # puts d
        ins_vars = d.instance_variables.map{|v|v.to_s[1..-1]}
        methods = d.methods.map &:to_s
        attribute = ins_vars & methods #attribute
        # puts attribute
        if d.name.match(/^Hycan/) && d.external_source
          # puts d.external_source[:path]
          paths.push({ 'spec_path' => d.external_source[:path], 'spec_name' => d.name })
        end
      end
      CocoapodsVipers::Vipers.new.sync(paths)
  end

  Pod::HooksManager.register('cocoapods-vipers', :post_install) do |context|
    # CocoapodsVipers::Vipers.new.sync()
    puts 'vipers hook post_install'
  end

  Pod::HooksManager.register('cocoapods-vipers', :post_update) do |context|
    puts 'vipers hook post_update'
    # CocoapodsVipers::Vipers.new.sync()
  end
  
end