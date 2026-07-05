{
  description = "wwn-utm: Wawona's UTM fork, aligned as the QEMU-TCTI (jitless, UTM SE model) + Virtualization.framework source for wwn-vms. Exposes the fork's emulator sources/patches; the packaged per-target engine is assembled downstream in wwn-vms.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      allSystems = [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAll = nixpkgs.lib.genAttrs allSystems;
    in
    {
      # Source surface consumed by wwn-vms' mobile/android engine recipes. These
      # are the jitless-QEMU (UTM SE) + VZ pieces; wwn-vms cross-compiles them
      # through wwn-toolchain and links the bundled NixOS guest + wwn-waypipe.
      lib = {
        # UTM's QEMU patch (TCTI/SE + iOS build fixes).
        qemuUtmPatch = ./patches/qemu-10.0.2-utm.patch;
        # Dependency build machinery (produces the QEMU + libs artifacts).
        buildDependenciesScript = ./scripts/build_dependencies.sh;
        packDependenciesScript = ./scripts/pack_dependencies.sh;
        # Emulator/hypervisor Swift/ObjC backends.
        sources = {
          qemuSystem = ./Services/UTMQemuSystem.m;
          qemuVirtualMachine = ./Services/UTMQemuVirtualMachine.swift;
          appleVirtualMachine = ./Services/UTMAppleVirtualMachine.swift;
          qemuProcess = ./Services/UTMProcess.m;
        };
        # Xcode schemes: iOS-SE is the jitless (TCTI) target; iOS uses JIT.
        seScheme = ./UTM.xcodeproj/xcshareddata/xcschemes/iOS-SE.xcscheme;

        # Assemble the jitless QEMU-TCTI engine for an Apple/Android target.
        # Placeholder until the full cross-build is wired through wwn-toolchain;
        # kept as a function (not a forced package) so `nix flake` stays green.
        mkQemuTcti =
          { pkgs, applePlatform ? "ios" }:
          throw ''
            wwn-utm.mkQemuTcti (${applePlatform}) is not built yet. It will
            cross-compile QEMU (jitless TCTI, from qemuUtmPatch + buildDependenciesScript)
            through wwn-toolchain and hand the artifact to wwn-vms' engine.nix.
          '';
      };

      formatter = forAll (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
