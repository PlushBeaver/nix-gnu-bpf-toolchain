{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-20.03;

  outputs = { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      prefix = "bpf-none-";
    in rec {
      binutils = pkgs.stdenv.mkDerivation {
        version = "2.34";
        name = "binutils-ebpf";
        
        src = builtins.fetchurl {
          url = "https://mirror.tochlab.net/pub/gnu/binutils/binutils-2.34.tar.xz";
          sha256 = "f00b0e8803dc9bab1e2165bd568528135be734df3fabf8d0161828cd56028952";
        };

        buildInputs = with pkgs; [
          gmp
          libmpc
          mpfr
          texinfo
        ];

        configureFlags = [
          "--target=bpf-none"
        ];

        meta = {
          homepage = "https://www.gnu.org/software/binutils/";
          license = pkgs.stdenv.lib.licenses.gpl3Plus;
        };
      };

      gcc = pkgs.stdenv.mkDerivation {
        version = "10.1.0";
        name = "gcc-ebpf";
        
        src = builtins.fetchurl {
          url = "http://mirror.linux-ia64.org/gnu/gcc/releases/gcc-10.1.0/gcc-10.1.0.tar.xz";
          sha256 = "b6898a23844b656f1b68691c5c012036c2e694ac4b53a8918d4712ad876e7ea2";
        };

        nativeBuildInputs = [
          binutils
        ];
        buildInputs = with pkgs; [
          gmp
          libmpc
          mpfr
          texinfo
        ];

        hardeningDisable = [
          "format"
        ];

        configureFlags = [
          "--program-prefix=${prefix}"
          "--target=bpf-none"
          "--enable-languages=c"
          "--disable-gcov"
          "--disable-libatomic"
          "--disable-libgcc"
          "--disable-libgomp"
          "--disable-libquadmath"
          "--disable-libssp"
          "--disable-multilib"
          "--disable-nls"
          "--disable-threads"
        ];

        meta = {
          homepage = "https://gcc.gnu.org/";
          license = pkgs.stdenv.lib.licenses.gpl3Plus;
        };
      };

      defaultPackage.x86_64-linux = pkgs.symlinkJoin {
        name = "gcc-ebpf-wrapper";
        paths = [gcc];
        buildInputs = [pkgs.makeWrapper];
        postBuild =
          let
            wrap = suffix: ''wrapProgram $out/bin/${prefix}gcc${suffix} --add-flags "-B${binutils}/bin/${prefix}"'';
          in
            builtins.concatStringsSep "\n" (map wrap ["" "-${gcc.version}"]);
      };
    };
}
