import TheoremaAureum.C01_Arakelov
import TheoremaAureum.C03_Positivity  -- add this
import TheoremaAureum.RHStatement

namespace TheoremaAureum

/-- H2: Weil Positivity Transfer.
"If VALOR > 0, then GRH holds for L(s,E)" -/
axiom H2_WeilTransfer : H1_ArakelovPositivity → GRH_E143a1

end TheoremaAureum
