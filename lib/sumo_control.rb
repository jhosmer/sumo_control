require 'rubygems'
require 'json'
require 'logger'

require 'sumo_control/source_definition'
require 'sumo_control/error'
require 'sumo_control/client'
require 'sumo_control/filters'
require 'sumo_control/source_file'

class SumoControl
  def initialize(user, password, logger = Logger.new('/dev/null'))
    @client = Client.new(user, password, logger)
    @logger = logger
  end

  def register(collector_id, source_json_path)
    yield (source_definition = SourceDefinition.new)

    updated_source_definition = register_source(collector_id, source_definition)
    store_source(updated_source_definition, source_json_path)

    updated_source_definition
  rescue SumoControl::Error => error
    logger.fatal(error)
  end

private

  attr_reader :client, :logger

  def register_source(collector_id, source_definition)
    client.create_source(collector_id, source_definition)
  rescue SumoControl::Error => error
    raise unless error.duplicate?

    source_definition.identify_as(remote_source_definition(collector_id, source_definition))
    client.update_source(collector_id, source_definition)
  end

  def remote_source_definition(collector_id, source_definition)
    client.source(collector_id, lookup_source_id(collector_id, source_definition))
  end

  def lookup_source_id(collector_id, source_definition)
    client.sources(collector_id).detect{|remote_source| remote_source == source_definition}.id
  end

  def store_source(source_definition, file_path)
    SourceFile.new(file_path).write(source_definition)
  end
end
