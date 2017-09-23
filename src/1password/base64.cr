module OnePassword::Base64

  def self.base64_to_base64url(input : String)
    input.gsub(/\+/, '-').gsub(/\//, '_').gsub(/=+$/, "")
  end

  def self.base64url_to_bytes(input : String)
    input = base64_to_base64url(input)

    OnePassword::Codec::Bytes.from_bits(OnePassword::Codec::Base64Url.to_bits(input))
  end
end
