class ModBonjour < Formula
  class CLTRequirement < Requirement
    fatal true
    satisfy { MacOS.version < :mavericks || MacOS::CLT.installed? }

    def message; <<-EOS.undent
      Xcode Command Line Tools required, even if Xcode is installed, on OS X 10.9 or
      10.10 and not using Homebrew httpd22 or httpd24. Resolve by running
        xcode-select --install
      EOS
    end
  end

  desc "Control websites registration with multicast DNS."
  homepage "http://www.opensource.apple.com/source/apache_mod_bonjour/apache_mod_bonjour-23/"
  url "http://www.opensource.apple.com/tarballs/apache_mod_bonjour/apache_mod_bonjour-23.tar.gz"
  version "2.3"
  sha256 "189de580be60198dcaf5d9dabc559d95ed2355c12bb55fad2f3f4f8b2b034ef6"

  option "with-homebrew-httpd22", "Use Homebrew Apache httpd 2.2"
  option "with-homebrew-httpd24", "Use Homebrew Apache httpd 2.4"

  deprecated_option "with-brewed-httpd22" => "with-homebrew-httpd22"
  deprecated_option "with-brewed-httpd24" => "with-homebrew-httpd24"

  depends_on "httpd22" if build.with? "homebrew-httpd22"
  depends_on "httpd24" if build.with? "homebrew-httpd24"
  depends_on CLTRequirement if build.without?("homebrew-httpd22") && build.without?("homebrew-httpd24")

  def apache_apxs
    if build.with? "homebrew-httpd22"
      %w[sbin bin].each do |dir|
        if File.exist?(location = "#{Formula["httpd22"].opt_prefix}/#{dir}/apxs")
          return location
        end
      end
    elsif build.with? "homebrew-httpd24"
      %w[sbin bin].each do |dir|
        if File.exist?(location = "#{Formula["httpd24"].opt_prefix}/#{dir}/apxs")
          return location
        end
      end
    else
      "/usr/sbin/apxs"
    end
  end

  def apache_configdir
    if build.with? "homebrew-httpd22"
      "#{etc}/apache2/2.2"
    elsif build.with? "homebrew-httpd24"
      "#{etc}/apache2/2.4"
    else
      "/etc/apache2"
    end
  end

  def install
    if build.with?("homebrew-httpd22") && build.with?("homebrew-httpd24")
      onoe "Cannot build for http22 and httpd24 at the same time"
      exit 1
    end

    system "#{apache_apxs} -o mod_bonjour.so -c *.c"
    libexec.install ".libs/mod_bonjour.so"
  end

  def caveats
    <<-EOS.undent
    You must manually edit #{apache_configdir}/httpd.conf to include
      LoadModule bonjour_module #{libexec}/mod_bonjour.so

    Add the following to your virtual host conf files to advertise them on bonjour. The
    last number is whatever port the virtual host is listening on.

        <IfModule bonjour_module>
            RegisterResource "Site Title" / 80
        </IfModule>

    NOTE: If you're _NOT_ using --with-homebrew-httpd22 or --with-homebrew-httpd24 and having
    installation problems relating to a missing `cc` compiler and `OSX#{MacOS.version}.xctoolchain`,
    read the "Troubleshooting" section of https://github.com/Homebrew/homebrew-apache
    EOS
  end
end
