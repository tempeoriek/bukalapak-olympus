class JsonWebToken
  def self.decode(token)
    rsa_public = OpenSSL::PKey::RSA.new(ENV['RSA_PUBLIC_KEY'])
    return HashWithIndifferentAccess.new(JWT.decode(token, rsa_public, true, { algorithm: 'RS256' })[0])
  rescue
    nil
  end
end
