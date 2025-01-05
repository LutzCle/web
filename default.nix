let
  ssh_host = "alain.cml.li";
  ssh_port = "22";
  ssh_user = "lutzcle";
  ssh_target_dir = "/var/www/clemenslutz_com";
  ssh_test_target_dir = "/var/www/alain_cml_li";

  pelican_conf = "pelicanconf_template.py";
  publish_conf = "publishconf.py";

  pkgs = import (pkgsSrc) { };
  pkgsLocal = import <nixpkgs> { };
  pkgsSrc = pkgsLocal.fetchzip {
    url = "https://github.com/NixOS/nixpkgs/archive/8686c71d34e53fd84e1ead97684198f526e54432.zip";
    sha256 = "ftHmDc9I3BKHuNzFQ6xiIC2cpftI3TR6AbswCouiEoQ=";
  };

  pelican_themes = pkgs.fetchFromGitHub {
    owner = "getpelican";
    repo = "pelican-themes";
    rev = "7e96082";
    sha256 = "0najxycfa2q1446959p773nmjb9k3r7lf9dnmy1vvrwgbscszf5k";
  };

  pelican_plugins = pkgs.fetchFromGitHub {
    owner = "getpelican";
    repo = "pelican-plugins";
    rev = "000fc5a";
    sha256 = "1955plbgzc5zq6rg054jaaj7fzq7k5w1szwy85c1mmvsq5xkzc63";
  };

  website_template =
    {
      publish ? false,
      nixconf ? "pelicanconf_nix",
      nixpublish ? "publishconf_nix",
    }:
    pkgs.stdenv.mkDerivation {
      inherit
        pelican_themes
        pelican_plugins
        nixconf
        nixpublish
        ;

      name = "website-template";
      src = ./.;
      # src = pkgs.fetchFromGitHub {
      #   owner = "lutzcle";
      #   repo = "web";
      #   rev = "HEAD";
      #   sha256 = "0yp46gs3p72qr8dkqqakrl29z8jnf3bv37g5arr8jx6k0z5y6sl8";
      # };

      buildInputs =
        (with pkgs.python312Packages; [ pelican ] ++ pelican.optional-dependencies.markdown)
        ++ [
          pelican_themes
          pelican_plugins
        ];

      activeconf = if publish then nixpublish else nixconf;

      builder = builtins.toFile "builder.sh" ''
        source $stdenv/setup

        # `pelican --listen` searches for `output/index.html`
        mkdir -p "$out/output"

        substitute "$src/${pelican_conf}" "$out/${nixconf}.py" --subst-var pelican_themes --subst-var pelican_plugins
        substitute "$src/${publish_conf}" "$out/${nixpublish}.py" --subst-var-by include_path "$out" --subst-var-by pelican_conf "${nixconf}"

        pelican "$src/content" --output "$out/output" --settings "$out/$activeconf.py" --cache-path "$TMPDIR"
      '';
    };
in
{
  html = website_template { publish = false; };

  serve =
    let
      website = website_template { publish = false; };
    in
    pkgs.writeShellApplication {
      name = "serve-website.sh";
      runtimeInputs = [ website ] ++ (with pkgs.python312Packages; [ pelican ]);
      text = ''
        cache=$(mktemp -d)
        echo "Rendering content in: ${website}"
        pelican ${website} --output ${website}/output --settings "${website}/${website.nixconf}.py" --listen --cache-path "$cache"
      '';
    };

  publish =
    let
      website = website_template { publish = true; };
    in
    pkgs.writeShellApplication {
      name = "publish-website.sh";
      runtimeInputs = [ website ] ++ (with pkgs; [ rsync ]) ++ (with pkgs.python312Packages; [ pelican ]);
      text = ''
        echo "Publishing content in: ${website}"
        rsync -rv --checksum --copy-links --delete --times --port=${ssh_port} ${website}/output/ ${ssh_user}@${ssh_host}:${ssh_target_dir}
      '';
    };
}
