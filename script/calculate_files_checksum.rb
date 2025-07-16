# Used to determine versioning for Docker base images
require 'digest'

sha_all = ''
for arg in ARGV
  sha_all << Digest::SHA256.file(arg).hexdigest
end

puts(Digest::SHA256.hexdigest(sha_all))
