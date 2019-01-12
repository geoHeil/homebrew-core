class Direnv < Formula
  desc "Load/unload environment variables based on $PWD"
  homepage "https://direnv.net/"
  url "https://github.com/direnv/direnv/archive/v2.19.0.tar.gz"
  sha256 "b4ad422091b6480b072db2e878c860dc17847fb4f8e4419ed90f59866e100b59"
  head "https://github.com/direnv/direnv.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "4bfcb61687fa138c918fe6363a7caad35ff85fcc3a7d4305502f6ea0e958a471" => :mojave
    sha256 "c9418748a77d54a6ddf1495def75289e52541658ce754384659d059b1ca08984" => :high_sierra
    sha256 "a1306461fa5b01642c827dacacd618824830a418e1802671eaacd4bb965cb166" => :sierra
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    (buildpath/"src/github.com/direnv/direnv").install buildpath.children
    cd "src/github.com/direnv/direnv" do
      system "make", "install", "DESTDIR=#{prefix}"
      prefix.install_metafiles
    end
  end

  test do
    system bin/"direnv", "status"
  end
end
