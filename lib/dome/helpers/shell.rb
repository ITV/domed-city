# frozen_string_literal: true
require 'open3'

module Dome
  module Shell
    def execute_command(command, failure_message)
      puts "[*] Running: #{command.colorize(:yellow)}"
      success = system command
      Kernel.abort(failure_message) unless success
    end

    def command_output(command, failure_message)
      puts "[*] Running: #{command.colorize(:yellow)}"
      stdout, stderr, status = Open3.capture3(command)
      Kernel.abort(failure_message) unless status == 0
      return stdout
    end
  end
end
