{
  allowUnfree = true;

  packageOverrides = pkgs: with pkgs; {
    packages = pkgs.buildEnv {
      name = "packages";
      paths = [
        spotify
      ];
    };
  };
}
