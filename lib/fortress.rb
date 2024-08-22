# frozen_string_literal: true

require_relative 'fortress/version'
require_relative 'crypto'
require 'uri'
require 'net/http'
require 'json'
require 'base64'
require 'pg'

# Fortress is a Ruby client for the Fortress API.
#
# It provides methods to manage tenants and databases in the Fortress platform.
#
# @example
#   fortress = Fortress.new('org_id', 'api_key')
#
module Fortress
  class Error < StandardError; end

  # Define the Tenant struct here
  Tenant = Struct.new(:name, :alias, :database_id, :date_created) do
    def to_json(*_args)
      { id:, alias: self.alias }.to_json
    end
  end

  # Define the Database struct here
  Database = Struct.new(:id, :alias, :bytes_size, :average_read_iops, :average_write_iops, :date_created) do
    def to_json(*_args)
      { id:, alias: self.alias }.to_json
    end
  end

  # Client provides methods to interact with the Fortress API.
  # It requires an organization ID and an API key to authenticate requests.
  class Fortress
    BASE_URL = 'https://api.fortress.build'
    attr_reader :org_id, :api_key

    # Create a new Fortress client.
    # @param org_id [String] The organization ID.
    # @param api_key [String] The API key.
    # @return [Fortress] The Fortress client.
    def initialize(org_id, api_key)
      @org_id = org_id
      @api_key = api_key
    end

    # Connect to a tenant.
    # @param id [String] The tenant ID.
    # @return [PG::Connection] The connection to the tenant database.
    def connect_tenant(id)
      connection_details = get_connection_uri(id, 'tenant')
      PG::Connection.new(dbname: connection_details.database, user: connection_details.username,
                         password: connection_details.password, host: connection_details.url, port: connection_details.port)
    end

    # Create a tenant in a database.
    # @param id [String] The tenant ID.
    # @param tenant_alias [String] The tenant alias.
    # @param database_id [String] The database ID. (optional)
    # @return [void]
    def create_tenant(id, tenant_alias, database_id = nil)
      endpoint = "#{BASE_URL}/v1/organization/#{@org_id}/tenant/#{id}"
      body = { alias: tenant_alias }
      body[:databaseId] = database_id if database_id
      _ = make_request(:post, endpoint, body)
    end

    # List all tenants in the organization.
    # @return [Array<Tenant>] The list of tenants.
    def list_tenants
      endpoint = "#{BASE_URL}/v1/organization/#{@org_id}/tenants"
      response = make_request(:get, endpoint)
      tenants = response['tenants']
      tenants.map do |tenant|
        Tenant.new(tenant['name'], tenant['alias'], tenant['databaseId'], tenant['dateCreated'])
      end
    end

    # Delete a tenant.
    # @param id [String] The tenant ID.
    # @return [void]
    def delete_tenant(id)
      endpoint = "#{BASE_URL}/v1/organization/#{@org_id}/tenant/#{id}"
      _ = make_request(:delete, endpoint)
    end

    def connect_database(id)
      connection_details = get_connection_uri(id, 'database')
      PG::Connection.new(dbname: connection_details.database, user: connection_details.username,
                         password: connection_details.password, host: connection_details.url, port: connection_details.port)
    end

    # Create a database.
    # @param database_alias [String] The database alias.
    # @return [String] The database ID.
    def create_database(database_alias)
      endpoint = "#{BASE_URL}/v1/organization/#{@org_id}/database"
      response = make_request(:post, endpoint, { alias: database_alias })
      response['id']
    end

    # List all databases in the organization.
    # @return [Array<Database>] The list of databases.
    def list_databases
      endpoint = "#{BASE_URL}/v1/organization/#{@org_id}/databases"
      response = make_request(:get, endpoint)
      databases = response['databases']
      databases.map do |database|
        Database.new(database['id'], database['alias'], database['bytesSize'],
                     database['averageReadIOPS'], database['averageWriteIOPS'], database['dateCreated'])
      end
    end

    # Delete a database.
    # @param id [String] The database ID.
    def delete_database(id)
      endpoint = "#{BASE_URL}/v1/organization/#{@org_id}/database/#{id}"
      _ = make_request(:delete, endpoint)
    end

    private

    ConnectionDetails = Struct.new(:database_id, :url, :port, :username, :password, :database) do
      def to_json(*_args)
        { database_id:, url:, port:, username:, password:, database: }.to_json
      end
    end

    def get_connection_uri(id, type)
      endpoint = "#{BASE_URL}/v1/organization/#{@org_id}/#{type}/#{id}/uri"

      response = make_request(:get, endpoint)
      connection_details_encrypted = response['connectionDetails']
      connection_details_decrypted = Crypto.decrypt(@api_key, connection_details_encrypted)
      connection_details = JSON.parse(connection_details_decrypted)
      ConnectionDetails.new(connection_details['databaseId'].to_i, connection_details['url'],
                            connection_details['port'].to_i, connection_details['username'], connection_details['password'], connection_details['database'])
    end

    def make_request(method, url, body = nil)
      uri = URI.parse(url)

      request = Net::HTTP.const_get(method.capitalize).new(uri)
      request['Content-Type'] = 'application/json'
      request['Api-Key'] = @api_key
      http = Net::HTTP.new(uri.host, uri.port)

      # TODO: Enable SSL
      http.use_ssl = true

      request.body = body.to_json if body

      parse_response(http.request(request))
    end

    def parse_response(response)
      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)
      else
        raise Error, "Request failed with response code #{response.code}: #{response.message}"
      end
    end
  end
end
