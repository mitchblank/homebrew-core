class ExtractUrl < Formula
  desc "Perl script to extracts URLs from emails or plain text"
  homepage "https://www.memoryhole.net/~kyle/extract_url/"
  url "https://github.com/m3m0ryh0l3/extracturl/archive/v1.6.2.tar.gz"
  sha256 "5f0b568d5c9449f477527b4077d8269f1f5e6d6531dfa5eb6ca72dbacab6f336"
  license "BSD-2-Clause"
  revision 1
  head "https://github.com/m3m0ryh0l3/extracturl.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "1418a8148c3fbeb60fbb976b52b5fa59d3702ba5e69fe02179588ab3ba343001" => :big_sur
    sha256 "950f85ce128891278f41aa0b2c7fcaf0cce890055be40741ed8cac6db35c0a73" => :arm64_big_sur
    sha256 "f25df47b8114db594552372e4ee1f9bf7337ab14996429dda0981c93c74afcfe" => :catalina
    sha256 "e8061e3ca6f23c1ae9a042960d05b8ff23887a684c6b37cc831f17fdab4936de" => :mojave
    sha256 "2880b669c381e7c7a2420d71c673d68d988223dc63bad9f14b1c62495973f362" => :high_sierra
    sha256 "57b556a225f6ec03cee7166c1b4cbd2eb1c0eb2bd7819865bd9ed39620b81b68" => :sierra
    sha256 "96d599a0f724f6f09e261c8b0a1c8bbf69ce1b199d311527636f8a5d42f197c6" => :el_capitan
    sha256 "d16fcc4c81a2ffb7f384f104396aae674bb8f6f08d336056ab858924d545f205" => :yosemite
  end

  uses_from_macos "ncurses"
  uses_from_macos "perl"

  resource "MIME::Parser" do
    url "https://cpan.metacpan.org/authors/id/D/DS/DSKOLL/MIME-tools-5.509.tar.gz"
    sha256 "64579f0c923d81d9a2194586e47c3475519e2646e4b5c102a8920759facf6973"
  end

  resource "HTML::Parser" do
    url "https://cpan.metacpan.org/authors/id/C/CA/CAPOEIRAB/HTML-Parser-3.75.tar.gz"
    sha256 "ac6b5e25a8df7af54885201e91c45fb9ab6744c08cedc1a38fcc7d95d21193a9"
  end

  resource "Pod::Usage" do
    url "https://cpan.metacpan.org/authors/id/A/AT/ATOOMIC/Pod-Usage-2.01.tar.gz"
    sha256 "d6d28ff686c9761874321c3dc22cae39f3fb0a39d64fb140c694eef74d468152"
  end

  resource "Env" do
    url "https://cpan.metacpan.org/authors/id/F/FL/FLORA/Env-1.04.tar.gz"
    sha256 "d94a3d412df246afdc31a2199cbd8ae915167a3f4684f7b7014ce1200251ebb0"
  end

  resource "Getopt::Long" do
    url "https://cpan.metacpan.org/authors/id/J/JV/JV/Getopt-Long-2.52.tar.gz"
    sha256 "9dc7a7c373353d5c05efae548e7b123aa8a31d1f506eb8dbbec8f0dca77705fa"
  end

  resource "URI::Find" do
    url "https://cpan.metacpan.org/authors/id/M/MS/MSCHWERN/URI-Find-20160806.tar.gz"
    sha256 "e213a425a51b5f55324211f37909d78749d0bacdea259ba51a9855d0d19663d6"
  end

  resource "Curses" do
    url "https://cpan.metacpan.org/authors/id/G/GI/GIRAFFED/Curses-1.37.tar.gz"
    sha256 "74707ae3ad19b35bbefda2b1d6bd31f57b40cdac8ab872171c8714c88954db20"
  end

  resource "Curses::UI" do
    url "https://cpan.metacpan.org/authors/id/M/MD/MDXI/Curses-UI-0.9609.tar.gz"
    sha256 "0ab827a513b6e14403184fb065a8ea1d2ebda122d2178cbf45c781f311240eaf"
  end

  def install
    ENV.prepend_create_path "PERL5LIB", libexec/"lib/perl5"
    ENV.prepend_path "PERL5LIB", libexec/"lib"

    # Disable dynamic selection of perl, which may cause "Can't locate
    # Mail/Header.pm in @INC" if brew perl is picked up. If the missing modules
    # are added to the formula, mismatched perl will cause segfault instead.
    inreplace "extract_url.pl", "#!/usr/bin/env perl", "#!/usr/bin/perl"

    %w[MIME::Parser HTML::Parser Pod::Usage Env Getopt::Long Curses Curses::UI].each do |r|
      resource(r).stage do
        system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
        if (r == "Curses") && (MacOS.version >= :big_sur)
          # Work around a 11.0 problem in MakeMaker:
          #   https://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker/issues/381
          #
          # This issue is that due to the changes to how libraries
          # exist (or, rather, DON'T exist) on the filesystem, usual ways
          # of detecting libraries do not work.  This extends even
          # to the MakeMaker that comes bundled with Apple's own
          # copy of perl (at least as of OS 11.0.1)
          #
          # The result is that Makefile.PL generates a Makefile that
          # does not contain the expected "LDLOADLIBS = -lcurses" line.
          # The tell is when it prints the diagnostic:
          #   Warning (mostly harmless): No library found for -lcurses
          # Since it doesn't find the library, it assumes no flag is needed.
          #
          # Normally we could probably work around this by just specifying
          # an explicit value of LDLOADLIBS on the "make" command line,
          # but that doesn't work here.  That is because the Makefile
          # runs the perl script "test.syms" which then opens and re-parses
          # "Makefile" to find these values and then uses them to introspect
          # the system's curses library.  If it doesn't find the right
          # value of LDLOADLIBS *inside the Makefile* it won't find any
          # symbols and the build will end up not working.
          #
          # Therefore we need to actually munge "Makefile" after "Makefile.PL"
          # runs but before "make" does
          mk_lines = File.readlines("Makefile")
          if mk_lines.grep(/^LDLOADLIBS\s*=/).empty?
            mv "Makefile", "Makefile.orig"
            File.open("Makefile", "w") { |f| f << "LDLOADLIBS = -lcurses\n" << mk_lines.join << "\n" }
          end
        end
        system "make"
        system "make", "install"
      end
    end

    resource("URI::Find").stage do
      system "perl", "Build.PL", "--install_base", libexec
      system "./Build"
      system "./Build", "install"
    end

    system "make", "prefix=#{prefix}"
    system "make", "prefix=#{prefix}", "install"
    bin.env_script_all_files(libexec/"bin", PERL5LIB: ENV["PERL5LIB"])
  end

  test do
    (testpath/"test.txt").write("Hello World!\nhttps://www.google.com\nFoo Bar")
    assert_match "https://www.google.com", pipe_output("#{bin}/extract_url -l test.txt")
    # Make sure that each of the sub-resources can be imported into perl.  Some like
    # Curses are optional and extract_url will quietly try to work without them, so
    # double check they are all there.
    resources.each do |r|
      system "/usr/bin/perl", "-I#{libexec}/lib", "-I#{libexec}/lib/perl5", "-e", "use #{r.name}; 0"
    end
    unless ENV["CI"]
      # If called without a "-l" flag and connected to a pty it should bring up a
      # selection menu.  The first test makes sure that the URL extraction
      # works, so just verify that it produces some sort of curses UI.
      require "pty"
      ENV["TERM"] = "xterm"
      PTY.spawn("#{bin}/extract_url", "test.txt") do |r, w, _pid|
        w << "q\n"
        w.close
        assert_match "\e", r.read
      end
    end
  end
end
