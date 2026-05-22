import TheoremaAureum.C01_Arakelov
import TheoremaAureum.C02_Modularity
import TheoremaAureum.C03_Positivity
import TheoremaAureum.C04_HeightBound
import TheoremaAureum.C05_Discriminant
import TheoremaAureum.C06_ZetaControl
import TheoremaAureum.C07_RH

theorem Theorema_Aureum : 
  ArakelovPositivity (X₀ 143) → RiemannHypothesis := by
  intro hA
  exact C07_RH_of_Arakelov hA

#check Theorema_Aureum
