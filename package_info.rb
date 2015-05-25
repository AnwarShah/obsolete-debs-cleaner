class PackageInfo

  attr_reader :name, :arch, :vers, :paths

  def initialize(name, arch, ver_string, path )
    @name = name
    @arch = arch
    @vers = [ver_string]
    @paths = [path]
  end

  def add_version(ver_string, path)
    @vers.push ver_string
    @paths.push path
  end

  def to_s
    "#{@name}, #{@arch}, #{@vers}, #{@paths}"
  end

end


p1 = PackageInfo.new("compiz", "i386", "1:0.9.11.3+14.04.20150313-0ubuntu1",
                     'file:/home/learner/deb-repo/Trusty-New/')

p1.add_version("1:0.9.11.3+14.04.20150122-0ubuntu1", "http://archive.ubuntu.com/ubuntu/" )

puts p1.paths