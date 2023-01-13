class Tz < Formula
  desc "CLI time zone visualizer"
  homepage "https://github.com/oz/tz"
  url "https://github.com/oz/tz/archive/refs/tags/v0.6.2.tar.gz"
  sha256 "f4dc3ae2089701947cbdba37f9684708d5fd63e362b1355469105860b08b356b"
  license "GPL-3.0-or-later"
  head "https://github.com/oz/tz.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "7c7b5d50f3a4932dd5938d575c745556751e0bdb422365e81b8940fd8095468e"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "ffcc6e47c89080907b571031d530046fe710d4c74c45183a8981c6c67ed3515a"
    sha256 cellar: :any_skip_relocation, arm64_big_sur:  "ffcc6e47c89080907b571031d530046fe710d4c74c45183a8981c6c67ed3515a"
    sha256 cellar: :any_skip_relocation, ventura:        "d5cf2912da3e2e77cf17c1c6fecffb8712756b0ac02618035963bab34059aabb"
    sha256 cellar: :any_skip_relocation, monterey:       "2ce8046b150966b4e05f0f13255f17d6589650331578256f6f6f41ec25823f81"
    sha256 cellar: :any_skip_relocation, big_sur:        "2ce8046b150966b4e05f0f13255f17d6589650331578256f6f6f41ec25823f81"
    sha256 cellar: :any_skip_relocation, catalina:       "2ce8046b150966b4e05f0f13255f17d6589650331578256f6f6f41ec25823f81"
    sha256 cellar: :any_skip_relocation, mojave:         "2ce8046b150966b4e05f0f13255f17d6589650331578256f6f6f41ec25823f81"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "ec421c74a0f6646bc9c0607eb43ce4a7b7330aabf3b8e8949740ae6674deac0f"
  end

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args
  end

  test do
    assert_match "US/Eastern", shell_output("#{bin}/tz --list")

    assert_match version.to_s, shell_output("#{bin}/tz -v")
  end
end
