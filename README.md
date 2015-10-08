# Fluent::Plugin::Pcapng

fluent-plugin-pcapng is an input plug-in for Fluentd.
It runs tshark with specified configuration and extract given packet fields.

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-pcapng'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-pcapng

## Usage

Add the following lines into your fluentd config.

simple case:

```
<source>
  type pcapng

  interface eth0
  fields frame.time,eth.dst,eth.src,eth.type
</source>
```

advanced case:

```
<source>
  type pcapng

  tag mypcap
  interface eth0
  fields frame.time,frame.time_epoch,ip.src,ip.dst,ip.proto
  types time,double,string,string,long
  convertdot __
```

## Configuration

|name|type|required?|default|description|
|:---|:---|:--------|:------|:----------|
| interface | string | required | "eth0" | interface to capture |
| fields | array | required | none | list of field to extract (-e on tshark) |
| types | array | optional | "string" for all | list of type for each field ("long", "double", "string", "time") |
| convertdot | string | optional | none | convert "." in field name (for outputing int DB who doesn't accept "dot" in schema) |

