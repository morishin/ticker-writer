require 'clockwork'
require './task.rb'

module Clockwork
  every(1.minutes, 'Task') { Task.run }
end
