class Fragroute < Formula
  desc "Intercepts, modifies and rewrites egress traffic for a specified host"
  # Original project homepage is https://www.monkey.org/~dugsong/fragroute/ but we
  # are now tracking the "fragroute-ipv6" fork which is somewhat more up-to-date
  homepage "https://github.com/stsi/fragroute-ipv6"
  url "https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/fragroute-ipv6/fragroute-1.2.6-ipv6.tar.gz"
  mirror "http://ftp.twaren.net/Linux/Gentoo/distfiles/7d/fragroute-1.2.6-ipv6.tar.gz"
  version "1.2.6"
  sha256 "f1e4217120a1c557408182a64033892a6ab7515abd1b46d8b10d6de76431f53d"
  license "BSD-3-Clause"
  head "https://github.com/stsi/fragroute-ipv6.git"

  livecheck do
    url "https://www.googleapis.com/storage/v1/b/google-code-archive/o/v2%2Fcode.google.com%2Ffragroute-ipv6%2Fdownloads-page-1.json?alt=media&stripTrailingSlashes=false"
    regex(/"filename":"fragroute-v?(\d+(?:\.\d+)+)-ipv6\.t/i)
  end

  bottle do
    rebuild 1
    sha256 "bc2aad3bd752e06ec939f1fd2f49ae26ceaff3175c6675be53c9dfebd41e694b" => :big_sur
    sha256 "7bd2a4a54f15b14b015e4defdfdf633db0b51cee12f126402dd99b708540ce9d" => :catalina
    sha256 "76571eb2b3a3026700b58e589b6a2e30651898763b63b26f9bc8d78856cf7e51" => :mojave
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libdnet"
  depends_on "libevent"

  uses_from_macos "libpcap"

  # define DNET_TUN_H
# patch :p0 do
#   url "https://raw.githubusercontent.com/Homebrew/formula-patches/2f5cab626/fragroute/configure.patch"
#   sha256 "215e21d92304e47239697945963c61445f961762aea38afec202e4dce4487557"
# end

# patch :p0 do
#   url "https://raw.githubusercontent.com/Homebrew/formula-patches/2f5cab626/fragroute/pcaputil.c.patch"
#   sha256 "c1036f61736289d3e9b9328fcb723dbe609453e5f2aab4875768068faade0391"
# end

  patch do
    url "https://github.com/stsi/fragroute-ipv6/commit/f16f6ac0288a8814461b6e5f2df0fe455f887433.patch?full_index=1"
    sha256 "eb0a93b17d4e324f822c5bfcdb88c10c5598c4e46a13007785ab8c2b843d02f9"
  end

  def install
    # Fix hard-coded tests looking for linux shared libraries
    inreplace "configure.in", ".so", ".dylib"

    system "autoreconf", "--verbose", "--install", "--force"

    # pcaputil.h defines a "pcap_open()" helper function, but that name
    # conflicts with an unrelated function in newer versions of libpcap
#   inreplace %w[pcaputil.h pcaputil.c tun-loop.c fragtest.c], /pcap_open\b/, "pcap_open_device_named"

    args = %W[
      --disable-dependency-tracking
      --prefix=#{prefix}
      --mandir=#{man}
      --sysconfdir=#{etc}
      --with-libevent=#{Formula["libevent"].opt_prefix}
      --with-libdnet=#{Formula["libdnet"].opt_prefix}
      --with-libpcap=#{MacOS.sdk_path}/usr
    ]

    system "./configure", *args
    system "make", "install"
  end
end
