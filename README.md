# Filter plugin for transforming syslog messages to hanarp message format for [Fluentd](http://fluentd.org)

## Requirements

| fluent-plugin-record-modifier  | fluentd | ruby |
|--------------------------------|---------|------|
| >= 1.0.0 | >= v0.14.0 | >= 2.1 |
|  < 1.0.0 | >= v0.12.0 | >= 1.9 |

## Configuration

    <filter **>
        @type hanarp_message
        ucsHostNameKey SyslogSource
    </filter>

Will transform UCS syslog messages to hanarp messages to send to Service Bus Queue. It will look in the record hash for "SyslogSource" key to get hostname.
Message format:

    {
        "timestamp": <timestamp>,
        "event": "<event>",
        "data": {
            "machineId": "Cisco_UCS:<coloRegion>:<serviceProfileName>",
            "hostname": "<hostname>",
            "chassis": "<chassisSlot>",
            "blade": "<bladeSlot>",
            "serviceProfile": "<serviceProfileName>",
            "stage": "<stage>",
            "message": "<syslogMessage>"
        }
    }

Plugin currently only expects syslog messages with either [FSM:BEGIN] or [FSM:END] tags and Power-on, Soft shutdown, Hard shutdown, or Power-cycle in the message. Please use the grep plugin to filter those messages out.

## Trademarks 

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow Microsoft's Trademark & Brand Guidelines. Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.
