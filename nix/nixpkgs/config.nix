{
  allowUnfree = true;

  packageOverrides = pkgs: with pkgs; {
    packages = pkgs.buildEnv {
      name = "packages";
      paths = [
        spotify
      ];
    };

    drivers = pkgs.buildEnv {
      name = "drivers";
      paths = [
        vulkan-loader
        vulkan-tools
        amdvlk
        libdrm
        mesa
      ];
    };
  };
}
