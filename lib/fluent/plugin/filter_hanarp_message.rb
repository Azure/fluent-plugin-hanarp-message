require 'fluent/plugin/filter'
require 'json'
require 'net/http'
require 'openssl'

module Fluent::Plugin
  class HanarpMessage < Filter
    Fluent::Plugin.register_filter("hanarp_message", self)

    config_param :ucsHostNameKey, :string

    def filter(tag, time, record)

      split = record["message"].split(": ")

      message = split[4]

      event = record["event"]
      stage = record["stage"]
      host = record[ucsHostNameKey]
      chassis = message[/chassis-(\d)/,1]
      blade = message[/blade-(\d)/,1]
      executedBy = record["executedBy"]

      if record.key?("machineId")
        machineId = record["machineId"]
        serviceProfile = machineId.split(":")[2]
      end

      d = Data.new(machineId, host, chassis, blade, serviceProfile, event, stage, message, executedBy)
      m = Message.new(time, event, d)
      record["message"] = m.to_json
      record
    end
  end

  class Message
    def initialize(timestamp, event, data)
      @timestamp = timestamp
      @event = event
      @data = data
    end

    def to_json(*a)
      {
        timestamp: @timestamp,
        event: @event,
        data: @data
      }.to_json(*a)
    end
  end

  class Data

    # Events
    SOFT_SHUTDOWN = "soft shutdown"
    HARD_SHUTDOWN = "hard shutdown"
    BOOT          = "boot"
    RESTART       = "restart"
    # Stages
    STAGE_BEGIN = "begin"
    STAGE_END   = "end"
    # Machine States
    STARTING   = "starting"
    STARTED    = "started"
    STOPPING   = "stopping"
    STOPPED    = "stopped"
    RESTARTING = "restarting"
    UNKNOWN    = "unknown"

    MACHINE_STATES = {
      SOFT_SHUTDOWN+STAGE_BEGIN => STOPPING,
      SOFT_SHUTDOWN+STAGE_END   => STOPPED,
      HARD_SHUTDOWN+STAGE_BEGIN => STOPPING,
      HARD_SHUTDOWN+STAGE_END   => STOPPED,
      BOOT+STAGE_BEGIN          => STARTING,
      BOOT+STAGE_END            => STARTED,
      RESTART+STAGE_BEGIN       => RESTARTING,
      RESTART+STAGE_END         => STARTED
    }

    def initialize(machineId, hostname, chassis, blade, serviceProfile, event, stage, message, executedBy)
      @machineId = machineId
      @hostname = hostname
      @chassis = chassis
      @blade = blade
      @serviceProfile = serviceProfile
      @stage = stage
      @message = message
      @executedBy = executedBy

      eventLower = event.downcase
      stageLower = stage.downcase
      if MACHINE_STATES.key?(eventLower+stageLower) then
        @state = MACHINE_STATES[eventLower+stageLower]
      else
        @state = UNKNOWN
      end
    end

    def to_json(*a)
      {
        machineId: @machineId,
        hostname: @hostname,
        chassis: @chassis,
        blade: @blade,
        serviceProfile: @serviceProfile,
        stage: @stage,
        state: @state,
        message: @message,
        executedBy: @executedBy
      }.to_json(*a)
    end
  end
end
