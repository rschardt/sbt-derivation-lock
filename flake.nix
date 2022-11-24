{
  inputs.sbt-derivation.url = github:zaninime/sbt-derivation;

  outputs = inputs: {
    overlay = externalInputs:
      let
        usedInput = if (isNull externalInputs)
                     then inputs
                     else externalInputs;
      in
        import ./overlay.nix usedInput;
  };
}
