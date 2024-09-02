require_relative 'lib/fortress'

# Create a client
client = Fortress::Fortress.new('orgId', 'apiKey')

# Create a database
id = client.create_database('Client 1')

# Create a tenant in that database
client.create_tenant('client1', 'dedicate', 'aws', 'Client 1', id)

# List all tenants
client.list_tenants.each do |tenant|
  print "Tenant: #{tenant.name} (#{tenant.alias})\n"
end

# Connect to the tenant
conn = client.connect_tenant('client1')
conn.exec('CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(50))')
conn.exec("INSERT INTO users (name) VALUES ('Alice')")
conn.exec("INSERT INTO users (name) VALUES ('Bob')")
conn.exec("INSERT INTO users (name) VALUES ('Charlie')")
conn.exec('SELECT * FROM users') do |result|
  result.each do |row|
    print "User: #{row['name']}\n"
  end
end
