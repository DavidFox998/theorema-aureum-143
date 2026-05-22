import TheoremaAureum.C01_Arakelov
import TheoremaAureum.C03_Positivity  -- needs H1
import TheoremaAureum.RHStatement     -- needs GRH_E_143a1

namespace TheoremaAureum

/-- H2: Weil Positivity Transfer.
"If VALOR > 0, then GRH holds for L(s,E)" -/
axiom H2_WeilTransfer : H1_ArakelovPositivity → GRH_E_143a1

end TheoremaAureum
