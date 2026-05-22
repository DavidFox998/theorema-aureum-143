import Lake
open Lake DSL

package «theorema-aureum-143» where
  leanOptions := #[⟨`autoImplicit, false⟩]

lean_lib «TheoremaAureum» where
  srcDir := "."

@[default_target]
lean_exe «theorema-aureum-143» where
  root := `Main
