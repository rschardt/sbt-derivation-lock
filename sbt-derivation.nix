{
  sbt-derivation,
  callPackage,
  sbt,
}:

{
  lockFile,
  flakeOutput, # ? "defaultPackage"
  ...
} @ args:

let
  lockedSbt = callPackage ./sbt.nix { inherit lockFile; };
  callMkDerivation = callPackage "${sbt-derivation}/lib/sbt-derivation.nix";
in

(callMkDerivation { sbt = lockedSbt; } (args // {
  depsSha256 = null;

  passthru = args.passthru or {} // {
    sbt = lockedSbt;

    lock-deps = callPackage ./lock-deps.nix { inherit flakeOutput; };

    # used by lock-deps
    depsDerivation = (callMkDerivation { sbt = sbt; } (args // {
      depsSha256 = null;
      depsWarmupCommand = ''
        runHook preDepsWarmupCommand
        sbt --verbose "dependencyTree ; consoleQuick" <<< ":quit"
      '';
    }));
  };
})).overrideAttrs (oldAttrs: {
  # no longer needed
  deps = null;

  # explicitly overwrite the `postConfigure` phase, otherwise it
  # references the now null `deps` derivation.
  postConfigure = ''
    ${args.postConfigure or ""}
    mkdir -p .nix/ivy
    # SBT expects a "local" prefix to each organization for plugins
    for repo in ${lockedSbt.mavenRepo}/sbt-plugin-releases/*; do
      ln -s $repo .nix/ivy/local''${repo##*/}
    done
  '';
})
