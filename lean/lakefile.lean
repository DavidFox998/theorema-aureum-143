import Lake
open Lake DSL

package «theorema-aureum-143» where
  dependencies := #[
    {
      name := `mathlib,
      src := Source.git "https://github.com/leanprover-community/mathlib4.git" "v4.12.0"
    }
  ]

lean_lib TheoremaAureum

@[default_target]
lean_exe «theorema-aureum-143» where
  root := `TheoremaAureum.Main  ← This points to your current Main.lean location
