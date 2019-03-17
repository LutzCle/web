let
  pkgs = import (pkgsSrc) {};
  pkgsLocal = import <nixpkgs> {};
  pkgsSrc = pkgsLocal.fetchzip {
    url = "https://github.com/NixOS/nixpkgs/archive/82a3ab0dd25d535e556abf7e7f676627217edc07.zip";
    sha256 = "0xlpkys7pc1riqlfii6hv09wmnalnj0q6qyb5mwyxgzlghi9mixh";
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

  in pkgs.stdenv.mkDerivation {
    inherit pelican_themes pelican_plugins;

    name = "clemenslutz-com";
    src = ./.;
    # src = pkgs.fetchFromGitHub {
    #   owner = "lutzcle";
    #   repo = "web";
    #   rev = "HEAD";
    #   sha256 = "0yp46gs3p72qr8dkqqakrl29z8jnf3bv37g5arr8jx6k0z5y6sl8";
    # };

    buildInputs = (with pkgs.python36Packages; [ pelican markdown ])
    ++ (with pkgs; [ openssh ])
    ++ [ pelican_themes pelican_plugins ];

    builder = builtins.toFile "builder.sh" ''
      source $stdenv/setup
      mkdir $out
      mkdir $out/output
      substitute $src/pelicanconf_template.py $TMPDIR/pelicanconf_nix.py --subst-var pelican_themes --subst-var pelican_plugins
      cd $src
      make OUTPUTDIR=$out/output CONFFILE=$TMPDIR/pelicanconf_nix.py html
      cp -R --no-preserve=mode,ownership $src/* $out
      chmod +x $out/develop_server.sh
      cp --no-preserve=mode,ownership $TMPDIR/pelicanconf_nix.py $out/pelicanconf.py
    '';
  }
