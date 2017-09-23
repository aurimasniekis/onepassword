module OnePassword::Codec

  module Bytes
    def self.from_bits(input)
      out = [] of UInt32
      bl = BitArray.bit_length(input)
      i = 0
      tmp = uninitialized Int32

      while (i < bl/8)
        if (i&3) == 0
          tmp = input[i/4]
        end

        out << (tmp.to_u >> 24)
        tmp <<= 8

        i += 1
      end

      out
    end
  end

  module BitArray
    def self.partial(length, x, end? : Bool)
      if length == 32
        return x
      end

      if end?
        a = (x|0)
      else
        a = (x << (32 - length))
      end

      return a + length * 0x10000000000
    end

    def self.get_partial(x)
      a = (x.to_f / 0x10000000000).round(0)

      if (a != 0)
        a.to_i
      else
        32
      end
    end

    def self.bit_length(a : Array)
      l = a.size
      if l == 0
        return 0
      end

      x = a[l - 1]
      return (l-1) * 32 + get_partial(x)
    end
  end

  module Base64
    CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

    def self.from_bits(input, no_equals? : Bool, url? : Bool)
      base64_chars = Base64::CHARS

      if url?
        base64_chars = base64_chars[0...62] + "-_"
      end

      out = ""
      bits = 0
      ta = 0
      bl = BitArray.bit_length(input)
      i = 0

      while (out.size * 6 < bl)
        a = input[i]?
        if a.nil?
          a = 0
        end
        out += base64_chars[((ta ^ a.to_u >> bits).to_u >> 26)]

        if bits < 6
          ta = a << (6 - bits)
          bits += 26
          i += 1
        else
          ta <<= 6
          bits -= 6
        end
      end

      while ((out.size&3) != 0 && false == no_equals?)
        out += '='
      end

      out
    end

    def self.to_bits(input : String, url? : Bool)
      input = input.gsub(/\s|=/, "")

      base64_chars = Base64::CHARS

      if url?
        base64_chars = base64_chars[0...62] + "-_"
      end

      out = [] of Int32
      bits = 0_u8
      ta = 0

      input.each_char_with_index do |input_char, index|
        x = base64_chars.index(input_char)

        if x.nil?
          raise "Invalid Base64 string given"
        end

        if bits > 26
          bits -= 26
          out << (ta ^ x >> bits)
          ta = (x << (32 - bits))
        else
          bits += 6
          ta ^= (x << (32 - bits))
        end
      end

      if bits&56 != 0
        out << BitArray.partial(bits&56, ta, true)
      end

      out
    end
  end

  module Base64Url
    def self.from_bits(input)
      Base64.from_bits(input, true, true)
    end

    def self.to_bits(input : String)
      Base64.to_bits(input, true)
    end
  end

end
