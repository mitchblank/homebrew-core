class NuSmv < Formula
  desc "Reimplementation and extension of SMV symbolic model checker"
  homepage "https://nusmv.fbk.eu"
  url "https://nusmv.fbk.eu/distrib/NuSMV-2.6.0.tar.gz"
  sha256 "dba953ed6e69965a68cd4992f9cdac6c449a3d15bf60d200f704d3a02e4bbcbb"
  license "LGPL-2.1-or-later"
  revision 1

  livecheck do
    url :homepage
    regex(/href=.*?announce-NuSMV[._-]v?(\d+(?:\.\d+)+)\.txt/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, catalina:    "90dad1b30d80ee7ddba984d6ad2536fff08896e79cf1a26a083a5e9990fc3c43"
    sha256 cellar: :any_skip_relocation, mojave:      "c2cc207758d6f315db1116e0e162be72edc0356312c460cd3359dca8c7de597e"
    sha256 cellar: :any_skip_relocation, high_sierra: "f2e93143e60b64244fd25958a88480acee332fd4109a6bd356719dc6259efc36"
    sha256 cellar: :any_skip_relocation, sierra:      "64f825eac53c6c16c9b3db4b505d37a6de9f1f3471863b39081b5a98d517fb3e"
  end

  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "pkg-config" => :build
  depends_on "readline"

  uses_from_macos "bison" => :build
  uses_from_macos "flex" => :build
  uses_from_macos "libxml2"
  uses_from_macos "ncurses"

  resource "minisat" do
    # This URL must match what is specified in MiniSat/minisat-default.cmake except
    # that we download the '.tar.gz' instead of the '.zip' to keep "brew audit" happy
    url "https://github.com/niklasso/minisat/archive/37dc6c67e2af26379d88ce349eb9c4c6160e8543.tar.gz"
    sha256 "3db05b02f91c4b097b7962e523225aa5e6fa9a6c0d42704a170b01b069cdfcfe"
  end

  def install
    # Normally cmake will try to download the minisat source zip itself
    # but we already got it as a resource.  If we drop it into the build
    # directory it will use that one.  However, we grabbed the .tar.gz
    # instead of the .zip above, so we need to name it .zip so it is
    # in the right place.  It is ultimately unpacked with bsdtar anyway
    # so the fact that it's the "wrong" format won't matter!
    r = resource("minisat")
    r.fetch unless r.downloaded?
    cp r.cached_download, buildpath/"MiniSat"/(File.basename(r.url, ".tar.gz") + ".zip")

    mkdir "NuSMV/build" do
      system "cmake", "..", *std_cmake_args
      system "make"
      system "make", "prog-man-html"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.smv").write <<~EOS
      MODULE main
      SPEC TRUE = TRUE
    EOS

    output = shell_output("#{bin}/NuSMV test.smv")
    assert_match "specification TRUE = TRUE  is true", output
  end
end
