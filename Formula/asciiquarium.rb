class Asciiquarium < Formula
  desc "Aquarium animation in ASCII art"
  homepage "https://robobunny.com/projects/asciiquarium/html/"
  url "https://robobunny.com/projects/asciiquarium/asciiquarium_1.1.tar.gz"
  sha256 "1b08c6613525e75e87546f4e8984ab3b33f1e922080268c749f1777d56c9d361"
  license "GPL-2.0-or-later"
  revision 2

  livecheck do
    url "https://robobunny.com/projects/asciiquarium/"
    regex(/href=.*?asciiquarium[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    cellar :any_skip_relocation
    sha256 "9bf092861aad33c28e8f753d79032eb9af48521508dbee0a5ec6dc3646e6cc89" => :catalina
    sha256 "7c9263400bd1045b998e5f48d34d79fa4df0e27daf5f9c49afb1ed283a39f537" => :mojave
    sha256 "10d2a74f8e447c87fa477de74aa692a1d0043ab508e9a924126e0a3d55ffe5a7" => :high_sierra
    sha256 "890b0e69b0261ff61b0d0666f2b3e0f579c1f63556c77c2d8d24bc1ef3f4e241" => :sierra
    sha256 "9120f02b70c63672af2752de536aeaeac5ef57bc2b3a388afe1ab9e12d40a59b" => :el_capitan
    sha256 "6b20abf264f40c7123e40f0f34cfc11f0c12a03b1a74a324e3f3a7ae75e94f3f" => :yosemite
  end

  uses_from_macos "ncurses"

  resource "Curses" do
    url "https://cpan.metacpan.org/authors/id/G/GI/GIRAFFED/Curses-1.37.tar.gz"
    sha256 "74707ae3ad19b35bbefda2b1d6bd31f57b40cdac8ab872171c8714c88954db20"
  end

  resource "Term::Animation" do
    url "https://cpan.metacpan.org/authors/id/K/KB/KBAUCOM/Term-Animation-2.6.tar.gz"
    sha256 "7d5c3c2d4f9b657a8b1dce7f5e2cbbe02ada2e97c72f3a0304bf3c99d084b045"
  end

  def install
    ENV.prepend_create_path "PERL5LIB", libexec/"lib/perl5"

    resources.each do |r|
      r.stage do
        system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
        if (r.name == "Curses") && (MacOS.version >= :big_sur)
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

    # Disable dynamic selection of perl which may cause segfault when an
    # incompatible perl is picked up.
    # https://github.com/Homebrew/homebrew-core/issues/4936
    inreplace "asciiquarium", "#!/usr/bin/env perl", "#!/usr/bin/perl"

    chmod 0755, "asciiquarium"
    bin.install "asciiquarium"
    bin.env_script_all_files(libexec/"bin", PERL5LIB: ENV["PERL5LIB"])
  end

  test do
    # This is difficult to test because:
    # - There are no command line switches that make the process exit
    # - The output is a constant stream of terminal control codes
    # - Testing only if the binary exists can still result in failure

    # The test process is as follows:
    # - Spawn the process capturing stdout and the pid
    # - Kill the process after there is some output
    # - Ensure the start of the output matches what is expected

    require "pty"
    ENV["TERM"] = "xterm"
    PTY.spawn(bin/"asciiquarium") do |stdin, _stdout, pid|
      sleep 0.1
      Process.kill "TERM", pid
      output = stdin.read
      assert_match "\e[?10", output[0..4]
    end
  end
end
