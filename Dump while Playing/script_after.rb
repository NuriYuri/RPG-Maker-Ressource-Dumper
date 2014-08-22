#===
#¤Script Injecté après chargement du RGSS
#---
#©21/08/2014 - Nuri Yuri (塗 ゆり) - Création du script
#===
#===
#>Petit trick sympatique pour extraire le data au fur et à mesure
#===
class Object
  def load_data(filename)
    data=super(filename)
    $Yuri_is_an_anonymous_module.extract_data(filename,data)
    return data
  end
end
#===
#>Modification du comportement de la classe Bitmap
#===
# Bitmap export v 3.0 by Zeus81
class Bitmap
  alias initialize_sdkjkgjsdlncvkjshdfv initialize
  def initialize(*args)
    initialize_sdkjkgjsdlncvkjshdfv(*args)
    $Yuri_is_an_anonymous_module.extract_bitmap(args[0],self) if(args.size==1 and args[0].class==String)
  rescue Errno::ENOENT
    nil
  rescue Exception
    p $!,$!.message,$!.backtrace
  end
  #>Partie du script de Zeus81
  RtlMoveMemory_pi = Win32API.new('kernel32', 'RtlMoveMemory', 'pii', 'i')
  RtlMoveMemory_ip = Win32API.new('kernel32', 'RtlMoveMemory', 'ipi', 'i')
  def address
    RtlMoveMemory_pi.call(a="\0"*4, __id__*2+16, 4)
    RtlMoveMemory_pi.call(a, a.unpack('L')[0]+8, 4)
    RtlMoveMemory_pi.call(a, a.unpack('L')[0]+16, 4)
    a.unpack('L')[0]
  end
  def export(filename)
    format=File.extname(filename)
    if(self.height>10_000 or self.width>10_000)
      filename<<".bmp" if(format.to_s.size==0)
      format='.bmp'
    end
    filename<<'.png' if(format.to_s.size==0)
    file = File.open(filename, 'wb')
    case format
    when '.bmp'
      data, size = String.new, width*height*4
      RtlMoveMemory_ip.call(data.__id__*2+8, [size,address].pack('L2'), 8)
      file.write(['BM',size+54,0,54,40,width,height,1,32,0,size,0,0,0,0].pack('a2L6S2L6'))
      file.write(data)
      RtlMoveMemory_ip.call(data.__id__*2+8, "\0"*8, 8)
    else
      def file.write_chunk(chunk)
        write([chunk.size-4].pack('N'))
        write(chunk)
        write([Zlib.crc32(chunk)].pack('N'))
      end
      file.write("\211PNG\r\n\32\n")
      file.write_chunk("IHDR#{[width,height,8,6,0,0,0].pack('N2C5')}")
      RtlMoveMemory_pi.call(data="\0"*(width*height*4), address, data.size)
      (width*height).times {|i| data[i<<=2,3] = data[i,3].reverse!}
      deflate, null_char, w4 = Zlib::Deflate.new(9), "\0", width*4
      (height-1).downto(0) {|i| deflate << null_char << data[i*w4,w4]}
      file.write_chunk("IDAT#{deflate.finish}")
      deflate.close
      file.write_chunk('IEND')
    end
    file.close
  end
end