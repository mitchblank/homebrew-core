class ArgyllCms < Formula
  desc "ICC compatible color management system"
  homepage "https://www.argyllcms.com/"
  url "https://www.argyllcms.com/Argyll_V2.1.2_src.zip"
  sha256 "be378ca836b17b8684db05e9feaab138d711835ef00a04a76ac0ceacd386a3e3"
  license "AGPL-3.0-only"
  revision 1

  bottle do
    cellar :any
    sha256 "242a8a56d37402e681d630d1df0702088df5555e367afb65469679aa96ee9f29" => :catalina
    sha256 "6edcbef10d3f93d7f527cc875a35cb9c6bf636da03d6a1c548f560fcbca83866" => :mojave
    sha256 "4b7bcbe2cd555d9606812afc676cab750c6f8bc4be54db0551bb2becefd176e0" => :high_sierra
  end

  depends_on "jam" => :build
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "openssl@1.1"

  uses_from_macos "zlib"

  conflicts_with "num-utils", because: "both install `average` binaries"

  # Fixes calls to obj_msgSend, whose signature changed in macOS 10.15.
  # Follows the advice in this blog post, which should be compatible
  # with both older and newer versions of macOS.
  # https://www.mikeash.com/pyblog/objc_msgsends-new-prototype.html
  # Submitted upstream: https://www.freelists.org/post/argyllcms/Patch-Fix-macOS-build-failures-from-obj-msgSend-definition-change
  patch do
    url "https://www.freelists.org/archives/argyllcms/02-2020/binRagOo4qV7a.bin"
    sha256 "fa86f5f21ed38bec6a20a79cefb78ef7254f6185ef33cac23e50bb1de87507a4"
  end

  def install
    # dyld: lazy symbol binding failed: Symbol not found: _clock_gettime
    # Reported 20 Aug 2017 to graeme AT argyllcms DOT com
    if MacOS.version == :el_capitan && MacOS::Xcode.version >= "8.0"
      inreplace "numlib/numsup.c", "CLOCK_MONOTONIC", "UNDEFINED_GIBBERISH"
    end

    # The JamTop file tries to automatically detect whether its dependencies
    # are already installed and if not uses its own included copies.  However
    # its detection of Homebrew-installed libraries isn't reliable so rewrite
    # it.  Unfortunately it doesn't have anything like autoconf's "--with-X=/path"
    # to specify them explicitly.
    force_library_external("TIFF", "libtiff", "-ltiff")
    force_library_external("JPEG", "jpeg", "-ljpeg")
    force_library_external("PNG", "libpng", "-lpng")
    force_library_external("SSL", "openssl@1.1", "-lssl -lcrypto")
    inreplace "JamTop", /^CheckForLibrary "Z".*;/,
      ["ZINC = ;\n",
       "ZLIC = ;\n",
       "HAVE_ZLIB = true ;\n",
       "LINKFLAGS += -lz ;\n"].join

    ENV["PREFIX"] = prefix
    # For some reason, if you don't set DESTDIR it treats PREFIX as
    # a relative path even wen it starts with "/"!
    ENV["DESTDIR"] = "/"
    # By default, the color profiles get instealld in /usr/local/ref but
    # it's more UNIX-like for them to be under /usr/local/share/argyll
    # This matches what FreeBSD ports has always done
    ENV["REFSUBDIR"] = "share/argyll/ref"
    system "sh", "makeall.sh"
    system "sh", "makeinstall.sh"
    # Adjust the location of the license file
    mv bin/"License.txt", prefix/"License.txt"
    # Also install documentation files
    (share/"argyll").install "doc"
  end

  test do
    system bin/"targen", "-d", "0", "test.ti1"
    system bin/"printtarg", testpath/"test.ti1"
    %w[test.ti1.ps test.ti1.ti1 test.ti1.ti2].each do |f|
      assert_predicate testpath/f, :exist?
    end
    assert_match "Calibrate a Display", shell_output("#{bin}/dispcal 2>&1", 1)
  end

  def force_library_external(name, formula, libflags)
    inreplace "JamTop", /^CheckForLibrary "#{name}".*;/,
      ["#{name}INC = ;\n",
       "#{name}LIC = ;\n",
       "HAVE_#{name} = true ;\n",
       "LINKFLAGS += -L#{Formula[formula].opt_lib} #{libflags} ;\n",
       "HDRS += #{Formula[formula].opt_include} ;\n"].join
  end
end
