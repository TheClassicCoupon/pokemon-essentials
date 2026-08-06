require 'zlib'

class Numeric
  def to_digits(num = 3)
    str = to_s
    (num - str.size).times { str = str.prepend("0") }
    return str
  end
end

module Scripts
  def self.dump(path = "Scripts", rxdata = "Data/Scripts.rxdata")
    scripts = File.open(rxdata, 'rb') { |f| Marshal.load(f) }
    if scripts.length < 10
      p "Scripts look like they're already extracted. Not doing so again."
      return
    end
    create_directory(path)
    clear_directory(path)
    folder_id = [1, 1]   # Can only have two layers of folders
    file_id = 1
    level = 0   # 0=main path, 1=subfolder, 2=sub-subfolder
    folder_path = path
    folder_name = nil
    scripts.each_with_index do |e, i|
      _, title, script = e
      title = title_to_filename(title).strip
      script = Zlib::Inflate.inflate(script).delete("\r")
      next if title.empty? && script.empty?
      section_name = nil
      if title[/\[\[\s*(.+)\s*\]\]$/]   # Make a folder
        section_name = $~[1].strip
        section_name = "unnamed" if !section_name || section_name.empty?
        folder_num =  (i < scripts.length - 2) ? folder_id[level].to_digits(3) : "999"
        folder_name = folder_num + "_" + section_name
        create_directory(folder_path + "/" + folder_name)
        folder_id[level] += 1
        if level < folder_id.length-1
          level += 1   # Go one level deeper
          folder_id[level] = 1   # Reset numbering of subfolders
          folder_path += "/" + folder_name
          folder_name = nil
        end
        file_id = 1   # Reset numbering of script files
      elsif title.start_with?("=====")   # Return to top level directory
        level = 0
        folder_path = path
        folder_name = nil
      end
      # Create script file
      next if script.empty?
      this_folder = folder_path
      this_folder += "/" + folder_name if folder_name
      section_name ||= title.strip
      section_name = "unnamed" if !section_name || section_name.empty?
      file_num =  (i < scripts.length - 1) ? file_id.to_digits(3) : "999"
      file_name = file_num + "_" + section_name + ".rb"
      create_script(this_folder + "/" + file_name, script)
      file_id += 1   # Increment numbering of script files
    end
    # Backup Scripts.rxdata to ScriptsBackup.rxdata
    File.open("Data/ScriptsBackup.rxdata", "wb") do |f|
      Marshal.dump(scripts, f)
    end
    # Replace Scripts.rxdata with ScriptsLoader.rxdata
    createLoaderScripts(rxdata)
  end

  def self.createLoaderScripts(rxdata)
		txt = "x\x9C}SK\x8F\x9B0\x10\xBEG\xCA\x7F\x18\xD8H\x8062\x9Bc\x0Fi\x0F}\xA9\xA7V\x9B\xDC\x02E<\x86\xC4]b#\xDB4\xDD\x86\xFC\xF7\xB5!\xE0\xD0m{\x01\xE6\xF5\xCD\xCC7\x1Fw\xB0=P\t\x05G\t\x8C+8q\xF1\x04\xB4\x04u@\xD8\xA7G\x04\x1DD\x96\x8B\xE7Za\xE1\xCCg\xF3Y\x81:*\xD2\x1C\xB34\x7FJ\x04\xD6\\\xA8\xF9\f\xC0\x98\x9D\x1F\xD6\xB0p\xC8h\x92\xBC\xE2\f'\x19\x04\xD3\xFCp\x866S\xAD\xF1\xEB\x88\"\xB2\xC9\x1C?\x8C\xCE~T\xDC\a\xD1%\f\xE0\xEC\xEE\xEE\xCE\x8B\xD5%\xD6\xCF\xC7\xCF\x9BM\xB2y\xFF\xF8\xE5\xDBv\xB3[\xAC\x88\xE2\t\x8Dw\xAB\xF8\xE2^\fB\xF7\x10\xA8\x1A\xC1L\xEF#J\x99\xEE\x11\xEE\xC1\x8DX\xC4\\\xFDa{\xFF\xE0\x94\xF9\xDA\xEF\x06\xF3\x19\xB2bXI\xA4Tbb\x17C!\xB80\xB0\x9A\f\vI$\xFD\x8D\xF0v\ro\x1E\x1E\xFA\xD1?\xD1\n\t\xAF\x91\xF9\xDEXL*\xBE\xF7\x96\xE0\x9D<\xBD\x05\xB4e\v%9\t\xAA\xD0_8A?,\xF4\r\xC1\xDB\x0EE\x86i\xC59dtO\xE0k\xA3\xEAF\x01e0\x055\xA5XI\xBC\x81\xE8\\f\x8F\x9Be*\x9E\x16\x89\xCC\x05\xAD\x95LJ\xC1\x8FI\xC9\xAB\x02\x85_\xA7\xEA\x10\x98\x8AR\x8F-5\xC4\x1Avqgwq9\xDA\x1F\xA8 %\x17\xE6P}\x91\x96\x88\xD9\xA4o\xCC\xF0\x972\xC4\x94\xB0^\x83G<h\xDB\xE1\x9Bx}\x8A\x8Ev\xD4\x14T`\xAE\xB8x~\xD7\xE1\x98\x9B\x84\xE6 e\xD0\xE7\x8D\xADI\xDD\xC8\x83_\x06\xA6\xD2)w\xE1\xF7\x88\x84q\x9Fc7\xBE\x0E~\x9B\xABS#\"\xB2EH\x87l\xC3\xC3\xF8\xEA\xF3\xA5\x16\xA9cM\xB3\xD6d\xA1\x9C\x17F\xB7\xF6\x98\xD3Y\x97\xE0\n\xB7\xBF\xA5\xCEh;\x14\xA2\xC9)\x86cf\xB8\xA7l\x18\x11\x7F\xA6\x95o\x10\x97\xC0h\xB5\x1CW\x15(\xF3\x06a\xD3\xDD\xE5\xE3\xA0/\xAB\x85\x9B\x00ax\xF2\xAD\xEC&\x00C\xD1\xAD*\xCD\xCFc\xED\xE5\xAB\x1F4\x98t\xFA\x9B\xCC_\xF1v\xBD\x8Ae\xEE\xEA\xB0\xDCu\x8E+\x81\xFFU\x9C%\xB2\xF3\x05\x7FJ\xF6\x9F\xC5nO\x89t\x83\x17\b\x9Ad6"
    File.open(rxdata, "wb") do |f|
      Marshal.dump([[62054200, "Main", txt]], f)
    end
  end

  def self.from_folder(path = "Scripts", rxdata = "Data/Scripts.rxdata")
    scripts = File.open(rxdata, 'rb') { |f| Marshal.load(f) }
    if scripts.length > 10
      p "Scripts.rxdata already has a bunch of scripts in it. Won't consolidate script files."
      return
    end
    scripts = []
    aggregate_from_folder(path, scripts)
    # Save scripts to file
    File.open(rxdata, "wb") do |f|
      Marshal.dump(scripts, f)
    end
  end

  def self.aggregate_from_folder(path, scripts, level = 0)
    files = []
    folders = []
    Dir.foreach(path) do |f|
      next if f == '.' || f == '..'
      if File.directory?(path + "/" + f)
        folders.push(f) if !f[/^\./]
      else
        files.push(f) if f[/\.rb$/i]
      end
    end
    # Aggregate individual script files into Scripts.rxdata
    files.sort!
    files.each do |f|
      section_name = filename_to_title(f)
      content = File.open(path + "/" + f, "rb") { |f2| f2.read }#.gsub(/\n/, "\r\n")
      scripts << [rand(999_999), section_name, Zlib::Deflate.deflate(content)]
    end
    # Check each subfolder for scripts to aggregate
    folders.sort!
    folders.each do |f|
      section_name = filename_to_title(f)
      scripts << [rand(999_999), "==================", Zlib::Deflate.deflate("")] if level == 0
      scripts << [rand(999_999), "", Zlib::Deflate.deflate("")] if level == 1
      scripts << [rand(999_999), "[[ " + section_name + " ]]", Zlib::Deflate.deflate("")]
      aggregate_from_folder(path + "/" + f, scripts, level + 1)
    end
  end

  def self.filename_to_title(filename)
    filename = filename.bytes.pack('U*')
    title = ""
    if filename[/^[^_]*_(.+)$/]
      title = $~[1]
      title = title[0..-4] if title.end_with?(".rb")
      title = title.strip
    end
    title = "unnamed" if !title || title.empty?
    title.gsub!(/&bs;/, "\\")
    title.gsub!(/&fs;/, "/")
    title.gsub!(/&cn;/, ":")
    title.gsub!(/&as;/, "*")
    title.gsub!(/&qm;/, "?")
    title.gsub!(/&dq;/, "\"")
    title.gsub!(/&lt;/, "<")
    title.gsub!(/&gt;/, ">")
    title.gsub!(/&po;/, "|")
    return title
  end

  def self.title_to_filename(title)
    filename = title.clone
    filename.gsub!(/\\/, "&bs;")
    filename.gsub!(/\//, "&fs;")
    filename.gsub!(/:/, "&cn;")
    filename.gsub!(/\*/, "&as;")
    filename.gsub!(/\?/, "&qm;")
    filename.gsub!(/"/, "&dq;")
    filename.gsub!(/</, "&lt;")
    filename.gsub!(/>/, "&gt;")
    filename.gsub!(/\|/, "&po;")
    return filename
  end

  def self.create_script(title, content)
    f = File.new(title, "wb")
    f.write content
    f.close
  end

  def self.clear_directory(path, delete_current = false)
    Dir.foreach(path) do |f|
      next if f == '.' || f == '..'
      if File.directory?(path + "/" + f)
        clear_directory(path + "/" + f, true)
      else
        File.delete(path + "/" + f)
      end
    end
    Dir.delete(path) if delete_current
  end

  def self.create_directory(path)
    paths = path.split('/')
    paths.each_with_index do |_e, i|
      if !File.directory?(paths[0..i].join('/'))
        Dir.mkdir(paths[0..i].join('/'))
      end
    end
  end
end

#Scripts.dump
Scripts.from_folder
