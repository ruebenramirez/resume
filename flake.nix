{
  description = "Resume generation environment with Pandoc and LaTeX";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Custom TeX Live package selection
        texlive = pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-medium   # Base package set
            collection-fontsrecommended
            geometry
            hyperref
            xcolor
            enumitem
            fancyhdr
            titlesec;
        };

        # Resume builder script
        resumeBuilder = pkgs.writeShellApplication {
          name = "build-resume";
          runtimeInputs = with pkgs; [ pandoc texlive ];
          text = ''
            # Extract the base name without extension
            BASE_NAME="''${1%.md}"

            # Generate PDF
            echo "Generating PDF..."
            pandoc "$1" \
              -f gfm \
              -t pdf \
              -o "$BASE_NAME.pdf" \
              --pdf-engine=xelatex \
              --variable mainfont="DejaVu Sans" \
              --variable monofont="DejaVu Sans Mono" \
              --variable fontsize=11pt \
              --variable geometry="margin=1in" \
              --variable urlcolor=blue

            # Generate DOCX
            echo "Generating DOCX..."
            pandoc "$1" \
              -f gfm \
              -t docx \
              -o "$BASE_NAME.docx" \
              --toc=false

            # Generate HTML
            echo "Generating HTML..."
            pandoc "$1" \
              -f gfm \
              -t html \
              -o "$BASE_NAME.html" \
              --standalone \
              --metadata title="" \
              --css=https://cdn.jsdelivr.net/npm/water.css@2/out/water.css \
              --self-contained

            echo "Done! Generated:"
            echo "- $BASE_NAME.pdf"
            echo "- $BASE_NAME.docx"
            echo "- $BASE_NAME.html"
          '';
        };

      in {
        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            pandoc
            texlive
            watchexec  # For auto-rebuilding
          ];

          shellHook = ''
            echo "Resume generation environment activated!"
            echo "Available commands:"
            echo "  pandoc input.md -o resume.pdf    # Generate PDF"
            echo "  watchexec -e md 'pandoc input.md -o resume.pdf'    # Auto-rebuild on changes"
          '';
        };

        # Packages
        packages = {
          build-resume = resumeBuilder;
        };
      });
}
