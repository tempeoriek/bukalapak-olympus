require 'jwt'
require 'dotenv'

# Load environment variables.
Dotenv.load

# Copy the environment variables and place it in your `.env`:
# https://gitlab.cloud.bukalapak.io/infra/gitops/minerva/-/blob/master/services/aleppo/config/preproduction/configmap-api#L27-28
rsa_private = OpenSSL::PKey::RSA.new(ENV['RSA_PRIVATE_KEY'])
rsa_public = OpenSSL::PKey::RSA.new(ENV['RSA_PUBLIC_KEY'])

exp = Time.now.to_i + 7 * 24 * 3600 # Expire after 7 days

# For the full payload, refer to this protobuf schema:
# https://gitlab.cloud.bukalapak.io/bukalapak/micro-standard/-/blob/master/proto/grpc/accounts/accounts.proto
payload = {
  exp: exp,
  resource_owner_id: 1,
  resource_owner: {
    agent: false
  }
}

token = JWT.encode payload, rsa_private, 'RS256'
puts JWT.decode token, rsa_public, true, {algorithm: 'RS256'}

request = "curl -H 'Authorization: Token #{token}' localhost:8086/pdam/transaction-configs"
File.write('./tmp/access_token.txt', request)
puts token
