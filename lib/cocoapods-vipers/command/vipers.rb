require 'cocoapods-vipers/vipers-sync'
require 'cocoapods'
include CocoapodsVipers

module Pod
  class Command
    # This is an example of a cocoapods plugin adding a top-level subcommand
    # to the 'pod' command.
    #
    # You can also create subcommands of existing or new commands. Say you
    # wanted to add a subcommand to `list` to show newly deprecated pods,
    # (e.g. `pod list deprecated`), there are a few things that would need
    # to change.
    #
    # - move this file to `lib/pod/command/list/deprecated.rb` and update
    #   the class to exist in the the Pod::Command::List namespace
    # - change this class to extend from `List` instead of `Command`. This
    #   tells the plugin system that it is a subcommand of `list`.
    # - edit `lib/cocoapods_plugins.rb` to require this file
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
    class Vipers < Command
      self.summary = 'Short description of cocoapods-vipers.'

      self.description = <<-DESC
        Longer description of cocoapods-vipers.
      DESC

      def initialize(argv)
        super
      end

      def validate!
        super
      end

      def run
        Pod::UI.puts "Use 'pod install' or 'pod update' to do vipers generate"
        # CocoapodsVipers::Vipers.new.sync()
      end
    end
  end
end
