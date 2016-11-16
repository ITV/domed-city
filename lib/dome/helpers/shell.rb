module Dome
  module Shell
    def execute_command(command, failure_message)
      puts "About to execute command: #{command.colorize(:yellow)}"
      result = system command
      puts failure_message unless result
      result
    end
  end
end
