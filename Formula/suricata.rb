class Suricata < Formula
  desc "Network IDS, IPS, and security monitoring engine"
  homepage "https://suricata.io"
  url "https://www.openinfosecfoundation.org/download/suricata-6.0.8.tar.gz"
  sha256 "253ce3cc0df967ad9371d6ea8d4eed91ec593df3ed04e08229c7cf85780c91a3"
  license "GPL-2.0-only"

  livecheck do
    url "https://suricata.io/download/"
    regex(/href=.*?suricata[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 arm64_monterey: "d2a768df140d12f487a71bddfddc8f84848df9d0fea09ce1b33a099c4416bf5d"
    sha256 arm64_big_sur:  "2a66f64bc224b24c9ce98e49b783c0f1c1cf101f419dc027d2371853fb4d1b7c"
    sha256 monterey:       "b63164b0e79fa038451212f01b182dad95edd1334ca26181c528999c4cf8942e"
    sha256 big_sur:        "df74bb0d6c6350e8a866107cd52540e68104c5fc571c906fc61c437964965208"
    sha256 catalina:       "4679e19e9160e587462ab8c40f2d292fc65da79ed7ef788e879f7d60151fd153"
    sha256 x86_64_linux:   "a3daab3dce1e955289e1bb9fae9cdf61a71029d691a5fa6a27d3357ba02fc482"
  end

  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  depends_on "jansson"
  depends_on "libmagic"
  depends_on "libnet"
  depends_on "lz4"
  depends_on "nspr"
  depends_on "nss"
  depends_on "pcre"
  depends_on "python@3.10"
  depends_on "pyyaml"

  uses_from_macos "libpcap"

  resource "argparse" do
    url "https://files.pythonhosted.org/packages/18/dd/e617cfc3f6210ae183374cd9f6a26b20514bbb5a792af97949c5aacddf0f/argparse-1.4.0.tar.gz"
    sha256 "62b089a55be1d8949cd2bc7e0df0bddb9e028faefc8c32038cc84862aefdd6e4"
  end

  resource "simplejson" do
    url "https://files.pythonhosted.org/packages/7a/47/c7cc3d4ed15f09917838a2fb4e1759eafb6d2f37ebf7043af984d8b36cf7/simplejson-3.17.6.tar.gz"
    sha256 "cf98038d2abf63a1ada5730e91e84c642ba6c225b0198c3684151b1f80c5f8a6"
  end

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/03cf8088210822aa2c1ab544ed58ea04c897d9c4/libtool/configure-big_sur.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
    directory "libhtp"
  end

  def install
    python = "python3.10"

    ENV.prepend_create_path "PYTHONPATH", libexec/"vendor"/Language::Python.site_packages(python)
    resources.each do |r|
      r.stage do
        system python, *Language::Python.setup_install_args(libexec/"vendor", python)
      end
    end

    jansson = Formula["jansson"]
    libmagic = Formula["libmagic"]
    libnet = Formula["libnet"]

    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --with-libjansson-includes=#{jansson.opt_include}
      --with-libjansson-libraries=#{jansson.opt_lib}
      --with-libmagic-includes=#{libmagic.opt_include}
      --with-libmagic-libraries=#{libmagic.opt_lib}
      --with-libnet-includes=#{libnet.opt_include}
      --with-libnet-libraries=#{libnet.opt_lib}
    ]

    if OS.mac?
      args << "--enable-ipfw"
      # Workaround for dyld[98347]: symbol not found in flat namespace '_iconv'
      ENV.append "LIBS", "-liconv" if MacOS.version >= :monterey
    else
      args << "--with-libpcap-includes=#{Formula["libpcap"].opt_include}"
      args << "--with-libpcap-libraries=#{Formula["libpcap"].opt_lib}"
    end

    system "./configure", *args
    # setuptools>=60 prefers its own bundled distutils, which breaks the installation
    # pkg_resources.DistributionNotFound: The 'suricata-update==1.2.3' distribution was not found
    # Remove when deprecated distutils installation is no longer used
    with_env(SETUPTOOLS_USE_DISTUTILS: "stdlib") do
      system "make", "install-full"
    end

    bin.env_script_all_files(libexec/"bin", PYTHONPATH: ENV["PYTHONPATH"])

    # Leave the magic-file: prefix in otherwise it overrides a commented out line rather than intended line.
    inreplace etc/"suricata/suricata.yaml", %r{magic-file: /.+/magic}, "magic-file: #{libmagic.opt_share}/misc/magic"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/suricata --build-info")
  end
end
