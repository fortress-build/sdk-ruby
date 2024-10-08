# Fortress Ruby SDK

Welcome to the Fortress Ruby SDK. This SDK provides a way for you to leverage the power of the Fortress platform in your Ruby applications.

## Installation

You can install the SDK using Gem. Simply run the following command:

```bash
gem install fortress-sdk-ruby
```

## Quick Start

Here is a quick example to get you started with the SDK:

```ruby
require 'fortress'

# Initialize the client
client = Fortress::Client.new(api_key, organization_id)

# Create a new tenant
client.create_tenant("tenant_name", "alias")

# Connect to the tenant
conn = client.connect_tenant("tenant_name")

conn.exec('CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(50))')
conn.exec("INSERT INTO users (name) VALUES ('Alice')")
conn.exec('SELECT * FROM users') do |result|
  result.each do |row|
    print "User: #{row['name']}\n"
  end
end

# Delete the tenant
client.delete_tenant("tenant_name")
```

## Documentation

Below is a list of the available functionality in the SDK. Using the SDK you can create a new tenants and point them to existing or new databases. You can also easily route data requests based on tenant names. For more detailed information, please refer to the [Fortress API documentation](https://docs.fortress.build).

Database Management:

- `create_database(platform: str, alias: str)`: Creates a new database.
- `delete_database(database_name: str)`: Deletes to a database.
- `list_databases()`: Lists all databases.

Tenant Management:

- `create_tenant(tenant_name: str, isolation_level: str, platform: str, alias: str, database_id: str = "")`: Creates a new tenant.
- `delete_tenant(tenant_name: str)`: Deletes a tenant.
- `list_tenants()`: Lists all tenants.
- `connect_tenant(tenant_name: str)`: Connects to a tenant and turns into SQL connection.

## Configuration

To use the SDK, generate an API key from the Fortress dashboard to initialize the client. Also, provide the organization ID, which is available under the API Keys page on the platform website.

## License

This SDK is licensed under the MIT License.

## Support

If you have any questions or need help, don't hesitate to get in touch with our support team at founders@fortress.build.
