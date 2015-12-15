class ModSecurity < Formula
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

  desc "Open Source Web application firewall"
  homepage "http://www.modsecurity.org/"
  url "https://www.modsecurity.org/tarball/2.9.0/modsecurity-2.9.0.tar.gz"
  sha256 "e2bbf789966c1f80094d88d9085a81bde082b2054f8e38e0db571ca49208f434"

  option "with-homebrew-apr", "Use Homebrew apr"
  option "with-homebrew-httpd22", "Use Homebrew Apache httpd 2.2"
  option "with-homebrew-httpd24", "Use Homebrew Apache httpd 2.4"

  deprecated_option "with-brewed-apr" => "with-homebrew-apr"
  deprecated_option "with-brewed-httpd22" => "with-homebrew-httpd22"
  deprecated_option "with-brewed-httpd24" => "with-homebrew-httpd24"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "apr-util" if build.with? "homebrew-apr"
  depends_on "httpd22" if build.with? "homebrew-httpd22"
  depends_on "httpd24" if build.with? "homebrew-httpd24"
  depends_on "libtool" => :build
  depends_on "pcre"
  depends_on CLTRequirement if build.without?("homebrew-httpd22") && build.without?("homebrew-httpd24")

  if build.with?("homebrew-apr") && (build.with?("homebrew-httpd22") || build.with?("homebrew-httpd24"))
    opoo "Ignoring --with-homebrew-apr: homebrew apr included in httpd22 and httpd24"
  end

  if build.with?("homebrew-httpd22") && build.with?("homebrew-httpd24")
    onoe "Cannot build for http22 and httpd24 at the same time"
    exit 1
  end

  def apache_apxs
    if build.with? "homebrew-httpd22"
      %W[sbin bin].each do |dir|
        if File.exist?(location = "#{Formula["httpd22"].opt_prefix}/#{dir}/apxs")
          return location
        end
      end
    elsif build.with? "homebrew-httpd24"
      %W[sbin bin].each do |dir|
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
    args = "--prefix=#{prefix}", "--disable-dependency-tracking"
    args << "--with-pcre=#{Formula["pcre"].opt_prefix}"
    args << "--with-apxs=#{apache_apxs}"

    if (build.with? "homebrew-httpd22") || (build.with? "homebrew-httpd24") || (build.with? "homebrew-apr")
      args << "--with-apr=#{Formula["apr"].opt_prefix}"
      args << "--with-apu=#{Formula["apr-util"].prefix}/bin"
    else
      args << "--with-apr=/usr/bin"
      args << "--with-apu=/usr/bin"
    end

    system "./autogen.sh"
    system "./configure", *args
    system "make"

    libexec.install "apache2/.libs/mod_security2.so"

    # Use Homebrew paths in the sample file
    inreplace "modsecurity.conf-recommended" do |s|
      s.gsub! " /var/log", " #{var}/log"
      s.gsub! " /opt/modsecurity/var", " #{opt_prefix}/var"
    end

    prefix.install "modsecurity.conf-recommended"
  end

  def caveats; <<-EOS.undent
    You must manually edit #{apache_configdir}/httpd.conf to include
      LoadModule security2_module #{libexec}/mod_security2.so

    You must also uncomment a line similar to the line below in #{apache_configdir}/httpd.conf to enable unique_id_module
      #LoadModule unique_id_module libexec/mod_unique_id.so

    Sample configuration file for Apache is at:
      #{prefix}/modsecurity.conf-recommended

    NOTE: If you're _NOT_ using --with-homebrew-httpd22 or --with-homebrew-httpd24 and having
    installation problems relating to a missing `cc` compiler and `OSX#{MacOS.version}.xctoolchain`,
    read the "Troubleshooting" section of https://github.com/Homebrew/homebrew-apache
    EOS
  end
end
